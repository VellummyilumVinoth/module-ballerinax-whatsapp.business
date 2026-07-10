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

# Configuration for the WhatsApp Business Cloud webhook `Listener`.
#
# + verifyToken - The verification token configured in the Meta App dashboard. Matched against
# `hub.verify_token` during the webhook subscription handshake before the `hub.challenge` is
# echoed back.
# + appSecret - The Meta app secret. Every inbound notification is authenticated by validating the
# `X-Hub-Signature-256` header against the raw request body (HMAC-SHA256).
public type ListenerConfig record {|
    string verifyToken;
    string appSecret;
|};

# One inbound WhatsApp message, part of a `MessagesEvent` batch.
#
# + 'from - The WhatsApp ID (phone number) of the sender
# + messageId - The unique WhatsApp message ID (`wamid...`)
# + messageType - The message type (e.g. `text`, `image`, `interactive`)
# + text - The message body for text messages; `()` for non-text messages
# + timestamp - The provider-reported timestamp of the message, if present
# + contactName - The sender's WhatsApp profile name, if present
# + raw - The raw message object as received, for accessing type-specific fields
public type InboundMessage record {|
    string 'from;
    string messageId;
    string messageType;
    string? text = ();
    string? timestamp = ();
    string? contactName = ();
    json raw;
|};

# A delivery failure reported against a message status.
#
# + code - Meta's error code
# + title - A short error title
# + message - A human-readable error message
# + details - Further detail, if present
public type MessageErrorDetail record {|
    int? code = ();
    string? title = ();
    string? message = ();
    string? details = ();
|};

# One outbound message status update, part of a `MessageStatusEvent` batch.
#
# + messageId - The message ID whose status changed
# + status - The new status (`sent`, `delivered`, `read`, `failed`)
# + recipientId - The WhatsApp ID of the recipient
# + timestamp - The provider-reported timestamp of the status change, if present
# + errors - Delivery failure details; present only when `status` is `failed`
# + raw - The raw status object as received
public type MessageStatusUpdate record {|
    string messageId;
    string status;
    string recipientId;
    string? timestamp = ();
    MessageErrorDetail[]? errors = ();
    json raw;
|};

# A `messages` webhook notification that carries one or more new inbound messages. Meta always
# sends inbound messages and status updates as two mutually exclusive payload shapes under this
# same field — never both together in the same notification — so this and `MessageStatusEvent`
# are the two members of the `MessagesNotificationEvent` union `onMessages` takes.
#
# + phoneNumberId - The business phone number ID the notification relates to
# + messages - The inbound messages
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type MessagesEvent record {|
    string phoneNumberId;
    InboundMessage[] messages;
    int? timestamp = ();
    json raw;
|};

# A `messages` webhook notification that carries one or more outbound message status updates
# (delivery/read receipts). See `MessagesEvent` for why this is a separate type.
#
# + phoneNumberId - The business phone number ID the notification relates to
# + statuses - The status updates
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type MessageStatusEvent record {|
    string phoneNumberId;
    MessageStatusUpdate[] statuses;
    int? timestamp = ();
    json raw;
|};

# A `messages` webhook notification: either a batch of inbound messages (`MessagesEvent`) or a
# batch of status updates (`MessageStatusEvent`) — Meta always sends these as two mutually
# exclusive shapes under this one field, never both together. Narrow with
# `event is MessagesEvent` / `event is MessageStatusEvent`.
public type MessagesNotificationEvent MessagesEvent|MessageStatusEvent;

# A WhatsApp Business Account (WABA) review decision.
#
# + wabaId - The WhatsApp Business Account ID the review relates to
# + decision - The review outcome (`APPROVED`, `REJECTED`, `PENDING`, or `DEFERRED`)
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received, for accessing undocumented fields
public type AccountReviewUpdateEvent record {|
    string wabaId;
    string decision;
    int? timestamp = ();
    json raw;
|};

