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

// ── API Base URLs ───────────────────────────────────────────────────────────────

# The default base URL for the Meta Graph API.
const string DEFAULT_BASE_URL = "https://graph.facebook.com";

# The default Meta Graph API version path segment used for every request.
const string DEFAULT_API_VERSION = "v23.0";

// ── Webhook Verification ────────────────────────────────────────────────────────

# The header Meta signs every webhook request body with (HMAC-SHA256, keyed by the app secret).
const string WEBHOOK_SIGNATURE_HEADER = "X-Hub-Signature-256";

# Query parameter carrying the subscription mode on the verification handshake.
const string QUERY_PARAM_HUB_MODE = "hub.mode";

# Query parameter carrying the verify token on the verification handshake.
const string QUERY_PARAM_HUB_VERIFY_TOKEN = "hub.verify_token";

# Query parameter carrying the challenge to be echoed back on the verification handshake.
const string QUERY_PARAM_HUB_CHALLENGE = "hub.challenge";

# The `hub.mode` value Meta sends on a subscription verification handshake.
const string HUB_MODE_SUBSCRIBE = "subscribe";

// ── Message Constants ───────────────────────────────────────────────────────────
// Declared without an explicit `string` type so each constant retains its singleton literal
// type, letting it double as both a `'type` field's type descriptor and its default value.

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
const string WEBHOOK_FIELD_MESSAGES = "messages";

# Webhook field for a WhatsApp Business Account review decision.
const string WEBHOOK_FIELD_ACCOUNT_REVIEW_UPDATE = "account_review_update";

# Webhook field for a WhatsApp Business Account lifecycle update.
const string WEBHOOK_FIELD_ACCOUNT_UPDATE = "account_update";

# Webhook field for a change in the account's business capability limits.
const string WEBHOOK_FIELD_BUSINESS_CAPABILITY_UPDATE = "business_capability_update";

# Webhook field for a message template's quality score update.
const string WEBHOOK_FIELD_MESSAGE_TEMPLATE_QUALITY_UPDATE = "message_template_quality_update";

# Webhook field for a message template's approval status update.
const string WEBHOOK_FIELD_MESSAGE_TEMPLATE_STATUS_UPDATE = "message_template_status_update";

# Webhook field for a phone number's display name update.
const string WEBHOOK_FIELD_PHONE_NUMBER_NAME_UPDATE = "phone_number_name_update";

# Webhook field for a phone number's messaging quality/tier update.
const string WEBHOOK_FIELD_PHONE_NUMBER_QUALITY_UPDATE = "phone_number_quality_update";

# Webhook field for a PIN change/reset security event.
const string WEBHOOK_FIELD_SECURITY = "security";

# Webhook field for a message template's category update.
const string WEBHOOK_FIELD_TEMPLATE_CATEGORY_UPDATE = "template_category_update";

// ── Log Messages ────────────────────────────────────────────────────────────────

const string LOG_WEBHOOK_POST_RECEIVED = "WhatsApp webhook POST received";

// ── Warning Messages ────────────────────────────────────────────────────────────

const string WARN_PAYLOAD_READ_FAILED = "Failed to read WhatsApp webhook payload as text";
const string WARN_SIGNATURE_VERIFICATION_FAILED =
    "WhatsApp webhook signature verification failed; rejecting notification";
const string WARN_PAYLOAD_PARSE_FAILED = "Failed to parse WhatsApp webhook payload as JSON";
const string WARN_NOTIFICATION_PARSE_FAILED = "Failed to parse WhatsApp webhook notification envelope";
const string WARN_WEBHOOK_VALUE_PARSE_FAILED = "Failed to parse WhatsApp webhook event value; dropping notification";
const string WARN_UNRECOGNIZED_WEBHOOK_FIELD = "Unrecognized WhatsApp webhook field; dropping notification";

// ── Error Messages ──────────────────────────────────────────────────────────────

const string ERR_ON_MESSAGES_HANDLER = "Error in onMessages handler";
const string ERR_ON_ACCOUNT_REVIEW_UPDATE_HANDLER = "Error in onAccountReviewUpdate handler";
const string ERR_ON_ACCOUNT_UPDATE_HANDLER = "Error in onAccountUpdate handler";
const string ERR_ON_BUSINESS_CAPABILITY_UPDATE_HANDLER = "Error in onBusinessCapabilityUpdate handler";
const string ERR_ON_MESSAGE_TEMPLATE_QUALITY_UPDATE_HANDLER = "Error in onMessageTemplateQualityUpdate handler";
const string ERR_ON_MESSAGE_TEMPLATE_STATUS_UPDATE_HANDLER = "Error in onMessageTemplateStatusUpdate handler";
const string ERR_ON_PHONE_NUMBER_NAME_UPDATE_HANDLER = "Error in onPhoneNumberNameUpdate handler";
const string ERR_ON_PHONE_NUMBER_QUALITY_UPDATE_HANDLER = "Error in onPhoneNumberQualityUpdate handler";
const string ERR_ON_SECURITY_HANDLER = "Error in onSecurity handler";
const string ERR_ON_TEMPLATE_CATEGORY_UPDATE_HANDLER = "Error in onTemplateCategoryUpdate handler";

// ── Other Constants ─────────────────────────────────────────────────────────────

# Default value for `ConnectionConfig.forwarded` — disables the `forwarded`/`x-forwarded` header.
const string FORWARDED_DISABLE = "disable";
