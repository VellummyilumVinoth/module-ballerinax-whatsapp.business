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

import ballerina/log;
import ballerinax/whatsapp.business as whatsapp;

// Provide these in Config.toml
configurable string accessToken = ?;
configurable string phoneNumberId = ?;
configurable string recipientNumber = ?;
configurable string verifyToken = ?;
configurable string appSecret = ?;

final whatsapp:Client whatsappClient = check new ({auth: {token: accessToken}});

// 1. Send a text message.
public function main() returns error? {
    whatsapp:TextMessage message = {
        to: recipientNumber,
        text: {body: "Hello! This is a test message sent via the Ballerina connector."}
    };

    whatsapp:MessageResponsePayload response = check whatsappClient->sendMessage(phoneNumberId, message);

    var sentMessages = response?.messages;
    if sentMessages is () || sentMessages.length() == 0 {
        log:printInfo(string `Message sent to ${recipientNumber} (no message ID returned).`);
    } else {
        log:printInfo(string `Message sent. Message ID: ${sentMessages[0].id}`);
    }
}

// 2. Receive all ten webhook event types over the listener.
listener whatsapp:Listener whatsappListener = new (8090, verifyToken = verifyToken, appSecret = appSecret);

service whatsapp:WhatsAppService on whatsappListener {
    isolated remote function onMessages(whatsapp:MessagesNotificationEvent event) returns error? {
        if event is whatsapp:MessagesEvent {
            foreach whatsapp:InboundMessage message in event.messages {
                log:printInfo(string `Message from ${message.'from}: ${message.text ?: "(non-text message)"}`);
            }
        } else {
            foreach whatsapp:MessageStatusUpdate status in event.statuses {
                log:printInfo(string `Message ${status.messageId} is now ${status.status}`);
            }
        }
    }

    isolated remote function onAccountReviewUpdate(whatsapp:AccountReviewUpdateEvent event) returns error? {
        log:printInfo(string `WABA ${event.wabaId} review decision: ${event.decision}`);
    }

    isolated remote function onAccountUpdate(whatsapp:AccountUpdateEvent event) returns error? {
        log:printInfo(string `WABA ${event.wabaId} account update: ${event.event}`);
    }

    isolated remote function onBusinessCapabilityUpdate(whatsapp:BusinessCapabilityUpdateEvent event)
    returns error? {
        log:printInfo(string `WABA ${event.wabaId} capability update`);
    }

    isolated remote function onMessageTemplateQualityUpdate(whatsapp:MessageTemplateQualityUpdateEvent event)
    returns error? {
        log:printInfo(string `Template ${event.messageTemplateName} quality: ` +
                string `${event.previousQualityScore} -> ${event.newQualityScore}`);
    }

    isolated remote function onMessageTemplateStatusUpdate(whatsapp:MessageTemplateStatusUpdateEvent event)
    returns error? {
        log:printInfo(string `Template ${event.messageTemplateName} status: ${event.event}`);
    }

    isolated remote function onPhoneNumberNameUpdate(whatsapp:PhoneNumberNameUpdateEvent event) returns error? {
        log:printInfo(string `Phone number ${event.displayPhoneNumber} name decision: ${event.decision}`);
    }

    isolated remote function onPhoneNumberQualityUpdate(whatsapp:PhoneNumberQualityUpdateEvent event)
    returns error? {
        log:printInfo(string `Phone number ${event.displayPhoneNumber} quality update: ${event.event}`);
    }

    isolated remote function onSecurity(whatsapp:SecurityEvent event) returns error? {
        log:printInfo(string `Security event on ${event.displayPhoneNumber}: ${event.event}`);
    }

    isolated remote function onTemplateCategoryUpdate(whatsapp:TemplateCategoryUpdateEvent event) returns error? {
        log:printInfo(string `Template ${event.messageTemplateName} category update: ${event.newCategory}`);
    }
}
