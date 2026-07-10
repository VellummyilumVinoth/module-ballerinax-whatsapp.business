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

# Configuration for the WhatsApp Business Cloud `Client`.
#
# + auth - Bearer-token authentication (a system-user or temporary access token)
# + apiVersion - The Meta Graph API version path segment used for every request (e.g. `v23.0`)
# + httpVersion - The HTTP version understood by the client
# + http1Settings - Configurations related to HTTP/1.x protocol
# + http2Settings - Configurations related to HTTP/2 protocol
# + timeout - The maximum time to wait (in seconds) for a response before closing the connection
# + forwarded - The choice of setting `forwarded`/`x-forwarded` header
# + followRedirects - Configurations associated with redirection
# + poolConfig - Configurations associated with request pooling
# + cache - HTTP caching related configurations
# + compression - Specifies the way of handling compression (`accept-encoding`) header
# + circuitBreaker - Configurations associated with the behaviour of the Circuit Breaker
# + retryConfig - Configurations associated with retrying
# + cookieConfig - Configurations associated with cookies
# + responseLimits - Configurations associated with inbound response size limits
# + secureSocket - SSL/TLS-related options
# + proxy - Proxy server related options
# + socketConfig - Provides settings related to client socket configuration
# + validation - Enables the inbound payload validation functionality provided by the constraint package
# + laxDataBinding - Enables relaxed data binding on the client side
public type ConnectionConfig record {|
    http:BearerTokenConfig auth;
    string apiVersion = DEFAULT_API_VERSION;
    http:HttpVersion httpVersion = http:HTTP_2_0;
    http:ClientHttp1Settings http1Settings = {};
    http:ClientHttp2Settings http2Settings = {};
    decimal timeout = 30;
    string forwarded = FORWARDED_DISABLE;
    http:FollowRedirects followRedirects?;
    http:PoolConfiguration poolConfig?;
    http:CacheConfig cache = {};
    http:Compression compression = http:COMPRESSION_AUTO;
    http:CircuitBreakerConfig circuitBreaker?;
    http:RetryConfig retryConfig?;
    http:CookieConfig cookieConfig?;
    http:ResponseLimitConfigs responseLimits = {};
    http:ClientSecureSocket secureSocket?;
    http:ProxyConfig proxy?;
    http:ClientSocketConfig socketConfig = {};
    boolean validation = true;
    boolean laxDataBinding = true;
|};

# A reference to a message being replied to.
#
# + message_id - The WhatsApp message ID (`wamid...`) being replied to
public type MessageContext record {|
    string message_id;
|};

# A media attachment referenced either by a previously uploaded media ID or by a public link.
# Exactly one of `id`/`link` should be set.
#
# + id - The ID of a media object already uploaded via `Client->uploadMedia`
# + link - A public URL Meta will fetch the media from
# + caption - A caption shown with the media (not supported for audio)
# + filename - The filename shown to the recipient (documents only)
public type MediaObject record {|
    string id?;
    string link?;
    string caption?;
    string filename?;
|};

# A text message.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID (phone number, international format, no leading `+`)
# + type - Always `text`
# + text - The message body
# + context - The message being replied to, if this is a reply
public type TextMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_TEXT 'type = MESSAGE_TYPE_TEXT;
    record {|string body; boolean preview_url?;|} text;
    MessageContext context?;
|};

# An image message.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `image`
# + image - The image, by media ID or link
# + context - The message being replied to, if this is a reply
public type ImageMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_IMAGE 'type = MESSAGE_TYPE_IMAGE;
    MediaObject image;
    MessageContext context?;
|};

# An audio message.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `audio`
# + audio - The audio clip, by media ID or link
# + context - The message being replied to, if this is a reply
public type AudioMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_AUDIO 'type = MESSAGE_TYPE_AUDIO;
    MediaObject audio;
    MessageContext context?;
|};