# Partner/business relationship details on an `account_update` event. Populated only for events
# where it is relevant.
#
# + wabaId - The owning WhatsApp Business Account ID, if present
# + ownerBusinessId - The owning Business Portfolio ID, if present
# + adAccountLinked - The linked ad account ID, if present
# + partnerAppId - The partner app ID, if present
# + solutionId - The solution ID, if present
# + solutionPartnerBusinessIds - The solution partner business IDs, if present
public type AccountUpdateWabaInfo record {|
    string? wabaId = ();
    string? ownerBusinessId = ();
    string? adAccountLinked = ();
    string? partnerAppId = ();
    string? solutionId = ();
    string[]? solutionPartnerBusinessIds = ();
|};

# Policy violation details, present only for `ACCOUNT_VIOLATION` events.
#
# + violationType - The violation classification
public type AccountUpdateViolationInfo record {|
    string? violationType = ();
|};

# Account disable/reinstate details, present only for `DISABLED_UPDATE` events.
#
# + wabaBanState - The current ban state
# + wabaBanDate - The date the ban took effect
public type AccountUpdateBanInfo record {|
    string? wabaBanState = ();
    string? wabaBanDate = ();
|};

# WhatsApp Business app disconnection details.
#
# + reason - The disconnection reason
# + initiatedBy - Who/what initiated the disconnection
public type AccountUpdateDisconnectionInfo record {|
    string? reason = ();
    string? initiatedBy = ();
|};

# A country exception to a rate-eligibility window.
#
# + countryCode - The exception country's ISO code
# + startTime - Unix epoch seconds the exception starts
public type AccountUpdateExceptionCountry record {|
    string? countryCode = ();
    int? startTime = ();
|};

# International rate eligibility timeline, present only for rate-related events.
#
# + startTime - Unix epoch seconds the eligibility window starts
# + exceptionCountries - Per-country exceptions to the window
public type AccountUpdateRateEligibility record {|
    int? startTime = ();
    AccountUpdateExceptionCountry[]? exceptionCountries = ();
|};

# Messaging volume pricing tier metadata, present only for tier-update events.
#
# + tierUpdateTime - Unix epoch seconds of the tier change
# + pricingCategory - The pricing category
# + tier - The new tier
# + effectiveMonth - The month the tier takes effect
# + region - The pricing region
public type AccountUpdateVolumeTierInfo record {|
    int? tierUpdateTime = ();
    string? pricingCategory = ();
    string? tier = ();
    string? effectiveMonth = ();
    string? region = ();
|};

# Business verification submission status, present only for partner-client certification events.
#
# + clientBusinessId - The customer Business Portfolio ID
# + status - The certification status
# + rejectionReasons - Reasons for rejection, if rejected
public type AccountUpdateCertificationInfo record {|
    string? clientBusinessId = ();
    string? status = ();
    string[]? rejectionReasons = ();
|};

# A single functional restriction, present only for `ACCOUNT_RESTRICTION` events.
#
# + restrictionType - The type of restriction applied
# + expiration - Unix epoch seconds the restriction expires
# + remediation - Steps to remediate/lift the restriction
public type AccountUpdateRestriction record {|
    string? restrictionType = ();
    int? expiration = ();
    string? remediation = ();
|};

