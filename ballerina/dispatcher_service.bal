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
import ballerina/jballerina.java;
import ballerina/log;

# Invokes the named handler on `whatsappService` with `argument`, if (and only if) the service
# declares that handler; since `WhatsAppService` declares no remote methods (all ten handlers are
# optional), there is no statically bound method to call directly, so this dispatches
# reflectively via the native (Java) runtime. If the handler declares a second parameter, `caller`
# is passed as its second argument too, so it can be typed `Caller` for manual acknowledgement.
#
# + whatsappService - The attached `WhatsAppService` implementation
# + methodName - The handler's name, e.g. `onMessages`
# + argument - The record to pass as the handler's sole (or first, if two) argument
# + caller - Passed as the handler's second argument if (and only if) it declares one
# + return - The handler's result, or `()` if it does not declare that handler
isolated function invokeHandlerIfPresent(WhatsAppService whatsappService, string methodName, any argument,
        Caller caller) returns error? = @java:Method {
    name: "invokeIfPresent",
    'class: "io.ballerinax.whatsapp.business.HandlerDispatcher"
} external;

# Reports a failed handler invocation to `onError`, if the consumer declared it. The original
# error is always logged separately by the caller regardless of whether `onError` is declared or
# itself fails, so a broken `onError` implementation can never silence the underlying failure.
#
# + whatsappService - The attached `WhatsAppService` implementation
# + handlerError - The error the failed handler returned
# + 'field - The webhook field being dispatched when the handler failed
# + payload - The raw `value` object that was being dispatched
# + caller - Passed as `onError`'s second argument if (and only if) it declares one
isolated function invokeOnError(WhatsAppService whatsappService, error handlerError, string 'field, json payload,
        Caller caller) {
    HandlerError errorInfo = {'error: handlerError, 'field, payload};
    error? result = invokeHandlerIfPresent(whatsappService, "onError", errorInfo, caller);
    if result is error {
        log:printError(ERR_ON_ERROR_HANDLER, result, 'field = 'field);
    }
}

isolated function toInboundMessage(WebhookInboundMessage message, string? contactName) returns InboundMessage|error {
    string? sender = message?.'from;
    string? messageId = message?.id;
    string? messageType = message?.'type;
    if sender is () || messageId is () || messageType is () {
        // Every inbound message carries from/id/type regardless of its type-specific content
        // (text, image, location, ...); a missing value means the payload doesn't match the
        // documented shape.
        return error(ERR_INBOUND_MESSAGE_MISSING_REQUIRED_FIELD);
    }
    return {
        'from: sender,
        messageId,
        messageType,
        text: message?.text?.body,
        timestamp: message?.timestamp,
        contactName,
        raw: message.toJson()
    };
}

isolated function toMessageErrorDetail(WebhookStatusError statusError) returns MessageErrorDetail => {
    code: statusError?.code,
    title: statusError?.title,
    message: statusError?.message,
    details: statusError?.error_data?.details
};

