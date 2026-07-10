# Ballerina WhatsApp Business Cloud connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/actions/workflows/ci.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/actions/workflows/build-with-bal-test-graalvm.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/actions/workflows/trivy-scan.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[WhatsApp Business Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) is Meta's hosted API for sending and receiving WhatsApp messages, managing business phone numbers, message templates, and more, over the Meta Graph API.

The `ballerinax/whatsapp.business` package provides both:

- A **client** (`whatsapp:Client`) for sending text/media/location/contacts messages and message templates, and for uploading, retrieving, and deleting media.
- A webhook **listener** (`whatsapp:Listener`) for all ten WhatsApp Business Cloud webhook event types (inbound messages and status updates, account/template/phone-number lifecycle changes, and security events), with built-in `X-Hub-Signature-256` (HMAC-SHA256) verification backed by a native Java module.

The client and listener are hand-written directly against [Meta's Cloud API reference](https://developers.facebook.com/docs/whatsapp/cloud-api), cross-checked against Meta's official `whatsapp-business-nodejs-sdk` TypeScript types for field accuracy — not generated from an OpenAPI spec.

## Setup guide

### Step 1: Create a Meta app

1. Go to [Meta for Developers](https://developers.facebook.com/) and create a new app of type **Business**.
2. Add the **WhatsApp** product to the app.

### Step 2: Get the messaging credentials (client)

From **WhatsApp → API Setup**:

- **Phone number ID** — the test or production business phone number ID.
- **Access token** — a temporary token is shown for testing. For production, create a **System User** in Meta Business Settings and generate a permanent token with the `whatsapp_business_messaging` and `whatsapp_business_management` permissions.

Use this as the `token` in `whatsapp:ConnectionConfig.auth` — the client attaches it to every request automatically.

### Step 3: Configure webhooks (listener)

From **WhatsApp → Configuration → Webhooks**:

1. Set the **Callback URL** to your listener's public URL (e.g. via a tunnel during development).
2. Set a **Verify token** — this must match the `verifyToken` you pass to `whatsapp:Listener`.
3. Subscribe to the fields you want notifications for. Each maps 1:1 to one `WhatsAppService` handler: `messages` (`onMessages` — inbound messages and status updates both arrive here, as two mutually exclusive payload shapes; narrow the `MessagesNotificationEvent` parameter with `event is MessagesEvent`), `account_review_update` (`onAccountReviewUpdate`), `account_update` (`onAccountUpdate`), `business_capability_update` (`onBusinessCapabilityUpdate`), `message_template_quality_update` (`onMessageTemplateQualityUpdate`), `message_template_status_update` (`onMessageTemplateStatusUpdate`), `phone_number_name_update` (`onPhoneNumberNameUpdate`), `phone_number_quality_update` (`onPhoneNumberQualityUpdate`), `security` (`onSecurity`), `template_category_update` (`onTemplateCategoryUpdate`). A field outside this set is logged and dropped.
4. Copy the app's **App secret** (App Settings → Basic) and pass it as the listener's `appSecret` so inbound notifications are authenticated via `X-Hub-Signature-256`.

Both `verifyToken` and `appSecret` are required fields on `whatsapp:Listener` — there is no way to start it without them.

Meta will call your callback URL with a `GET` handshake (echoing `hub.challenge`) when you save the configuration, then deliver notifications via `POST`.

## Quickstart

The connector has two independent entry points — a **client** for calling the Cloud API and a **listener** for handling webhook events. Follow the track that matches your use case.

### Client

Use this if your app only needs to send messages/templates or manage media (no event handling).

#### Step 1: Import the module

```ballerina
import ballerina/io;
import ballerinax/whatsapp.business as whatsapp;
```

#### Step 2: Initialize a WhatsApp client

```ballerina
configurable string accessToken = ?;
configurable string phoneNumberId = ?;

whatsapp:Client whatsappClient = check new ({auth: {token: accessToken}});
```

#### Step 3: Invoke connector operations

```ballerina
whatsapp:TextMessage message = {
    to: "1XXXXXXXXXX",
    text: {body: "Hello from Ballerina!"}
};

whatsapp:MessageResponsePayload response = check whatsappClient->sendMessage(phoneNumberId, message);
io:println(response);
```

Send a template, or upload/retrieve/delete media the same way:

```ballerina
whatsapp:MessageResponsePayload templateResponse = check whatsappClient->sendTemplateMessage(
    phoneNumberId, {to: "1XXXXXXXXXX", template: {name: "hello_world", language: {code: "en_US"}}});

whatsapp:MediaUploadResponse uploaded = check whatsappClient->uploadMedia(phoneNumberId, {
    fileContent: check io:fileReadBytes("image.jpg"), fileName: "image.jpg", mimeType: "image/jpeg"
});
byte[] mediaBytes = check whatsappClient->downloadMedia(uploaded.id);
whatsapp:MediaDeleteResponse deleted = check whatsappClient->deleteMedia(uploaded.id);
```

#### Step 4: Run the Ballerina application

```bash
bal run
```

### Listener

Use this if your app needs to handle inbound messages, status updates, or other webhook events from WhatsApp Business Cloud.

#### Step 1: Import the module

```ballerina
import ballerinax/whatsapp.business as whatsapp;
```

#### Step 2: Initialize a WhatsApp listener

```ballerina
listener whatsapp:Listener whatsappListener = new (
    8090, verifyToken = "my-verify-token", appSecret = "my-app-secret");
```

#### Step 3: Implement the service

`whatsapp:WhatsAppService` has exactly ten handlers, one per WhatsApp Business Cloud webhook field. Implement all of them — there is no catch-all, and a field outside this set is logged and dropped.

```ballerina
service whatsapp:WhatsAppService on whatsappListener {
    remote function onMessages(whatsapp:MessagesNotificationEvent event) returns error? {
        if event is whatsapp:MessagesEvent {
            // handle inbound messages: event.messages
        } else {
            // handle status updates: event.statuses
        }
    }
    remote function onSecurity(whatsapp:SecurityEvent event) returns error? {
        // handle a PIN change/reset event
    }
    // ... plus onAccountReviewUpdate, onAccountUpdate, onBusinessCapabilityUpdate,
    // onMessageTemplateQualityUpdate, onMessageTemplateStatusUpdate, onPhoneNumberNameUpdate,
    // onPhoneNumberQualityUpdate, and onTemplateCategoryUpdate. See `examples/send-message` for a
    // service implementing all of them.
}
```

#### Step 4: Run the Ballerina application

```bash
bal run
```

Point your Meta app's webhook callback URL at the listener (via a public tunnel during development) to start receiving events.

## Examples

The `whatsapp.business` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/tree/main/examples).

1. [Send a WhatsApp message](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/tree/main/examples/send-message) — send a text message and receive replies/status updates over a webhook listener.

## Issues and projects

The **Issues** and **Projects** tabs are disabled for this repository as this is part of the Ballerina library. To report bugs, request new features, start new discussions, view project boards, etc., visit the Ballerina library [parent repository](https://github.com/ballerina-platform/ballerina-library).

This repository only contains the source code for the package.

## Build from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

   * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
   * [OpenJDK](https://adoptium.net/)

    > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/) 2201.12.x.

### Build options

Execute the following commands to build from the source:

| Command                      | Purpose                                                       |
|-------------------------------|----------------------------------------------------------------|
| `./gradlew build`            | Build the native module, the Ballerina package, and examples   |
| `./gradlew clean`            | Clean the build artifacts                                      |
| `cd ballerina && bal test`   | Run the package tests (requires the native jar to be built)    |
| `cd ballerina && bal pack`   | Pack the Ballerina package                                     |

> The `ballerina/Ballerina.toml` references the native jar at
> `../native/build/libs/whatsapp.business-native-<version>.jar`. Build the `native` module
> first (`./gradlew :whatsapp.business-native:build`) before running `bal` commands directly.

## Repository structure

| Directory       | Contents                                                             |
|------------------|------------------------------------------------------------------------|
| `ballerina/`    | The Ballerina connector + webhook listener source and tests          |
| `native/`       | The Java native module (webhook HMAC-SHA256 signature verification)  |
| `examples/`     | Runnable usage examples                                               |
| `docs/setup/`   | Credential and webhook setup guide                                    |
| `build-config/` | Build resources (the `Ballerina.toml` version template)              |

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`whatsapp.business` package](https://lib.ballerina.io/ballerinax/whatsapp.business/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