# A WABA account-lifecycle or compliance change: verification, violations, partner changes,
# pricing-tier updates, restrictions, or disconnection. Only the sub-record matching `event` is
# populated; the rest are `()`.
#
# + wabaId - The WhatsApp Business Account ID the change relates to
# + event - The event type (e.g. `ACCOUNT_DELETED`, `ACCOUNT_VIOLATION`, `PARTNER_ADDED`, `DISABLED_UPDATE`)
# + country - The ISO country code; present only for location-related events
# + wabaInfo - Account/partner relationship details, if present
# + violationInfo - Present only for `ACCOUNT_VIOLATION` events
# + banInfo - Present only for `DISABLED_UPDATE` events
# + rateEligibility - Present only for international-rate-eligibility events
# + volumeTierInfo - Present only for volume-tier-update events
# + certificationInfo - Present only for partner-client-certification events
# + disconnectionInfo - Present only for WhatsApp Business app disconnection events
# + restrictions - Present only for `ACCOUNT_RESTRICTION` events
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received, for accessing undocumented sub-fields
public type AccountUpdateEvent record {|
    string wabaId;
    string event;
    string? country = ();
    AccountUpdateWabaInfo? wabaInfo = ();
    AccountUpdateViolationInfo? violationInfo = ();
    AccountUpdateBanInfo? banInfo = ();
    AccountUpdateRateEligibility? rateEligibility = ();
    AccountUpdateVolumeTierInfo? volumeTierInfo = ();
    AccountUpdateCertificationInfo? certificationInfo = ();
    AccountUpdateDisconnectionInfo? disconnectionInfo = ();
    AccountUpdateRestriction[]? restrictions = ();
    int? timestamp = ();
    json raw;
|};

# A WABA business-capability change: creation, or a rise/fall in messaging or phone-number limits.
#
# + wabaId - The WhatsApp Business Account ID the change relates to
# + maxDailyConversationsPerBusiness - The updated daily conversation messaging cap, if present
# + maxPhoneNumbersPerBusiness - The updated maximum phone numbers allowed on the business, if present
# + maxPhoneNumbersPerWaba - The updated maximum phone numbers allowed on the WABA, if present
# + maxDailyConversationsPerPhone - The per-phone-number daily conversation cap; deprecated by Meta
# in favor of `maxDailyConversationsPerBusiness` (removal targeted ~Feb 2026), but still observed
# on some payloads
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type BusinessCapabilityUpdateEvent record {|
    string wabaId;
    int? maxDailyConversationsPerBusiness = ();
    int? maxPhoneNumbersPerBusiness = ();
    int? maxPhoneNumbersPerWaba = ();
    int? maxDailyConversationsPerPhone = ();
    int? timestamp = ();
    json raw;
|};

# A message template quality-score change.
#
# + wabaId - The WhatsApp Business Account ID the template belongs to
# + messageTemplateId - The unique template ID
# + messageTemplateName - The template's name
# + messageTemplateLanguage - The template's language/locale code (e.g. `en_US`)
# + previousQualityScore - The prior quality score (`GREEN`, `YELLOW`, `RED`, or `UNKNOWN`)
# + newQualityScore - The updated quality score
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type MessageTemplateQualityUpdateEvent record {|
    string wabaId;
    int messageTemplateId;
    string messageTemplateName;
    string messageTemplateLanguage;
    string previousQualityScore;
    string newQualityScore;
    int? timestamp = ();
    json raw;
|};

# Present only when a template was disabled.
#
# + disableDate - The date the template was disabled
public type MessageTemplateDisableInfo record {|
    string? disableDate = ();
|};

# Present only for lock/unlock-style template status events.
#
# + title - A short title describing the event
# + description - A longer description
public type MessageTemplateOtherInfo record {|
    string? title = ();
    string? description = ();
|};

# Present only for `INVALID_FORMAT` template rejections.
#
# + reason - The detailed rejection reason
# + recommendation - Guidance on how to correct the template
public type MessageTemplateRejectionInfo record {|
    string? reason = ();
    string? recommendation = ();
|};

