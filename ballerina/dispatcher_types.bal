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

// Internal types used to parse the raw WhatsApp webhook notification envelope. They are open and
// all-optional so binding tolerates any extra Meta fields and any event `value` shape; unrecognized
// events are logged and dropped (see `dispatcher_service.bal`'s `dispatch()`).
type WebhookNotification record {
    WebhookEntry[] entry?;
};

type WebhookEntry record {
    string id?;
    int time?;
    WebhookChange[] changes?;
};

type WebhookChange record {
    string 'field?;
    WebhookValue value?;
};

type WebhookValue record {
    WebhookMetadata metadata?;
    WebhookContact[] contacts?;
    WebhookInboundMessage[] messages?;
    WebhookStatus[] statuses?;
};

type WebhookMetadata record {
    string phone_number_id?;
};

type WebhookContact record {
    record {string name?;} profile?;
    string wa_id?;
};

type WebhookInboundMessage record {
    string 'from?;
    string id?;
    string 'type?;
    string timestamp?;
    record {string body?;} text?;
};

type WebhookStatusError record {
    int code?;
    string title?;
    string message?;
    record {string details?;} error_data?;
};

type WebhookStatus record {
    string id?;
    string status?;
    string recipient_id?;
    string timestamp?;
    WebhookStatusError[] errors?;
};

// Loosely-typed wire shapes for the 9 non-message `value` payloads, used only as
// `cloneWithType()` targets. Open and all-optional so undocumented sub-fields don't break
// binding; anything not modeled here is still reachable via the public event's `raw` field.

type WebhookAccountReviewValue record {
    string decision?;
};

type WebhookWabaInfo record {
    string waba_id?;
    string owner_business_id?;
    string ad_account_linked?;
    string partner_app_id?;
    string solution_id?;
    string[] solution_partner_business_ids?;
};

type WebhookViolationInfo record {
    string violation_type?;
};

type WebhookBanInfo record {
    string waba_ban_state?;
    string waba_ban_date?;
};

type WebhookExceptionCountry record {
    string country_code?;
    int start_time?;
};

type WebhookRateEligibility record {
    int start_time?;
    WebhookExceptionCountry[] exception_countries?;
};

type WebhookVolumeTierInfo record {
    int tier_update_time?;
    string pricing_category?;
    string tier?;
    string effective_month?;
    string region?;
};

type WebhookCertificationInfo record {
    string client_business_id?;
    string status?;
    string[] rejection_reasons?;
};

type WebhookDisconnectionInfo record {
    string reason?;
    string initiated_by?;
};

type WebhookRestriction record {
    string restriction_type?;
    int expiration?;
    string remediation?;
};

type WebhookAccountUpdateValue record {
    string event?;
    string country?;
    WebhookWabaInfo waba_info?;
    WebhookViolationInfo violation_info?;
    WebhookRateEligibility auth_international_rate_eligibility?;
    WebhookBanInfo ban_info?;
    WebhookVolumeTierInfo volume_tier_info?;
    WebhookCertificationInfo partner_client_certification_info?;
    WebhookDisconnectionInfo disconnection_info?;
    WebhookRestriction[] restriction_info?;
};

type WebhookBusinessCapabilityValue record {
    int max_daily_conversations_per_business?;
    int max_phone_numbers_per_waba?;
};

type WebhookTemplateQualityValue record {
    string previous_quality_score?;
    string new_quality_score?;
    int message_template_id?;
    string message_template_name?;
    string message_template_language?;
};

type WebhookTemplateDisableInfo record {
    string disable_date?;
};

type WebhookTemplateOtherInfo record {
    string title?;
    string description?;
};

type WebhookTemplateRejectionInfo record {
    string reason?;
    string recommendation?;
};

type WebhookTemplateStatusValue record {
    string event?;
    int message_template_id?;
    string message_template_name?;
    string message_template_language?;
    string reason?;
    string message_template_category?;
    WebhookTemplateDisableInfo disable_info?;
    WebhookTemplateOtherInfo other_info?;
    WebhookTemplateRejectionInfo rejection_info?;
};

type WebhookPhoneNumberNameValue record {
    string display_phone_number?;
    string decision?;
    string requested_verified_name?;
    string rejection_reason?;
};

type WebhookPhoneNumberQualityValue record {
    string display_phone_number?;
    string event?;
    string current_limit?;
    string old_limit?;
    string max_daily_conversations_per_business?;
};

type WebhookSecurityValue record {
    string display_phone_number?;
    string event?;
    string requester?;
};

type WebhookTemplateCategoryValue record {
    int message_template_id?;
    string message_template_name?;
    string message_template_language?;
    string new_category?;
    string previous_category?;
    string correct_category?;
    int category_update_timestamp?;
};
