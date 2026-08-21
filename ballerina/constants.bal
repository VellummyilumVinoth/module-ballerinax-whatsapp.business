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

// Constants below are declared without an explicit `string` type so each retains its singleton
// literal type; this also lets the message-type constants double as both a `'type` field's type
// descriptor and its default value.

// ── API Base URLs ───────────────────────────────────────────────────────────────

# The default base URL for the Meta Graph API.
const DEFAULT_BASE_URL = "https://graph.facebook.com";

# The default Meta Graph API version path segment used for every request.
const DEFAULT_API_VERSION = "v23.0";

// ── Webhook Verification ────────────────────────────────────────────────────────

# The header Meta signs every webhook request body with (HMAC-SHA256, keyed by the app secret).
const WEBHOOK_SIGNATURE_HEADER = "X-Hub-Signature-256";

# Query parameter carrying the subscription mode on the verification handshake.
const QUERY_PARAM_HUB_MODE = "hub.mode";

# Query parameter carrying the verify token on the verification handshake.
const QUERY_PARAM_HUB_VERIFY_TOKEN = "hub.verify_token";

# Query parameter carrying the challenge to be echoed back on the verification handshake.
const QUERY_PARAM_HUB_CHALLENGE = "hub.challenge";

# The `hub.mode` value Meta sends on a subscription verification handshake.
const HUB_MODE_SUBSCRIBE = "subscribe";

// ── Message Constants ───────────────────────────────────────────────────────────

# The `messaging_product` value on every outbound message and template.
const MESSAGING_PRODUCT_WHATSAPP = "whatsapp";

# The `recipient_type` value on every outbound message and template.
const RECIPIENT_TYPE_INDIVIDUAL = "individual";

# Message `type` discriminator for a `TextMessage`.
const MESSAGE_TYPE_TEXT = "text";

# Message `type` discriminator for an `ImageMessage`.
const MESSAGE_TYPE_IMAGE = "image";

# Message `type` discriminator for an `AudioMessage`.
const MESSAGE_TYPE_AUDIO = "audio";

# Message `type` discriminator for a `VideoMessage`.
const MESSAGE_TYPE_VIDEO = "video";

# Message `type` discriminator for a `DocumentMessage`.
const MESSAGE_TYPE_DOCUMENT = "document";

# Message `type` discriminator for a `LocationMessage`.
const MESSAGE_TYPE_LOCATION = "location";

# Message `type` discriminator for a `ContactMessage`.
const MESSAGE_TYPE_CONTACTS = "contacts";

# Message `type` discriminator for a `TemplateMessage`.
const MESSAGE_TYPE_TEMPLATE = "template";

// ── Webhook Field (Event Type) Constants ────────────────────────────────────────

# Webhook field for inbound messages and message status updates.
const WEBHOOK_FIELD_MESSAGES = "messages";

# Webhook field for a WhatsApp Business Account review decision.
const WEBHOOK_FIELD_ACCOUNT_REVIEW_UPDATE = "account_review_update";

# Webhook field for a WhatsApp Business Account lifecycle update.
const WEBHOOK_FIELD_ACCOUNT_UPDATE = "account_update";

# Webhook field for a change in the account's business capability limits.
const WEBHOOK_FIELD_BUSINESS_CAPABILITY_UPDATE = "business_capability_update";

# Webhook field for a message template's quality score update.
const WEBHOOK_FIELD_MESSAGE_TEMPLATE_QUALITY_UPDATE = "message_template_quality_update";

# Webhook field for a message template's approval status update.
const WEBHOOK_FIELD_MESSAGE_TEMPLATE_STATUS_UPDATE = "message_template_status_update";

# Webhook field for a phone number's display name update.
const WEBHOOK_FIELD_PHONE_NUMBER_NAME_UPDATE = "phone_number_name_update";

# Webhook field for a phone number's messaging quality/tier update.
const WEBHOOK_FIELD_PHONE_NUMBER_QUALITY_UPDATE = "phone_number_quality_update";

# Webhook field for a PIN change/reset security event.
const WEBHOOK_FIELD_SECURITY = "security";

# Webhook field for a message template's category update.
const WEBHOOK_FIELD_TEMPLATE_CATEGORY_UPDATE = "template_category_update";

// ── Log Messages ────────────────────────────────────────────────────────────────

const LOG_WEBHOOK_POST_RECEIVED = "WhatsApp webhook POST received";

// ── Warning Messages ────────────────────────────────────────────────────────────
// Reserved for conditions that are expected/benign and do not, by themselves, indicate lost data.

const WARN_SIGNATURE_VERIFICATION_FAILED =
    "WhatsApp webhook signature verification failed; rejecting notification";
const WARN_UNRECOGNIZED_WEBHOOK_FIELD = "Unrecognized WhatsApp webhook field; dropping notification";

// ── Error Messages ──────────────────────────────────────────────────────────────
// Includes conditions where malformed data caused a webhook notification (or part of one) to be
// silently dropped, in addition to the connector's own request/handler failures.

const ERR_WEBHOOK_VERIFICATION_FAILED =
    "Webhook verification failed: invalid hub.mode, hub.verify_token, or missing hub.challenge";
const ERR_PAYLOAD_READ_FAILED = "Failed to read WhatsApp webhook payload as text";
const ERR_PAYLOAD_PARSE_FAILED = "Failed to parse WhatsApp webhook payload as JSON";
const ERR_NOTIFICATION_PARSE_FAILED = "Failed to parse WhatsApp webhook notification envelope";
const ERR_WEBHOOK_VALUE_PARSE_FAILED = "Failed to parse WhatsApp webhook event value; dropping notification";
const ERR_STATUS_UPDATE_MISSING_REQUIRED_FIELD =
    "WhatsApp status update is missing a required field (id, status, or recipient_id); dropping status update";
const ERR_INBOUND_MESSAGE_MISSING_REQUIRED_FIELD =
    "WhatsApp inbound message is missing a required field (id, from, or type); dropping message";
const ERR_ON_MESSAGES_HANDLER = "Error in onMessages handler";
const ERR_ON_ACCOUNT_REVIEW_UPDATE_HANDLER = "Error in onAccountReviewUpdate handler";
const ERR_ON_ACCOUNT_UPDATE_HANDLER = "Error in onAccountUpdate handler";
const ERR_ON_BUSINESS_CAPABILITY_UPDATE_HANDLER = "Error in onBusinessCapabilityUpdate handler";
const ERR_ON_MESSAGE_TEMPLATE_QUALITY_UPDATE_HANDLER = "Error in onMessageTemplateQualityUpdate handler";
const ERR_ON_MESSAGE_TEMPLATE_STATUS_UPDATE_HANDLER = "Error in onMessageTemplateStatusUpdate handler";
const ERR_ON_PHONE_NUMBER_NAME_UPDATE_HANDLER = "Error in onPhoneNumberNameUpdate handler";
const ERR_ON_PHONE_NUMBER_QUALITY_UPDATE_HANDLER = "Error in onPhoneNumberQualityUpdate handler";
const ERR_ON_SECURITY_HANDLER = "Error in onSecurity handler";
const ERR_ON_TEMPLATE_CATEGORY_UPDATE_HANDLER = "Error in onTemplateCategoryUpdate handler";
const ERR_ON_ERROR_HANDLER = "Error in onError handler";
const ERR_ACK_FAILED = "Failed to acknowledge the WhatsApp webhook notification";

// ── Other Constants ─────────────────────────────────────────────────────────────

# Default value for `ConnectionConfig.forwarded` — disables the `forwarded`/`x-forwarded` header.
const FORWARDED_DISABLE = "disable";