isolated function toMessageStatusUpdate(WebhookStatus status) returns MessageStatusUpdate|error {
    string? messageId = status?.id;
    string? statusValue = status?.status;
    string? recipientId = status?.recipient_id;
    if messageId is () || statusValue is () || recipientId is () {
        // Meta documents id/status/recipient_id as required on every status update; a missing
        // value means the payload doesn't match the documented shape.
        return error(ERR_STATUS_UPDATE_MISSING_REQUIRED_FIELD);
    }
    WebhookStatusError[]? errors = status?.errors;
    return {
        messageId,
        status: statusValue,
        recipientId,
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

isolated function toMessages(string phoneNumberId, InboundMessage[] messages, int? entryTimestamp,
        json valueJson) returns Messages => {
    phoneNumberId,
    messages,
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toMessageStatuses(string phoneNumberId, MessageStatusUpdate[] statuses, int? entryTimestamp,
        json valueJson) returns MessageStatuses => {
    phoneNumberId,
    statuses,
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toAccountReviewUpdate(string wabaId, WebhookAccountReviewValue v, int? entryTimestamp,
        json valueJson) returns AccountReviewUpdate => {
    wabaId,
    decision: v.decision ?: "",
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toAccountUpdate(string wabaId, WebhookAccountUpdateValue v, int? entryTimestamp,
        json valueJson) returns AccountUpdate {
    WebhookWabaInfo? wi = v.waba_info;
    WebhookViolationInfo? vi = v.violation_info;
    WebhookBanInfo? bi = v.ban_info;
    WebhookRateEligibility? ri = v.auth_international_rate_eligibility;
    WebhookVolumeTierInfo? vti = v.volume_tier_info;
    WebhookCertificationInfo? ci = v.partner_client_certification_info;
    WebhookDisconnectionInfo? di = v.disconnection_info;
    WebhookRestriction[]? restrictions = v.restriction_info;
    return {
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
        violationInfo: vi is WebhookViolationInfo ? {violationType: vi.violation_type} : (),
        banInfo: bi is WebhookBanInfo ? {wabaBanState: bi.waba_ban_state, wabaBanDate: bi.waba_ban_date} : (),
        rateEligibility: ri is WebhookRateEligibility ? toAccountUpdateRateEligibility(ri) : (),
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
    };
}

isolated function toBusinessCapabilityUpdate(string wabaId, WebhookBusinessCapabilityValue v,
        int? entryTimestamp, json valueJson) returns BusinessCapabilityUpdate => {
    wabaId,
    maxDailyConversationsPerBusiness: v.max_daily_conversations_per_business,
    maxPhoneNumbersPerBusiness: v.max_phone_numbers_per_business,
    maxPhoneNumbersPerWaba: v.max_phone_numbers_per_waba,
    maxDailyConversationsPerPhone: v.max_daily_conversations_per_phone,
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toMessageTemplateQualityUpdate(string wabaId, WebhookTemplateQualityValue v,
        int? entryTimestamp, json valueJson) returns MessageTemplateQualityUpdate => {
    wabaId,
    messageTemplateId: v.message_template_id ?: 0,
    messageTemplateName: v.message_template_name ?: "",
    messageTemplateLanguage: v.message_template_language ?: "",
    previousQualityScore: v.previous_quality_score ?: "",
    newQualityScore: v.new_quality_score ?: "",
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toMessageTemplateStatusUpdate(string wabaId, WebhookTemplateStatusValue v,
        int? entryTimestamp, json valueJson) returns MessageTemplateStatusUpdate {
    WebhookTemplateDisableInfo? disableInfo = v.disable_info;
    WebhookTemplateOtherInfo? otherInfo = v.other_info;
    WebhookTemplateRejectionInfo? rejectionInfo = v.rejection_info;
    return {
        wabaId,
        event: v.event ?: "",
        messageTemplateId: v.message_template_id ?: 0,
        messageTemplateName: v.message_template_name ?: "",
        messageTemplateLanguage: v.message_template_language ?: "",
        reason: v.reason,
        messageTemplateCategory: v.message_template_category,
        disableInfo: disableInfo is WebhookTemplateDisableInfo ? {disableDate: disableInfo.disable_date} : (),
        otherInfo: otherInfo is WebhookTemplateOtherInfo ?
                {title: otherInfo.title, description: otherInfo.description} : (),
        rejectionInfo: rejectionInfo is WebhookTemplateRejectionInfo ? {
                reason: rejectionInfo.reason,
                recommendation: rejectionInfo.recommendation
            } : (),
        timestamp: entryTimestamp,
        raw: valueJson
    };
}

isolated function toPhoneNumberNameUpdate(string wabaId, WebhookPhoneNumberNameValue v, int? entryTimestamp,
        json valueJson) returns PhoneNumberNameUpdate => {
    wabaId,
    displayPhoneNumber: v.display_phone_number ?: "",
    decision: v.decision ?: "",
    requestedVerifiedName: v.requested_verified_name ?: "",
    rejectionReason: v.rejection_reason,
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toPhoneNumberQualityUpdate(string wabaId, WebhookPhoneNumberQualityValue v,
        int? entryTimestamp, json valueJson) returns PhoneNumberQualityUpdate => {
    wabaId,
    displayPhoneNumber: v.display_phone_number ?: "",
    event: v.event ?: "",
    currentLimit: v.current_limit,
    oldLimit: v.old_limit,
    maxDailyConversationsPerBusiness: v.max_daily_conversations_per_business,
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toSecurity(string wabaId, WebhookSecurityValue v, int? entryTimestamp, json valueJson)
        returns Security => {
    wabaId,
    displayPhoneNumber: v.display_phone_number ?: "",
    event: v.event ?: "",
    requester: v.requester,
    timestamp: entryTimestamp,
    raw: valueJson
};

isolated function toTemplateCategoryUpdate(string wabaId, WebhookTemplateCategoryValue v, int? entryTimestamp,
        json valueJson) returns TemplateCategoryUpdate => {
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
};

# The HTTP service that backs the WhatsApp `Listener`. It handles the subscription handshake
# (GET) and inbound notifications (POST), authenticates them, and dispatches parsed events to
# the attached `WhatsAppService`.
service class HttpService {
    *http:Service;

    private final WhatsAppService whatsappService;
    private final string verifyToken;
    private final string appSecret;
    private final boolean autoAck;

    function init(WhatsAppService whatsappService, string verifyToken, string appSecret, boolean autoAck) {
        self.whatsappService = whatsappService;
        self.verifyToken = verifyToken;
        self.appSecret = appSecret;
        self.autoAck = autoAck;
    }

    # Webhook subscription verification handshake. Meta calls this once when the callback URL is
    # saved, expecting the `hub.challenge` echoed back on a matching `hub.verify_token`.
    #
    # + request - The handshake request, carrying the `hub.mode`/`hub.verify_token`/`hub.challenge`
    #              query parameters
    # + return - `200` with the challenge echoed back if verification succeeds, otherwise `403`
    #            with an explanation of the failure
    resource function get .(http:Request request) returns http:Ok|http:Forbidden {
        string? mode = request.getQueryParamValue(QUERY_PARAM_HUB_MODE);
        string? token = request.getQueryParamValue(QUERY_PARAM_HUB_VERIFY_TOKEN);
        string? challenge = request.getQueryParamValue(QUERY_PARAM_HUB_CHALLENGE);
        if mode == HUB_MODE_SUBSCRIBE && challenge is string && token == self.verifyToken {
            return <http:Ok>{body: challenge};
        }
        return <http:Forbidden>{body: ERR_WEBHOOK_VERIFICATION_FAILED};
    }

    # Inbound notification handler. Verifies the payload signature, then parses the envelope and
    # dispatches each message/status/event. If `autoAck` is set (the default), acknowledges
    # immediately — before dispatching — since Meta requires a fast 2xx (retries otherwise);
    # otherwise, acknowledgement is left to the dispatched handler via the `Caller` it's given as
    # its optional second parameter.
    #
    # + caller - The HTTP caller used to acknowledge the notification (directly, or via a `Caller`)
    # + request - The inbound webhook notification request
    # + return - An error if the acknowledgement could not be sent; errors from dispatching the
    #            parsed event to the `WhatsAppService` are logged instead of returned
    resource function post .(http:Caller caller, http:Request request) returns error? {
        string|error rawPayload = request.getTextPayload();
        if rawPayload is error {
            log:printError(ERR_PAYLOAD_READ_FAILED, rawPayload);
            return caller->respond(<http:BadRequest>{body: ERR_PAYLOAD_READ_FAILED});
        }
        log:printDebug(LOG_WEBHOOK_POST_RECEIVED, payloadLength = rawPayload.length());

        string|error signatureHeader = request.getHeader(WEBHOOK_SIGNATURE_HEADER);
        string signature = signatureHeader is string ? signatureHeader : "";
        boolean|error valid = verifyWebhookSignature(rawPayload, signature, self.appSecret);
        if valid is error || !valid {
            log:printWarn(WARN_SIGNATURE_VERIFICATION_FAILED);
            return caller->respond(<http:Unauthorized>{body: WARN_SIGNATURE_VERIFICATION_FAILED});
        }

        json|error payload = rawPayload.fromJsonString();
        if payload is error {
            log:printError(ERR_PAYLOAD_PARSE_FAILED, payload);
            return caller->respond(<http:BadRequest>{body: ERR_PAYLOAD_PARSE_FAILED});
        }

        Caller ackCaller = new (caller);
        if self.autoAck {
            // Acknowledge receipt first so Meta does not retry, then dispatch (handlers may be
            // slow, e.g. an AI agent invocation). The `Caller` passed to the handler already
            // considers itself acknowledged, so a handler that also declares one and calls
            // `caller->complete()` anyway is a safe no-op.
            check ackCaller->complete();
        }
        // With autoAck false, acknowledgement is the dispatched handler's responsibility, via its
        // `Caller` parameter — if it never acknowledges, this connector never responds, and Meta's
        // own retry-then-give-up behavior is all that follows.
        self.dispatch(payload, ackCaller);
    }

    function dispatch(json payload, Caller caller) {
        WebhookNotification|error notification = payload.cloneWithType();
        if notification is error {
            log:printError(ERR_NOTIFICATION_PARSE_FAILED, notification);
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
                        InboundMessage[] typedMessages = [];
                        foreach WebhookInboundMessage message in messages {
                            InboundMessage|error typedMessage = toInboundMessage(message, contactName);
                            if typedMessage is error {
                                log:printError(ERR_INBOUND_MESSAGE_MISSING_REQUIRED_FIELD, typedMessage,
                                        phoneNumberId = phoneNumberId);
                            } else {
                                typedMessages.push(typedMessage);
                            }
                        }
                        if typedMessages.length() > 0 {
                            Messages messagesNotification = toMessages(phoneNumberId, typedMessages, entryTimestamp,
                                    valueJson);
                            error? result = invokeHandlerIfPresent(self.whatsappService, "onMessages",
                                    messagesNotification, caller);
                            if result is error {
                                log:printError(ERR_ON_MESSAGES_HANDLER, result, phoneNumberId = phoneNumberId);
                                invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                            }
                        }
                    } else if statuses is WebhookStatus[] {
                        MessageStatusUpdate[] typedStatuses = [];
                        foreach WebhookStatus status in statuses {
                            MessageStatusUpdate|error typedStatus = toMessageStatusUpdate(status);
                            if typedStatus is error {
                                log:printError(ERR_STATUS_UPDATE_MISSING_REQUIRED_FIELD, typedStatus,
                                        phoneNumberId = phoneNumberId);
                            } else {
                                typedStatuses.push(typedStatus);
                            }
                        }
                        if typedStatuses.length() > 0 {
                            MessageStatuses statusesNotification = toMessageStatuses(phoneNumberId, typedStatuses,
                                    entryTimestamp, valueJson);
                            error? result = invokeHandlerIfPresent(self.whatsappService, "onMessages",
                                    statusesNotification, caller);
                            if result is error {
                                log:printError(ERR_ON_MESSAGES_HANDLER, result, phoneNumberId = phoneNumberId);
                                invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                            }
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
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                AccountReviewUpdate update = toAccountReviewUpdate(wabaId, v,
                                        entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onAccountReviewUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_ACCOUNT_REVIEW_UPDATE_HANDLER, result, wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_ACCOUNT_UPDATE => {
                            WebhookAccountUpdateValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                AccountUpdate update = toAccountUpdate(wabaId, v, entryTimestamp,
                                        valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onAccountUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_ACCOUNT_UPDATE_HANDLER, result, wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_BUSINESS_CAPABILITY_UPDATE => {
                            WebhookBusinessCapabilityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                BusinessCapabilityUpdate update = toBusinessCapabilityUpdate(wabaId, v,
                                        entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onBusinessCapabilityUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_BUSINESS_CAPABILITY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_MESSAGE_TEMPLATE_QUALITY_UPDATE => {
                            WebhookTemplateQualityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                MessageTemplateQualityUpdate update = toMessageTemplateQualityUpdate(
                                        wabaId, v, entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onMessageTemplateQualityUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_MESSAGE_TEMPLATE_QUALITY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_MESSAGE_TEMPLATE_STATUS_UPDATE => {
                            WebhookTemplateStatusValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                MessageTemplateStatusUpdate update = toMessageTemplateStatusUpdate(
                                        wabaId, v, entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onMessageTemplateStatusUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_MESSAGE_TEMPLATE_STATUS_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_PHONE_NUMBER_NAME_UPDATE => {
                            WebhookPhoneNumberNameValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                PhoneNumberNameUpdate update = toPhoneNumberNameUpdate(wabaId, v,
                                        entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onPhoneNumberNameUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_PHONE_NUMBER_NAME_UPDATE_HANDLER, result, wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_PHONE_NUMBER_QUALITY_UPDATE => {
                            WebhookPhoneNumberQualityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                PhoneNumberQualityUpdate update = toPhoneNumberQualityUpdate(wabaId, v,
                                        entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onPhoneNumberQualityUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_PHONE_NUMBER_QUALITY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_SECURITY => {
                            WebhookSecurityValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                Security security = toSecurity(wabaId, v, entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService, "onSecurity", security, caller);
                                if result is error {
                                    log:printError(ERR_ON_SECURITY_HANDLER, result, wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
                                }
                            }
                        }
                        WEBHOOK_FIELD_TEMPLATE_CATEGORY_UPDATE => {
                            WebhookTemplateCategoryValue|error v = valueJson.cloneWithType();
                            if v is error {
                                log:printError(ERR_WEBHOOK_VALUE_PARSE_FAILED, v, wabaId = wabaId, 'field = 'field);
                            } else {
                                TemplateCategoryUpdate update = toTemplateCategoryUpdate(wabaId, v,
                                        entryTimestamp, valueJson);
                                error? result = invokeHandlerIfPresent(self.whatsappService,
                                        "onTemplateCategoryUpdate", update, caller);
                                if result is error {
                                    log:printError(ERR_ON_TEMPLATE_CATEGORY_UPDATE_HANDLER, result,
                                            wabaId = wabaId);
                                    invokeOnError(self.whatsappService, result, 'field, valueJson, caller);
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