# A video message.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `video`
# + video - The video, by media ID or link
# + context - The message being replied to, if this is a reply
public type VideoMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_VIDEO 'type = MESSAGE_TYPE_VIDEO;
    MediaObject video;
    MessageContext context?;
|};

# A document message.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `document`
# + document - The document, by media ID or link
# + context - The message being replied to, if this is a reply
public type DocumentMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_DOCUMENT 'type = MESSAGE_TYPE_DOCUMENT;
    MediaObject document;
    MessageContext context?;
|};

# A location message.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `location`
# + location - The location being shared
# + context - The message being replied to, if this is a reply
public type LocationMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_LOCATION 'type = MESSAGE_TYPE_LOCATION;
    record {|decimal longitude; decimal latitude; string name?; string address?;|} location;
    MessageContext context?;
|};

# A contact's name, as shared in a `ContactMessage`.
#
# + formatted_name - The contact's full display name  
# + first_name - The contact's first name  
# + last_name - The contact's last name  
# + middle_name - The contact's middle name  
# + suffix - The contact's name suffix  
# + prefix - The contact's name prefix
public type ContactName record {|
    string formatted_name;
    string first_name?;
    string last_name?;
    string middle_name?;
    string suffix?;
    string prefix?;
|};

# One phone number entry on a shared contact.
#
# + phone - The phone number
# + type - The number's category (e.g. `HOME`, `WORK`)
# + wa_id - The number's WhatsApp ID, if it's a WhatsApp user
public type ContactPhone record {|
    string phone?;
    string 'type?;
    string wa_id?;
|};

# One email entry on a shared contact.
#
# + email - The email address
# + type - The email's category (e.g. `HOME`, `WORK`)
public type ContactEmail record {|
    string email?;
    string 'type?;
|};

# One postal address entry on a shared contact.
#
# + street - The street address
# + city - The city
# + state - The state or province
# + zip - The postal code
# + country - The country name
# + country_code - The two-letter country code
# + type - The address's category (e.g. `HOME`, `WORK`)
public type ContactAddress record {|
    string street?;
    string city?;
    string state?;
    string zip?;
    string country?;
    string country_code?;
    string 'type?;
|};

# Organization details on a shared contact.
#
# + company - The company name
# + department - The department name
# + title - The contact's job title
public type ContactOrg record {|
    string company?;
    string department?;
    string title?;
|};

# One URL entry on a shared contact.
#
# + url - The URL
# + type - The URL's category (e.g. `HOME`, `WORK`)
public type ContactUrl record {|
    string url?;
    string 'type?;
|};

# A single shared contact card.
#
# + name - The contact's name
# + phones - The contact's phone numbers
# + emails - The contact's email addresses
# + addresses - The contact's postal addresses
# + org - The contact's organization details
# + urls - The contact's URLs
public type Contact record {|
    ContactName name;
    ContactPhone[] phones?;
    ContactEmail[] emails?;
    ContactAddress[] addresses?;
    ContactOrg org?;
    ContactUrl[] urls?;
|};

# A message sharing one or more contact cards.
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `contacts`
# + contacts - The contact cards being shared
# + context - The message being replied to, if this is a reply
public type ContactMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_CONTACTS 'type = MESSAGE_TYPE_CONTACTS;
    Contact[] contacts;
    MessageContext context?;
|};

# Any message `Client->sendMessage` can send.
public type Message TextMessage|ImageMessage|AudioMessage|VideoMessage|DocumentMessage|LocationMessage|ContactMessage;

# A currency value substituted into a template parameter.
#
# + fallback_value - The value shown if the template can't be localized to the recipient's locale
# + code - The ISO 4217 currency code
# + amount_1000 - The amount, multiplied by 1000 (e.g. `15990` for `15.99`)
public type TemplateCurrencyParameter record {|
    string fallback_value;
    string code;
    int amount_1000;
|};

# A date/time value substituted into a template parameter.
#
# + fallback_value - The value shown if the template can't be localized to the recipient's locale
public type TemplateDateTimeParameter record {|
    string fallback_value;
|};

