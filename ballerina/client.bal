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
    # + return - An error if initialization failed, otherwise `()`
    public isolated function init(ConnectionConfig config, string serviceUrl = DEFAULT_BASE_URL)
    returns error? {
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
        self.clientEp = check new (serviceUrl, httpClientConfig);
        self.apiVersion = config.apiVersion;
        self.accessToken = config.auth.token;
    }

    # Sends a text, image, audio, video, document, location, or contacts message.
    #
    # + phoneNumberId - The business phone number ID sending the message
    # + payload - The message to send
    # + return - The send result, or an error
    remote isolated function sendMessage(string phoneNumberId, Message payload) returns MessageResponsePayload|error {  
        string resourcePath = string `/${self.apiVersion}/${phoneNumberId}/messages`;
        return self.clientEp->post(resourcePath, payload);
    }

    # Sends a pre-approved message template. Required to start a conversation, or to message a
    # recipient outside the 24-hour customer service window.
    #
    # + phoneNumberId - The business phone number ID sending the message
    # + payload - The template message to send
    # + return - The send result, or an error
    remote isolated function sendTemplateMessage(string phoneNumberId, TemplateMessage payload)
    returns MessageResponsePayload|error {
        string resourcePath = string `/${self.apiVersion}/${phoneNumberId}/messages`;
        return self.clientEp->post(resourcePath, payload);
    }

    # Uploads a file as a reusable media object.
    #
    # + phoneNumberId - The business phone number ID the media is uploaded against
    # + payload - The file to upload
    # + return - The uploaded media's ID, or an error
    remote isolated function uploadMedia(string phoneNumberId, MediaUploadRequest payload)
    returns MediaUploadResponse|error {
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
        return self.clientEp->post(resourcePath, request);
    }

    # Retrieves a media object's metadata and a short-lived download URL.
    #
    # + mediaId - The media object's ID
    # + return - The media's metadata and download URL, or an error
    remote isolated function retrieveMediaUrl(string mediaId) returns MediaUrlResponse|error {
        string resourcePath = string `/${self.apiVersion}/${mediaId}`;
        return self.clientEp->get(resourcePath);
    }

    # Downloads a media object's bytes. Fetches the metadata (via `retrieveMediaUrl`) and then the
    # signed download URL it returns, since the URL alone is short-lived and Meta still requires
    # bearer-token authentication to fetch it.
    #
    # + mediaId - The media object's ID
    # + return - The media's raw bytes, or an error
    remote isolated function downloadMedia(string mediaId) returns byte[]|error {
        MediaUrlResponse mediaUrl = check self->retrieveMediaUrl(mediaId);
        http:Client mediaClientEp = check new (mediaUrl.url, {auth: {token: self.accessToken}});
        http:Response response = check mediaClientEp->get("");
        return response.getBinaryPayload();
    }

    # Deletes a media object.
    #
    # + mediaId - The media object's ID
    # + return - The delete result, or an error
    remote isolated function deleteMedia(string mediaId) returns MediaDeleteResponse|error {
        string resourcePath = string `/${self.apiVersion}/${mediaId}`;
        return self.clientEp->delete(resourcePath);
    }
}
