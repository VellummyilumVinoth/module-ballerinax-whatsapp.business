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
import ballerina/lang.runtime;
import ballerina/test;
import ballerina/time;

// The webhook handler acks before dispatching (see `dispatch_service.bal`), so a handler's
// side effect is not guaranteed to be visible the instant the HTTP response returns. Polls
// `predicate` until it holds or `timeoutSeconds` (wall-clock, not just cumulative sleep time)
// elapses, to avoid asserting on that race.
isolated function waitUntil(isolated function () returns boolean predicate, decimal timeoutSeconds = 5)
        returns error? {
    decimal interval = 0.05;
    decimal deadline = time:monotonicNow() + timeoutSeconds;
    while !predicate() {
        if time:monotonicNow() >= deadline {
            return error(string `Condition not met within ${timeoutSeconds}s`);
        }
        runtime:sleep(interval);
    }
}

// A service declaring none of the ten (all-optional) handlers, so a `Listener` can be attached
// and started in handshake tests without caring about any particular event.
isolated service class MockWhatsAppService {
    *WhatsAppService;
}

isolated int messagesReceived = 0;

// Declares only the one handler it cares about, to verify the dispatcher correctly invokes a
// declared handler and silently skips every handler this service does not declare.
isolated service class MessagesOnlyWhatsAppService {
    *WhatsAppService;
    remote function onMessages(MessagesNotification notification) returns error? {
        lock {
            messagesReceived += 1;
        }
    }
}

isolated int onErrorInvocations = 0;
isolated string onErrorLastField = "";

// Declares a failing `onSecurity` handler alongside `onError`, to verify `onError` is invoked with
// the failing handler's field/payload when the failing handler returns an error.
isolated service class FailingHandlerWhatsAppService {
    *WhatsAppService;
    remote function onSecurity(Security security) returns error? {
        return error("boom");
    }
    remote function onError(HandlerError handlerError) returns error? {
        lock {
            onErrorInvocations += 1;
        }
        lock {
            onErrorLastField = handlerError.'field;
        }
    }
}

const TEST_PORT = 18191;
const DISPATCH_TEST_PORT = 18192;
const ON_ERROR_TEST_PORT = 18193;
const MANUAL_ACK_TEST_PORT = 18194;
const NEVER_ACK_TEST_PORT = 18195;
const AUTO_ACK_NO_OP_TEST_PORT = 18196;

// The subscription handshake echoes the challenge only for a matching verify token and rejects a
// mismatch.
@test:Config {}
function testHandshakeWithVerifyToken() returns error? {
    Listener whatsappListener = check new (TEST_PORT, verifyToken = "secret-token", appSecret = "my-app-secret");
    check whatsappListener.attach(new MockWhatsAppService());
    check whatsappListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${TEST_PORT}`);

    http:Ok ok = check callerClient->get(
        "/?hub.mode=subscribe&hub.verify_token=secret-token&hub.challenge=challenge-1");
    test:assertEquals(ok?.body, "challenge-1", "challenge should be echoed");

    http:Forbidden forbidden = check callerClient->get(
        "/?hub.mode=subscribe&hub.verify_token=wrong-token&hub.challenge=challenge-1");
    test:assertEquals(forbidden?.body, ERR_WEBHOOK_VERIFICATION_FAILED, "a wrong token should be forbidden");

    check whatsappListener.immediateStop();
}

// Verifies the HMAC-SHA256 webhook signature verification end-to-end.
@test:Config {}
function testValidWebhookSignature() returns error? {
    string payload = {"object": "whatsapp_business_account", "entry": []}.toJsonString();
    string secret = "my-app-secret";
    byte[] hmac = check crypto:hmacSha256(payload.toBytes(), secret.toBytes());
    string signature = "sha256=" + hmac.toBase16().toLowerAscii();

    boolean valid = check verifyWebhookSignature(payload, signature, secret);
    test:assertTrue(valid, "a correctly signed payload should verify");
}

@test:Config {}
function testTamperedWebhookSignature() returns error? {
    string payload = {"object": "whatsapp_business_account"}.toJsonString();
    string secret = "my-app-secret";

    boolean valid = check verifyWebhookSignature(payload, "sha256=deadbeef", secret);
    test:assertFalse(valid, "a tampered signature should not verify");
}

@test:Config {}
function testWrongSecretWebhookSignature() returns error? {
    string payload = {"object": "whatsapp_business_account"}.toJsonString();
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

// Verifies a service that declares only `onMessages` still receives `messages` notifications, and
// that other webhook fields are dropped silently (no error) since no handler is declared for them.
@test:Config {}
function testDispatchInvokesOnlyDeclaredHandler() returns error? {
    string secret = "my-app-secret";
    Listener whatsappListener = check new (DISPATCH_TEST_PORT, verifyToken = "secret-token", appSecret = secret);
    check whatsappListener.attach(new MessagesOnlyWhatsAppService());
    check whatsappListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${DISPATCH_TEST_PORT}`);

    string messagesPayload = {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "waba-1",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messaging_product": "whatsapp",
                            "metadata": {"phone_number_id": "123"},
                            "messages": [
                                {"from": "111", "id": "wamid.1", "type": "text", "text": {"body": "hi"}}
                            ]
                        }
                    }
                ]
            }
        ]
    }.toJsonString();
    byte[] messagesHmac = check crypto:hmacSha256(messagesPayload.toBytes(), secret.toBytes());
    // A valid signed payload is accepted; binding to `http:Ok` itself asserts the 200 status.
    http:Ok _ = check callerClient->post("/", messagesPayload,
            headers = {[WEBHOOK_SIGNATURE_HEADER]: "sha256=" + messagesHmac.toBase16().toLowerAscii()});

    string securityPayload = {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "waba-1",
                "changes": [
                    {
                        "field": "security",
                        "value": {"display_phone_number": "111", "event": "PIN_CHANGED"}
                    }
                ]
            }
        ]
    }.toJsonString();
    byte[] securityHmac = check crypto:hmacSha256(securityPayload.toBytes(), secret.toBytes());
    // A field with no declared handler is still accepted (not delivered anywhere); binding to
    // `http:Ok` itself asserts the 200 status.
    http:Ok _ = check callerClient->post("/", securityPayload,
            headers = {[WEBHOOK_SIGNATURE_HEADER]: "sha256=" + securityHmac.toBase16().toLowerAscii()});

    check waitUntil(isolated function() returns boolean {
        lock {
            return messagesReceived >= 1;
        }
    });
    lock {
        test:assertEquals(messagesReceived, 1, "onMessages should have been invoked exactly once");
    }

    check whatsappListener.immediateStop();
}

