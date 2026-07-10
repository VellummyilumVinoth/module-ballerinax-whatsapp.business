// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;

isolated function statusResponse(int statusCode) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    return response;
}

isolated function toInboundMessage(WebhookInboundMessage message, string? contactName) returns InboundMessage {
    return {
        'from: message?.'from ?: "",
        messageId: message?.id ?: "",
        messageType: message?.'type ?: "",
        text: message?.text?.body,
        timestamp: message?.timestamp,
        contactName,
        raw: message.toJson()
    };
}

isolated function toMessageErrorDetail(WebhookStatusError statusError) returns MessageErrorDetail {
    return {
        code: statusError?.code,
        title: statusError?.title,
        message: statusError?.message,
        details: statusError?.error_data?.details
    };
}

isolated function toMessageStatusUpdate(WebhookStatus status) returns MessageStatusUpdate {
    WebhookStatusError[]? errors = status?.errors;
    return {
        messageId: status?.id ?: "",
        status: status?.status ?: "",
        recipientId: status?.recipient_id ?: "",
        timestamp: status?.timestamp,
        errors: errors is WebhookStatusError[] ?
                from WebhookStatusError statusError in errors
                select toMessageErrorDetail(statusError) : (),
        raw: status.toJson()
    };
}

isolated function toAccountUpdateRateEligibility(WebhookRateEligibility rateEligibility)
returns AccountUpdateRateEligibility {
    WebhookExceptionCountry[]? exceptionCountries = rateEligibility.exception_countries;
    return {
        startTime: rateEligibility.start_time,
        exceptionCountries: exceptionCountries is WebhookExceptionCountry[] ?
                from WebhookExceptionCountry ec in exceptionCountries
                select {countryCode: ec.country_code, startTime: ec.start_time} : ()
    };
}

