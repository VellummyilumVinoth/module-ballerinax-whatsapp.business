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
import ballerinax/whatsapp.business as business;

// Provide these in Config.toml
configurable string accessToken = ?;
configurable string phoneNumberId = ?;
configurable string recipientNumber = ?;
configurable string verifyToken = ?;
configurable string appSecret = ?;

final business:Client whatsappClient = check new ({auth: {token: accessToken}});

// Masks all but the last 4 digits of a phone number/ID for safe logging.
function mask(string value) returns string {
    int length = value.length();
    if length <= 4 {
        return value;
    }
    string stars = "";
    foreach int i in 0 ..< (length - 4) {
        stars += "*";
    }
    return stars + value.substring(length - 4);
}

// 1. Send a text message.
public function main() returns error? {
    business:TextMessage message = {
        to: recipientNumber,
        text: {body: "Hello! This is a test message sent via the Ballerina connector."}
    };

    business:MessageResponsePayload response = check whatsappClient->sendMessage(phoneNumberId, message);

    business:SentMessage[]? sentMessages = response?.messages;
    if sentMessages is () || sentMessages.length() == 0 {
        log:printInfo(string `Message sent to ${mask(recipientNumber)} (no message ID returned).`);
    } else {
        log:printInfo(string `Message sent. Message ID: ${sentMessages[0].id}`);
    }
}

// 2. Receive all ten webhook event types over the listener.
listener business:Listener whatsappListener = new (8090, verifyToken = verifyToken, appSecret = appSecret);

service business:WhatsAppService on whatsappListener {
    remote function onMessages(business:MessagesNotification notification) returns error? {
        if notification is business:Messages {
            foreach business:InboundMessage message in notification.messages {
                log:printInfo(string `Message from ${mask(message.'from)}: ${message.text ?: "(non-text message)"}`);
            }
        } else {
            foreach business:MessageStatusUpdate status in notification.statuses {
                log:printInfo(string `Message ${status.messageId} is now ${status.status}`);
            }
        }
    }

    remote function onAccountReviewUpdate(business:AccountReviewUpdate update) returns error? {
        log:printInfo(string `WABA ${mask(update.wabaId)} review decision: ${update.decision}`);
    }

    remote function onAccountUpdate(business:AccountUpdate update) returns error? {
        log:printInfo(string `WABA ${mask(update.wabaId)} account update: ${update.event}`);
    }

    remote function onBusinessCapabilityUpdate(business:BusinessCapabilityUpdate update)
    returns error? {
        log:printInfo(string `WABA ${mask(update.wabaId)} capability update`);
    }

    remote function onMessageTemplateQualityUpdate(business:MessageTemplateQualityUpdate update)
    returns error? {
        log:printInfo(string `Template ${update.messageTemplateName} quality: ` +
                string `${update.previousQualityScore} -> ${update.newQualityScore}`);
    }

    remote function onMessageTemplateStatusUpdate(business:MessageTemplateStatusUpdate update)
    returns error? {
        log:printInfo(string `Template ${update.messageTemplateName} status: ${update.event}`);
    }

    remote function onPhoneNumberNameUpdate(business:PhoneNumberNameUpdate update) returns error? {
        log:printInfo(string `Phone number ${mask(update.displayPhoneNumber)} name decision: ${update.decision}`);
    }

    remote function onPhoneNumberQualityUpdate(business:PhoneNumberQualityUpdate update)
    returns error? {
        log:printInfo(string `Phone number ${mask(update.displayPhoneNumber)} quality update: ${update.event}`);
    }

    remote function onSecurity(business:Security security) returns error? {
        log:printInfo(string `Security event on ${mask(security.displayPhoneNumber)}: ${security.event}`);
    }

    remote function onTemplateCategoryUpdate(business:TemplateCategoryUpdate update) returns error? {
        log:printInfo(string `Template ${update.messageTemplateName} category update: ${update.newCategory}`);
    }
}
