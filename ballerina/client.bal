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
import ballerina/mime;

# Client for the WhatsApp Business Cloud API (Meta Graph API), covering sending messages and
# templates, and uploading, retrieving, and deleting media.
@display {label: "Whatsapp Business", iconPath: "icon.png"}
public isolated client class Client {
    private final http:Client clientEp;
    private final string apiVersion;
    private final string accessToken;

    # Initializes the connector.
    #
    # + config - The connection configuration, including the bearer-token auth
    # + serviceUrl - The Meta Graph API base URL
    # + return - A `business:Error` (specifically a `business:ClientError`) if initialization
    #            failed, otherwise `()`
    public isolated function init(ConnectionConfig config, string serviceUrl = DEFAULT_BASE_URL)
    returns Error? {
        http:ClientConfiguration httpClientConfig = {
            auth: config.auth,
            httpVersion: config.httpVersion,
            http1Settings: config.http1Settings,
            http2Settings: config.http2Settings,
            timeout: config.timeout,
            forwarded: config.forwarded,
            followRedirects: config.followRedirects,
            poolConfig: config.poolConfig,
            cache: config.cache,
            compression: config.compression,
            circuitBreaker: config.circuitBreaker,
            retryConfig: config.retryConfig,
            cookieConfig: config.cookieConfig,
            responseLimits: config.responseLimits,
            secureSocket: config.secureSocket,
            proxy: config.proxy,
            socketConfig: config.socketConfig,
            validation: config.validation,
            laxDataBinding: config.laxDataBinding
        };
        http:Client|error clientEp = new (serviceUrl, httpClientConfig);
        if clientEp is error {
            return error ClientError("Failed to initialize the underlying HTTP client", clientEp);
        }
        self.clientEp = clientEp;
        self.apiVersion = config.apiVersion;
        self.accessToken = config.auth.token;
    }

    # Sends a text, image, audio, video, document, location, or contacts message.
    #
    # + phoneNumberId - The business phone number ID sending the message
    # + payload - The message to send
    # + return - The send result, or a `business:Error` (specifically a `business:ClientError`)
    remote isolated function sendMessage(string phoneNumberId, Message payload)
    returns MessageResponsePayload|Error {
        string resourcePath = string `/${self.apiVersion}/${phoneNumberId}/messages`;
        MessageResponsePayload|error response = self.clientEp->post(resourcePath, payload);
        if response is error {
            return error ClientError("Failed to send the message", response);
        }
        return response;
    }

    # Sends a pre-approved message template. Required to start a conversation, or to message a
    # recipient outside the 24-hour customer service window.
    #
    # + phoneNumberId - The business phone number ID sending the message
    # + payload - The template message to send
    # + return - The send result, or a `business:Error` (specifically a `business:ClientError`)
    remote isolated function sendTemplateMessage(string phoneNumberId, TemplateMessage payload)
    returns MessageResponsePayload|Error {
        string resourcePath = string `/${self.apiVersion}/${phoneNumberId}/messages`;
        MessageResponsePayload|error response = self.clientEp->post(resourcePath, payload);
        if response is error {
            return error ClientError("Failed to send the template message", response);
        }
        return response;
    }

    # Uploads a file as a reusable media object.
    #
    # + phoneNumberId - The business phone number ID the media is uploaded against
    # + payload - The file to upload
    # + return - The uploaded media's ID, or a `business:Error` (specifically a
    #            `business:ClientError`)
    remote isolated function uploadMedia(string phoneNumberId, MediaUploadRequest payload)
    returns MediaUploadResponse|Error {
        string resourcePath = string `/${self.apiVersion}/${phoneNumberId}/media`;
        mime:Entity messagingProductPart = new;
        messagingProductPart.setContentDisposition(
                mime:getContentDispositionObject("form-data; name=\"messaging_product\""));
        messagingProductPart.setText(MESSAGING_PRODUCT_WHATSAPP);

        mime:Entity filePart = new;
        filePart.setContentDisposition(mime:getContentDispositionObject(
                string `form-data; name="file"; filename="${payload.fileName}"`));
        filePart.setByteArray(payload.fileContent, contentType = payload.mimeType);

        http:Request request = new;
        request.setBodyParts([messagingProductPart, filePart], contentType = mime:MULTIPART_FORM_DATA);
        MediaUploadResponse|error response = self.clientEp->post(resourcePath, request);
        if response is error {
            return error ClientError("Failed to upload the media", response);
        }
        return response;
    }

    # Retrieves a media object's metadata and a short-lived download URL.
    #
    # + mediaId - The media object's ID
    # + return - The media's metadata and download URL, or a `business:Error` (specifically a
    #            `business:ClientError`)
    remote isolated function retrieveMediaUrl(string mediaId) returns MediaUrlResponse|Error {
        string resourcePath = string `/${self.apiVersion}/${mediaId}`;
        MediaUrlResponse|error response = self.clientEp->get(resourcePath);
        if response is error {
            return error ClientError("Failed to retrieve the media URL", response);
        }
        return response;
    }

    # Downloads a media object's bytes. Fetches the metadata (via `retrieveMediaUrl`) and then the
    # signed download URL it returns, since the URL alone is short-lived and Meta still requires
    # bearer-token authentication to fetch it.
    #
    # If you've already called `retrieveMediaUrl` yourself (e.g. to inspect the media's MIME type
    # or size before deciding whether to download it), call `downloadMediaFromUrl` with its `url`
    # field instead — this avoids the redundant `retrieveMediaUrl` call this function makes
    # internally.
    #
    # + mediaId - The media object's ID
    # + return - The media's raw bytes, or a `business:Error` (specifically a `business:ClientError`)
    remote isolated function downloadMedia(string mediaId) returns byte[]|Error {
        MediaUrlResponse mediaUrl = check self->retrieveMediaUrl(mediaId);
        return self->downloadMediaFromUrl(mediaUrl.url);
    }

    # Downloads a media object's bytes from its signed download URL (a `MediaUrlResponse.url`, as
    # returned by `retrieveMediaUrl`), without re-fetching the media's metadata. Use this when you
    # already have the URL — e.g. after calling `retrieveMediaUrl` yourself — to avoid the
    # redundant metadata call `downloadMedia` makes internally.
    #
    # + url - The signed download URL from a `MediaUrlResponse.url`
    # + return - The media's raw bytes, or a `business:Error` (specifically a `business:ClientError`)
    remote isolated function downloadMediaFromUrl(string url) returns byte[]|Error {
        http:Client|error mediaClientEp = new (url, {auth: {token: self.accessToken}});
        if mediaClientEp is error {
            return error ClientError("Failed to initialize the media download client", mediaClientEp);
        }
        http:Response|error response = mediaClientEp->get("");
        if response is error {
            return error ClientError("Failed to download the media", response);
        }
        byte[]|error bytes = response.getBinaryPayload();
        if bytes is error {
            return error ClientError("Failed to read the downloaded media's bytes", bytes);
        }
        return bytes;
    }

    # Deletes a media object.
    #
    # + mediaId - The media object's ID
    # + return - The delete result, or a `business:Error` (specifically a `business:ClientError`)
    remote isolated function deleteMedia(string mediaId) returns MediaDeleteResponse|Error {
        string resourcePath = string `/${self.apiVersion}/${mediaId}`;
        MediaDeleteResponse|error response = self.clientEp->delete(resourcePath);
        if response is error {
            return error ClientError("Failed to delete the media", response);
        }
        return response;
    }
}