# One parameter substituted into a template's header or body text.
#
# + type - The parameter kind: `text`, `currency`, `date_time`, or `image` (header media only)
# + text - The substitution value, when `type` is `text`
# + currency - The substitution value, when `type` is `currency`
# + date_time - The substitution value, when `type` is `date_time`
# + image - The header media, when `type` is `image`
public type TemplateParameter record {|
    string 'type;
    string text?;
    TemplateCurrencyParameter currency?;
    TemplateDateTimeParameter date_time?;
    MediaObject image?;
|};

# One populated component (header, body, or button) of a message template.
#
# + type - The component kind: `header`, `body`, or `button`
# + parameters - The parameters substituted into this component
# + sub_type - The button kind (`quick_reply` or `url`); only present when `type` is `button`
# + index - The zero-based button position on the template; only present when `type` is `button`
public type TemplateComponent record {|
    string 'type;
    TemplateParameter[] parameters?;
    string sub_type?;
    int index?;
|};

# The template being sent, identified by name and language.
#
# + name - The template's name, as approved in the WhatsApp Manager
# + language - The template's language
# + components - The template's populated header/body/button components
public type TemplateObject record {|
    string name;
    record {|string code;|} language;
    TemplateComponent[] components?;
|};

# A pre-approved template message. Required for messages sent outside the 24-hour customer service
# window (e.g. the first message in a conversation).
#
# + messaging_product - Always `whatsapp`
# + recipient_type - Always `individual`
# + to - The recipient's WhatsApp ID
# + type - Always `template`
# + template - The template to send
public type TemplateMessage record {|
    string messaging_product = MESSAGING_PRODUCT_WHATSAPP;
    string recipient_type = RECIPIENT_TYPE_INDIVIDUAL;
    string to;
    MESSAGE_TYPE_TEMPLATE 'type = MESSAGE_TYPE_TEMPLATE;
    TemplateObject template;
|};

# A recipient WhatsApp ID resolved from a `sendMessage`/`sendTemplateMessage` request.
#
# + input - The phone number supplied in the request
# + wa_id - The recipient's resolved WhatsApp ID
public type MessageRecipient record {
    string input;
    string wa_id;
};

# A message accepted by the WhatsApp Cloud API for delivery.
#
# + id - The unique WhatsApp message ID (`wamid...`)
public type SentMessage record {
    string id;
};

# The response returned after sending a message or template.
#
# + messaging_product - Always `whatsapp`
# + contacts - The resolved recipient(s)
# + messages - The accepted message(s)
public type MessageResponsePayload record {
    string messaging_product;
    MessageRecipient[] contacts?;
    SentMessage[] messages?;
};

# The file to upload as a reusable media object.
#
# + fileContent - The raw file bytes
# + fileName - The filename sent with the upload
# + mimeType - The file's MIME type (e.g. `image/jpeg`, `application/pdf`)
public type MediaUploadRequest record {|
    byte[] fileContent;
    string fileName;
    string mimeType;
|};

# The media ID assigned to an uploaded file. Use it in a `MediaObject.id` to send it, or with
# `retrieveMediaUrl`/`deleteMedia`.
#
# + id - The uploaded media's ID
public type MediaUploadResponse record {
    string id;
};

# The metadata and short-lived download URL for a media object.
#
# + url - A signed URL valid for a short time; fetch it (e.g. via `downloadMedia`) promptly
# + mime_type - The media's MIME type
# + sha256 - The SHA-256 checksum of the media's bytes
# + file_size - The media's size, in bytes, as reported by Meta
# + id - The media's ID
public type MediaUrlResponse record {
    string url;
    string mime_type;
    string sha256;
    string file_size;
    string id;
};

# The result of deleting a media object.
#
# + success - Whether the delete succeeded
public type MediaDeleteResponse record {
    boolean success;
};
