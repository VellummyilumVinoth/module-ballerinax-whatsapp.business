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

import ballerina/crypto;
import ballerina/http;
import ballerina/test;

// A no-op service so a `Listener` can be attached and started in handshake tests.
isolated service class MockWhatsAppService {
    *WhatsAppService;
    isolated remote function onMessages(MessagesNotificationEvent event) returns error? {
    }
    isolated remote function onAccountReviewUpdate(AccountReviewUpdateEvent event) returns error? {
    }
    isolated remote function onAccountUpdate(AccountUpdateEvent event) returns error? {
    }
    isolated remote function onBusinessCapabilityUpdate(BusinessCapabilityUpdateEvent event) returns error? {
    }
    isolated remote function onMessageTemplateQualityUpdate(MessageTemplateQualityUpdateEvent event) returns error? {
    }
    isolated remote function onMessageTemplateStatusUpdate(MessageTemplateStatusUpdateEvent event) returns error? {
    }
    isolated remote function onPhoneNumberNameUpdate(PhoneNumberNameUpdateEvent event) returns error? {
    }
    isolated remote function onPhoneNumberQualityUpdate(PhoneNumberQualityUpdateEvent event) returns error? {
    }
    isolated remote function onSecurity(SecurityEvent event) returns error? {
    }
    isolated remote function onTemplateCategoryUpdate(TemplateCategoryUpdateEvent event) returns error? {
    }
}

const int TEST_PORT = 18191;

// The subscription handshake echoes the challenge only for a matching verify token and rejects a
// mismatch.
@test:Config {}
function testHandshakeWithVerifyToken() returns error? {
    Listener whatsappListener = check new (TEST_PORT, verifyToken = "secret-token", appSecret = "my-app-secret");
    check whatsappListener.attach(new MockWhatsAppService());
    check whatsappListener.'start();

    http:Client callerClient = check new (string `http://localhost:${TEST_PORT}`);

    http:Response ok = check callerClient->get(
        "/?hub.mode=subscribe&hub.verify_token=secret-token&hub.challenge=challenge-1");
    test:assertEquals(ok.statusCode, 200, "matching token should return 200");
    test:assertEquals(check ok.getTextPayload(), "challenge-1", "challenge should be echoed");

    http:Response forbidden = check callerClient->get(
        "/?hub.mode=subscribe&hub.verify_token=wrong-token&hub.challenge=challenge-1");
    test:assertEquals(forbidden.statusCode, 403, "a wrong token should be forbidden");

    check whatsappListener.immediateStop();
}

// Verifies the native (Java) HMAC-SHA256 webhook signature binding end-to-end.
@test:Config {}
function testValidWebhookSignature() returns error? {
    string payload = "{\"object\":\"whatsapp_business_account\",\"entry\":[]}";
    string secret = "my-app-secret";
    byte[] hmac = check crypto:hmacSha256(payload.toBytes(), secret.toBytes());
    string signature = "sha256=" + hmac.toBase16().toLowerAscii();

    boolean valid = check verifyWebhookSignature(payload, signature, secret);
    test:assertTrue(valid, "a correctly signed payload should verify");
}

@test:Config {}
function testTamperedWebhookSignature() returns error? {
    string payload = "{\"object\":\"whatsapp_business_account\"}";
    string secret = "my-app-secret";

    boolean valid = check verifyWebhookSignature(payload, "sha256=deadbeef", secret);
    test:assertFalse(valid, "a tampered signature should not verify");
}

@test:Config {}
function testWrongSecretWebhookSignature() returns error? {
    string payload = "{\"object\":\"whatsapp_business_account\"}";
    byte[] hmac = check crypto:hmacSha256(payload.toBytes(), "right-secret".toBytes());
    string signature = "sha256=" + hmac.toBase16().toLowerAscii();

    boolean valid = check verifyWebhookSignature(payload, signature, "wrong-secret");
    test:assertFalse(valid, "signature computed with a different secret should not verify");
}

// Ensures the connector client can be initialized with bearer-token auth.
@test:Config {}
function testClientInitialization() returns error? {
    Client _ = check new ({auth: {token: "test-token"}});
}