// Verifies `onError` is invoked with the failing handler's field/payload when a handler returns an
// error, and that the ack to Meta still succeeds (dispatch failures never affect the response).
@test:Config {}
function testOnErrorInvokedWhenHandlerFails() returns error? {
    string secret = "my-app-secret";
    Listener whatsappListener = check new (ON_ERROR_TEST_PORT, verifyToken = "secret-token", appSecret = secret);
    check whatsappListener.attach(new FailingHandlerWhatsAppService());
    check whatsappListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${ON_ERROR_TEST_PORT}`);

    string securityPayload = {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "waba-1",
                "changes": [
                    {
                        "field": "security",
                        "value": {"display_phone_number": "111", "event": "PIN_CHANGED"}
                    }
                ]
            }
        ]
    }.toJsonString();
    byte[] securityHmac = check crypto:hmacSha256(securityPayload.toBytes(), secret.toBytes());
    // The failing onSecurity handler must not affect the ack; binding to `http:Ok` itself asserts
    // the 200 status.
    http:Ok _ = check callerClient->post("/", securityPayload,
            headers = {[WEBHOOK_SIGNATURE_HEADER]: "sha256=" + securityHmac.toBase16().toLowerAscii()});

    check waitUntil(isolated function() returns boolean {
        lock {
            return onErrorInvocations >= 1;
        }
    });
    lock {
        test:assertEquals(onErrorInvocations, 1, "onError should have been invoked exactly once");
    }
    lock {
        test:assertEquals(onErrorLastField, "security", "onError should report the failing handler's field");
    }

    check whatsappListener.immediateStop();
}

// ── Manual Acknowledgement ────────────────────────────────────────────────────────

// A service whose `onMessages` declares the optional `Caller` parameter and acknowledges via it.
@ServiceConfig {
    autoAck: false
}
isolated service class ManualAckWhatsAppService {
    *WhatsAppService;
    private int messagesReceived = 0;

    remote function onMessages(MessagesNotification notification, Caller caller) returns error? {
        lock {
            self.messagesReceived += 1;
        }
        check caller->complete();
    }

    isolated function getMessagesReceived() returns int {
        lock {
            return self.messagesReceived;
        }
    }
}

// A service whose `onMessages` declares the `Caller` parameter but never calls `complete()`.
@ServiceConfig {
    autoAck: false
}
isolated service class NeverAckingWhatsAppService {
    *WhatsAppService;
    remote function onMessages(MessagesNotification notification, Caller caller) returns error? {
    }
}

// A service identical to `ManualAckWhatsAppService` but with no `ServiceConfig` annotation, so it
// defaults to `autoAck: true`.
isolated service class AutoAckWhatsAppService {
    *WhatsAppService;
    private int messagesReceived = 0;

    remote function onMessages(MessagesNotification notification, Caller caller) returns error? {
        lock {
            self.messagesReceived += 1;
        }
        check caller->complete();
    }

    isolated function getMessagesReceived() returns int {
        lock {
            return self.messagesReceived;
        }
    }
}

function messagesPayload(string secret) returns [string, string]|error {
    string payload = {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "waba-1",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messaging_product": "whatsapp",
                            "metadata": {"phone_number_id": "123"},
                            "messages": [
                                {"from": "111", "id": "wamid.1", "type": "text", "text": {"body": "hi"}}
                            ]
                        }
                    }
                ]
            }
        ]
    }.toJsonString();
    byte[] hmac = check crypto:hmacSha256(payload.toBytes(), secret.toBytes());
    return [payload, "sha256=" + hmac.toBase16().toLowerAscii()];
}

// With a service annotated `ServiceConfig {autoAck: false}`, a handler that calls
// `caller->complete()` gets its `200 OK` — proving the listener itself no longer responds
// unconditionally before dispatch.
@test:Config {}
function testManualAckRespondsWhenHandlerCompletes() returns error? {
    string secret = "my-app-secret";
    Listener whatsappListener = check new (MANUAL_ACK_TEST_PORT, verifyToken = "secret-token", appSecret = secret);
    ManualAckWhatsAppService mockService = new;
    check whatsappListener.attach(mockService);
    check whatsappListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${MANUAL_ACK_TEST_PORT}`);
    [string, string] [payload, signature] = check messagesPayload(secret);
    http:Ok _ = check callerClient->post("/", payload, headers = {[WEBHOOK_SIGNATURE_HEADER]: signature});

    int retries = 0;
    while mockService.getMessagesReceived() == 0 && retries < 20 {
        runtime:sleep(0.05);
        retries += 1;
    }
    test:assertEquals(mockService.getMessagesReceived(), 1, "onMessages should have been invoked exactly once");

    check whatsappListener.immediateStop();
}