# The HTTP service that backs the WhatsApp `Listener`. It handles the subscription handshake
# (GET) and inbound notifications (POST), authenticates them, and dispatches parsed events to
# the attached `WhatsAppService`.
isolated service class HttpService {
    *http:Service;

    private final WhatsAppService whatsappService;
    private final string verifyToken;
    private final string appSecret;

    isolated function init(WhatsAppService whatsappService, string verifyToken, string appSecret) {
        self.whatsappService = whatsappService;
        self.verifyToken = verifyToken;
        self.appSecret = appSecret;
    }

    # Webhook subscription verification handshake. Meta calls this once when the callback URL is
    # saved, expecting the `hub.challenge` echoed back on a matching `hub.verify_token`.
    #
    # + request - The handshake request, carrying the `hub.mode`/`hub.verify_token`/`hub.challenge`
    #              query parameters
    # + return - `200` with the challenge echoed back if verification succeeds, otherwise `403`
    isolated resource function get .(http:Request request) returns http:Response {
        http:Response response = new;
        string? mode = request.getQueryParamValue(QUERY_PARAM_HUB_MODE);
        string? token = request.getQueryParamValue(QUERY_PARAM_HUB_VERIFY_TOKEN);
        string? challenge = request.getQueryParamValue(QUERY_PARAM_HUB_CHALLENGE);
        if mode == HUB_MODE_SUBSCRIBE && challenge is string && token == self.verifyToken {
            response.statusCode = http:STATUS_OK;
            response.setTextPayload(challenge);
            return response;
        }
        response.statusCode = http:STATUS_FORBIDDEN;
        return response;
    }

    # Inbound notification handler. Verifies the payload signature, acknowledges immediately, then
    # parses the envelope and dispatches each message/status/event. Meta requires a fast 2xx
    # (retries otherwise), so the acknowledgement is sent before the potentially slow handler
    # invocations run.
    #
    # + caller - The HTTP caller used to send the acknowledgement before dispatching
    # + request - The inbound webhook notification request
    # + return - An error if the acknowledgement could not be sent; errors from dispatching the
    #            parsed event to the `WhatsAppService` are logged instead of returned
    isolated resource function post .(http:Caller caller, http:Request request) returns error? {
        string|error rawPayload = request.getTextPayload();
        if rawPayload is error {
            log:printWarn(WARN_PAYLOAD_READ_FAILED, rawPayload);
            return caller->respond(statusResponse(http:STATUS_BAD_REQUEST));
        }
        log:printDebug(LOG_WEBHOOK_POST_RECEIVED, payloadLength = rawPayload.length());

        string|error signatureHeader = request.getHeader(WEBHOOK_SIGNATURE_HEADER);
        string signature = signatureHeader is string ? signatureHeader : "";
        boolean|error valid = verifyWebhookSignature(rawPayload, signature, self.appSecret);
        if valid is error || !valid {
            log:printWarn(WARN_SIGNATURE_VERIFICATION_FAILED);
            return caller->respond(statusResponse(http:STATUS_UNAUTHORIZED));
        }

        json|error payload = rawPayload.fromJsonString();
        if payload is error {
            log:printWarn(WARN_PAYLOAD_PARSE_FAILED, payload);
            return caller->respond(statusResponse(http:STATUS_BAD_REQUEST));
        }

        // Acknowledge receipt first so Meta does not retry, then dispatch (handlers may be slow,
        // e.g. an AI agent invocation).
        check caller->respond(statusResponse(http:STATUS_OK));
        self.dispatch(payload);
    }

    isolated function dispatch(json payload) {
        WebhookNotification|error notification = payload.cloneWithType();
        if notification is error {
            log:printWarn(WARN_NOTIFICATION_PARSE_FAILED, notification);
            return;
        }
        foreach WebhookEntry entry in notification?.entry ?: [] {
            string wabaId = entry?.id ?: "";
            int? entryTimestamp = entry?.time;
            foreach WebhookChange change in entry?.changes ?: [] {
                WebhookValue? value = change?.value;
                if value is () {
                    continue;
                }
                string phoneNumberId = value?.metadata?.phone_number_id ?: "";
                string 'field = change?.'field ?: "";
                json valueJson = value.toJson();

                if 'field == WEBHOOK_FIELD_MESSAGES {
                    string? contactName = ();
                    WebhookContact[]? contacts = value?.contacts;
                    if contacts is WebhookContact[] && contacts.length() > 0 {
                        contactName = contacts[0]?.profile?.name;
                    }

                    WebhookInboundMessage[]? messages = value?.messages;
                    WebhookStatus[]? statuses = value?.statuses;

                    if messages is WebhookInboundMessage[] {
                        InboundMessage[] typedMessages = from WebhookInboundMessage message in messages
                            select toInboundMessage(message, contactName);
                        MessagesEvent event = {
                            phoneNumberId,
                            messages: typedMessages,
                            timestamp: entryTimestamp,
                            raw: valueJson
                        };
                        error? result = self.whatsappService->onMessages(event);
                        if result is error {
                            log:printError(ERR_ON_MESSAGES_HANDLER, result, phoneNumberId = phoneNumberId);
                        }
                    } else if statuses is WebhookStatus[] {
                        MessageStatusUpdate[] typedStatuses = from WebhookStatus status in statuses
                            select toMessageStatusUpdate(status);
                        MessageStatusEvent event = {
                            phoneNumberId,
                            statuses: typedStatuses,
                            timestamp: entryTimestamp,
                            raw: valueJson
                        };
                        error? result = self.whatsappService->onMessages(event);
                        if result is error {
                            log:printError(ERR_ON_MESSAGES_HANDLER, result, phoneNumberId = phoneNumberId);
                        }
                    }
                } else {
                    // Every other field is routed by name to its typed handler; a field outside
                    // this closed set (e.g. `account_alerts`, `group_lifecycle_update`) is logged
                    // and dropped rather than delivered anywhere, matching the closed 10-field
                    // "Trigger On" model this listener mirrors.
                    match 'field {
                        WEBHOOK_FIELD_ACCOUNT_REVIEW_UPDATE => {
                            WebhookAccountReviewValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onAccountReviewUpdate({
                                    wabaId,
                                    decision: v.decision ?: "",
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_ACCOUNT_REVIEW_UPDATE_HANDLER, result, wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_ACCOUNT_UPDATE => {
                            WebhookAccountUpdateValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                WebhookWabaInfo? wi = v.waba_info;
                                WebhookViolationInfo? vi = v.violation_info;
                                WebhookBanInfo? bi = v.ban_info;
                                WebhookRateEligibility? ri = v.auth_international_rate_eligibility;
                                WebhookVolumeTierInfo? vti = v.volume_tier_info;
                                WebhookCertificationInfo? ci = v.partner_client_certification_info;
                                WebhookDisconnectionInfo? di = v.disconnection_info;
                                WebhookRestriction[]? restrictions = v.restriction_info;
                                error? result = self.whatsappService->onAccountUpdate({
                                    wabaId,
                                    event: v.event ?: "",
                                    country: v.country,
                                    wabaInfo: wi is WebhookWabaInfo ? {
                                            wabaId: wi.waba_id,
                                            ownerBusinessId: wi.owner_business_id,
                                            adAccountLinked: wi.ad_account_linked,
                                            partnerAppId: wi.partner_app_id,
                                            solutionId: wi.solution_id,
                                            solutionPartnerBusinessIds: wi.solution_partner_business_ids
                                        } : (),
                                    violationInfo: vi is WebhookViolationInfo ?
                                            {violationType: vi.violation_type} : (),
                                    banInfo: bi is WebhookBanInfo ?
                                            {wabaBanState: bi.waba_ban_state, wabaBanDate: bi.waba_ban_date} : (),
                                    rateEligibility: ri is WebhookRateEligibility ?
                                            toAccountUpdateRateEligibility(ri) : (),
                                    volumeTierInfo: vti is WebhookVolumeTierInfo ? {
                                            tierUpdateTime: vti.tier_update_time,
                                            pricingCategory: vti.pricing_category,
                                            tier: vti.tier,
                                            effectiveMonth: vti.effective_month,
                                            region: vti.region
                                        } : (),
                                    certificationInfo: ci is WebhookCertificationInfo ? {
                                            clientBusinessId: ci.client_business_id,
                                            status: ci.status,
                                            rejectionReasons: ci.rejection_reasons
                                        } : (),
                                    disconnectionInfo: di is WebhookDisconnectionInfo ?
                                            {reason: di.reason, initiatedBy: di.initiated_by} : (),
                                    restrictions: restrictions is WebhookRestriction[] ?
                                            from WebhookRestriction r in restrictions
                                            select {
                                                restrictionType: r.restriction_type,
                                                expiration: r.expiration,
                                                remediation: r.remediation
                                            } : (),
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_ACCOUNT_UPDATE_HANDLER, result, wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_BUSINESS_CAPABILITY_UPDATE => {
                            WebhookBusinessCapabilityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onBusinessCapabilityUpdate({
                                    wabaId,
                                    maxDailyConversationsPerBusiness: v.max_daily_conversations_per_business,
                                    maxPhoneNumbersPerWaba: v.max_phone_numbers_per_waba,
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_BUSINESS_CAPABILITY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_MESSAGE_TEMPLATE_QUALITY_UPDATE => {
                            WebhookTemplateQualityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onMessageTemplateQualityUpdate({
                                    wabaId,
                                    messageTemplateId: v.message_template_id ?: 0,
                                    messageTemplateName: v.message_template_name ?: "",
                                    messageTemplateLanguage: v.message_template_language ?: "",
                                    previousQualityScore: v.previous_quality_score ?: "",
                                    newQualityScore: v.new_quality_score ?: "",
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_MESSAGE_TEMPLATE_QUALITY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_MESSAGE_TEMPLATE_STATUS_UPDATE => {
                            WebhookTemplateStatusValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                WebhookTemplateDisableInfo? disableInfo = v.disable_info;
                                WebhookTemplateOtherInfo? otherInfo = v.other_info;
                                WebhookTemplateRejectionInfo? rejectionInfo = v.rejection_info;
                                error? result = self.whatsappService->onMessageTemplateStatusUpdate({
                                    wabaId,
                                    event: v.event ?: "",
                                    messageTemplateId: v.message_template_id ?: 0,
                                    messageTemplateName: v.message_template_name ?: "",
                                    messageTemplateLanguage: v.message_template_language ?: "",
                                    reason: v.reason,
                                    messageTemplateCategory: v.message_template_category,
                                    disableInfo: disableInfo is WebhookTemplateDisableInfo ?
                                            {disableDate: disableInfo.disable_date} : (),
                                    otherInfo: otherInfo is WebhookTemplateOtherInfo ?
                                            {title: otherInfo.title, description: otherInfo.description} : (),
                                    rejectionInfo: rejectionInfo is WebhookTemplateRejectionInfo ? {
                                            reason: rejectionInfo.reason,
                                            recommendation: rejectionInfo.recommendation
                                        } : (),
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_MESSAGE_TEMPLATE_STATUS_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_PHONE_NUMBER_NAME_UPDATE => {
                            WebhookPhoneNumberNameValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onPhoneNumberNameUpdate({
                                    wabaId,
                                    displayPhoneNumber: v.display_phone_number ?: "",
                                    decision: v.decision ?: "",
                                    requestedVerifiedName: v.requested_verified_name ?: "",
                                    rejectionReason: v.rejection_reason,
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_PHONE_NUMBER_NAME_UPDATE_HANDLER, result, wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_PHONE_NUMBER_QUALITY_UPDATE => {
                            WebhookPhoneNumberQualityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onPhoneNumberQualityUpdate({
                                    wabaId,
                                    displayPhoneNumber: v.display_phone_number ?: "",
                                    event: v.event ?: "",
                                    currentLimit: v.current_limit,
                                    oldLimit: v.old_limit,
                                    maxDailyConversationsPerBusiness: v.max_daily_conversations_per_business,
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_PHONE_NUMBER_QUALITY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_SECURITY => {
                            WebhookSecurityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onSecurity({
                                    wabaId,
                                    displayPhoneNumber: v.display_phone_number ?: "",
                                    event: v.event ?: "",
                                    requester: v.requester,
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_SECURITY_HANDLER, result, wabaId = wabaId);
                                }
                            }
                        }
                        WEBHOOK_FIELD_TEMPLATE_CATEGORY_UPDATE => {
                            WebhookTemplateCategoryValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printWarn(WARN_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                error? result = self.whatsappService->onTemplateCategoryUpdate({
                                    wabaId,
                                    messageTemplateId: v.message_template_id ?: 0,
                                    messageTemplateName: v.message_template_name ?: "",
                                    messageTemplateLanguage: v.message_template_language ?: "",
                                    newCategory: v.new_category ?: "",
                                    previousCategory: v.previous_category,
                                    correctCategory: v.correct_category,
                                    categoryUpdateTimestamp: v.category_update_timestamp,
                                    timestamp: entryTimestamp,
                                    raw: valueJson
                                });
                                if result is error {
                                    log:printError(ERR_ON_TEMPLATE_CATEGORY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                }
                            }
                        }
                        _ => {
                            log:printWarn(WARN_UNRECOGNIZED_WEBHOOK_FIELD,
                                    'field = 'field);
                        }
                    }
                }
            }
        }
    }
}