# A message template status change (approved, rejected, disabled, archived, unarchived, ...).
#
# + wabaId - The WhatsApp Business Account ID the template belongs to
# + event - The status-change event (e.g. `APPROVED`, `REJECTED`, `DISABLED`, `ARCHIVED`, `UNARCHIVED`)
# + messageTemplateId - The unique template ID
# + messageTemplateName - The template's name
# + messageTemplateLanguage - The template's language/locale code
# + reason - The rejection reason (e.g. `INVALID_FORMAT`, `ABUSIVE_CONTENT`), if present
# + messageTemplateCategory - The template category (`MARKETING`, `UTILITY`, `AUTHENTICATION`), if present
# + disableInfo - Present only when the template was disabled
# + otherInfo - Present only for lock/unlock-style events
# + rejectionInfo - Present only for `INVALID_FORMAT` rejections
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type MessageTemplateStatusUpdateEvent record {|
    string wabaId;
    string event;
    int messageTemplateId;
    string messageTemplateName;
    string messageTemplateLanguage;
    string? reason = ();
    string? messageTemplateCategory = ();
    MessageTemplateDisableInfo? disableInfo = ();
    MessageTemplateOtherInfo? otherInfo = ();
    MessageTemplateRejectionInfo? rejectionInfo = ();
    int? timestamp = ();
    json raw;
|};

# A business phone number display-name review outcome.
#
# + wabaId - The WhatsApp Business Account ID the phone number belongs to
# + displayPhoneNumber - The business phone number the name change relates to
# + decision - The review outcome (`APPROVED`, `REJECTED`, `PENDING`, or `DEFERRED`)
# + requestedVerifiedName - The display name that was submitted for verification
# + rejectionReason - The rejection reason (e.g. `NAME_EMPLOYEE_ISSUE`), if rejected
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type PhoneNumberNameUpdateEvent record {|
    string wabaId;
    string displayPhoneNumber;
    string decision;
    string requestedVerifiedName;
    string? rejectionReason = ();
    int? timestamp = ();
    json raw;
|};

# A business phone number messaging throughput/quality-tier change.
#
# + wabaId - The WhatsApp Business Account ID the phone number belongs to
# + displayPhoneNumber - The business phone number the change relates to
# + event - The change type (e.g. `THROUGHPUT_UPGRADE`, `ONBOARDING`)
# + currentLimit - The current throughput tier; deprecated by Meta in favor of
# `maxDailyConversationsPerBusiness`, but still observed on some payloads
# + oldLimit - The previous throughput tier, if present
# + maxDailyConversationsPerBusiness - The current messaging capacity tier (e.g. `TIER_2K`), if present
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type PhoneNumberQualityUpdateEvent record {|
    string wabaId;
    string displayPhoneNumber;
    string event;
    string? currentLimit = ();
    string? oldLimit = ();
    string? maxDailyConversationsPerBusiness = ();
    int? timestamp = ();
    json raw;
|};

# A two-step-verification PIN change, reset request, or reset success for a business phone number.
#
# + wabaId - The WhatsApp Business Account ID the phone number belongs to
# + displayPhoneNumber - The business phone number the security event relates to
# + event - The security action (`PIN_CHANGED`, `PIN_RESET_REQUEST`, or `PIN_REQUEST_SUCCESS`)
# + requester - The Meta Business Suite user ID that initiated the action; present only for reset requests
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type SecurityEvent record {|
    string wabaId;
    string displayPhoneNumber;
    string event;
    string? requester = ();
    int? timestamp = ();
    json raw;
|};

# A message template category change, either imminent (24-hour notice) or completed.
#
# + wabaId - The WhatsApp Business Account ID the template belongs to
# + messageTemplateId - The unique template ID
# + messageTemplateName - The template's name
# + messageTemplateLanguage - The template's language/locale code
# + newCategory - The category the template is changing to (imminent) or has changed to (completed)
# + previousCategory - The prior category; present only once the change is completed
# + correctCategory - The category Meta's classifier considers correct; present only for the imminent notice
# + categoryUpdateTimestamp - Unix epoch seconds the scheduled update takes effect; present only for the
# imminent notice
# + timestamp - The entry-level webhook trigger timestamp (Unix epoch seconds), if present
# + raw - The raw `value` object as received
public type TemplateCategoryUpdateEvent record {|
    string wabaId;
    int messageTemplateId;
    string messageTemplateName;
    string messageTemplateLanguage;
    string newCategory;
    string? previousCategory = ();
    string? correctCategory = ();
    int? categoryUpdateTimestamp = ();
    int? timestamp = ();
    json raw;
|};