// With a service annotated `ServiceConfig {autoAck: false}`, a handler that never calls
// `caller->complete()` never sends the `200 OK` acknowledgement itself — the underlying
// `http:Service` sends its own default `500` once the resource function returns having never
// responded. That's still a non-`2xx`, so it still leads to the same outcome documented on
// `Caller`: Meta's own retry-then-give-up behavior takes over.
@test:Config {}
function testManualAckNeverRespondsWhenHandlerDoesNotComplete() returns error? {
    string secret = "my-app-secret";
    Listener whatsappListener = check new (NEVER_ACK_TEST_PORT, verifyToken = "secret-token", appSecret = secret);
    check whatsappListener.attach(new NeverAckingWhatsAppService());
    check whatsappListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${NEVER_ACK_TEST_PORT}`);
    [string, string] [payload, signature] = check messagesPayload(secret);
    http:InternalServerError _ = check callerClient->post("/", payload,
            headers = {[WEBHOOK_SIGNATURE_HEADER]: signature});

    check whatsappListener.immediateStop();
}

// With the default `autoAck: true` (no `ServiceConfig` annotation), the listener still responds
// immediately regardless of whether the handler also declares (and calls) a `Caller` — calling
// `complete()` after the listener already responded is a safe no-op.
@test:Config {}
function testManualAckCompleteIsNoOpWhenAlreadyAutoAcked() returns error? {
    string secret = "my-app-secret";
    Listener whatsappListener = check new (AUTO_ACK_NO_OP_TEST_PORT, verifyToken = "secret-token", appSecret = secret);
    AutoAckWhatsAppService mockService = new;
    check whatsappListener.attach(mockService);
    check whatsappListener.'start();

    http:StatusCodeClient callerClient = check new (string `http://localhost:${AUTO_ACK_NO_OP_TEST_PORT}`);
    [string, string] [payload, signature] = check messagesPayload(secret);
    http:Ok _ = check callerClient->post("/", payload, headers = {[WEBHOOK_SIGNATURE_HEADER]: signature});

    int retries = 0;
    while mockService.getMessagesReceived() == 0 && retries < 20 {
        runtime:sleep(0.05);
        retries += 1;
    }
    test:assertEquals(mockService.getMessagesReceived(), 1,
            "onMessages should have been invoked once, and its caller->complete() call should not error");

    check whatsappListener.immediateStop();
}
