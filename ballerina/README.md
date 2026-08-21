## Overview

[WhatsApp Business Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) is Meta's hosted API for sending and receiving WhatsApp messages, managing business phone numbers, message templates, and more, over the Meta Graph API.

The `ballerinax/whatsapp.business` package provides both:

- A **client** (`business:Client`) for sending text/media/location/contacts messages and message templates, and for uploading, retrieving, and deleting media.
- A webhook **listener** (`business:Listener`) for all ten WhatsApp Business Cloud webhook event types (inbound messages and status updates, account/template/phone-number lifecycle changes, and security events), with built-in `X-Hub-Signature-256` (HMAC-SHA256) verification.

The client and listener are based on [Meta's Cloud API reference](https://developers.facebook.com/docs/whatsapp/cloud-api) and validated against Meta's official `whatsapp-business-nodejs-sdk` definitions.

## Setup guide

### Step 1: Create a Meta app

1. Go to [Meta for Developers](https://developers.facebook.com/) and create a new app of type **Business**.
2. Add the **WhatsApp** product to the app.

### Step 2: Get the messaging credentials (client)

From **WhatsApp → API Setup**:

- **Phone number ID** — the test or production business phone number ID.
- **Access token** — a temporary token is shown for testing. For production, create a **System User** in Meta Business Settings and generate a permanent token with the `whatsapp_business_messaging` and `whatsapp_business_management` permissions.

Use this as the `token` in `business:ConnectionConfig.auth` — the client attaches it to every request automatically.

### Step 3: Configure webhooks (listener)

From **WhatsApp → Configuration → Webhooks**:

1. Set the **Callback URL** to your listener's public URL (e.g. via a tunnel during development).
2. Set a **Verify token** — this must match the `verifyToken` you pass to `business:Listener`.
3. Subscribe to the fields you want notifications for. Each maps 1:1 to one `WhatsAppService` handler: `messages` (`onMessages` — inbound messages and status updates both arrive here, as two mutually exclusive payload shapes; narrow the `MessagesNotification` parameter with `notification is Messages`), `account_review_update` (`onAccountReviewUpdate`), `account_update` (`onAccountUpdate`), `business_capability_update` (`onBusinessCapabilityUpdate`), `message_template_quality_update` (`onMessageTemplateQualityUpdate`), `message_template_status_update` (`onMessageTemplateStatusUpdate`), `phone_number_name_update` (`onPhoneNumberNameUpdate`), `phone_number_quality_update` (`onPhoneNumberQualityUpdate`), `security` (`onSecurity`), `template_category_update` (`onTemplateCategoryUpdate`). A field outside this set is logged and dropped.
4. Copy the app's **App secret** (App Settings → Basic) and pass it as the listener's `appSecret` so inbound notifications are authenticated via `X-Hub-Signature-256`.

Both `verifyToken` and `appSecret` are required fields on `business:Listener` — there is no way to start it without them.

Meta will call your callback URL with a `GET` handshake (echoing `hub.challenge`) when you save the configuration, then deliver notifications via `POST`.

## Quickstart

The connector has two independent entry points — a **client** for calling the Cloud API and a **listener** for handling webhook events. Follow the track that matches your use case.

### Client

Use this if your app only needs to send messages/templates or manage media (no event handling).

#### Step 1: Import the module

```ballerina
import ballerina/io;
import ballerinax/whatsapp.business as business;
```

#### Step 2: Initialize a WhatsApp client

```ballerina
configurable string accessToken = ?;
configurable string phoneNumberId = ?;

business:Client whatsappClient = check new ({auth: {token: accessToken}});
```

#### Step 3: Invoke connector operations

```ballerina
business:TextMessage message = {
    to: "1XXXXXXXXXX",
    text: {body: "Hello from Ballerina!"}
};

business:MessageResponsePayload response = check whatsappClient->sendMessage(phoneNumberId, message);
io:println(response);
```

Send a template, or upload/retrieve/delete media the same way:

```ballerina
business:MessageResponsePayload templateResponse = check whatsappClient->sendTemplateMessage(
    phoneNumberId, {to: "1XXXXXXXXXX", template: {name: "hello_world", language: {code: "en_US"}}});

business:MediaUploadResponse uploaded = check whatsappClient->uploadMedia(phoneNumberId, {
    fileContent: check io:fileReadBytes("image.jpg"), fileName: "image.jpg", mimeType: "image/jpeg"
});
byte[] mediaBytes = check whatsappClient->downloadMedia(uploaded.id);
business:MediaDeleteResponse deleted = check whatsappClient->deleteMedia(uploaded.id);
```

#### Step 4: Run the Ballerina application

```bash
bal run
```

### Listener

Use this if your app needs to handle inbound messages, status updates, or other webhook events from WhatsApp Business Cloud.

#### Step 1: Import the module

```ballerina
import ballerinax/whatsapp.business as business;
```

#### Step 2: Initialize a WhatsApp listener

```ballerina
configurable string verifyToken = ?;
configurable string appSecret = ?;

listener business:Listener whatsappListener = new (8090, verifyToken = verifyToken, appSecret = appSecret);
```

#### Step 3: Implement the service

`business:WhatsAppService` has ten webhook-field handlers, one per WhatsApp Business Cloud webhook field, plus an eleventh optional `onError` handler — but unlike most Ballerina service types, none of them are required. Declare only the ones you care about; a field whose handler you did not declare (or a field outside this closed set) is logged and dropped rather than delivered anywhere. `onError(business:HandlerError handlerError) returns error?` doesn't correspond to a webhook field — it's invoked whenever one of the ten handlers above returns an `error` while being dispatched, and is the only way to react to a handler failure beyond logging. A compiler plugin validates every handler you do declare: its name must be one of these eleven, its parameter must match the documented event type, and it must return `error?`.

```ballerina
service business:WhatsAppService on whatsappListener {
    remote function onMessages(business:MessagesNotification notification) returns error? {
        if notification is business:Messages {
            // handle inbound messages: notification.messages
        } else {
            // handle status updates: notification.statuses
        }
    }
    remote function onSecurity(business:Security security) returns error? {
        // handle a PIN change/reset event
    }
}
```

See `examples/send-message` for a reference implementation of all eleven handlers.

By default, the listener acknowledges (`200 OK`) each notification automatically, before any handler runs — Meta requires a fast `2xx` and retries otherwise, so this is the safe default for slow handlers. If you'd rather decide exactly when a notification is acknowledged (e.g. only after some work has durably succeeded), annotate the service `@business:ServiceConfig { autoAck: false }` and declare a handler's optional second parameter as a `business:Caller`:

```ballerina
listener business:Listener whatsappListener = new (
    8090, verifyToken = verifyToken, appSecret = appSecret);

@business:ServiceConfig {
    autoAck: false
}
service business:WhatsAppService on whatsappListener {
    remote function onMessages(business:MessagesNotification notification, business:Caller caller) returns error? {
        check persistNotification(notification);
        check caller->complete();
    }
}
```

If a handler declared with a `Caller` never calls `caller->complete()`, the listener never sends its own `200 OK` for that request — the underlying HTTP service falls back to a default `500`, a non-`2xx` that Meta's own retry behavior treats the same as any other failed delivery. This connector adds no ack-tracking or retry logic of its own beyond that.

Meta may redeliver a notification if the acknowledgement is slow, dropped, or never sent — under either `autoAck` setting, not just `false`. Make handler processing idempotent, or deduplicate using a scoped key: `InboundMessage.messageId` (`wamid`) alone for messages, but `MessageStatusUpdate.messageId` needs `status` alongside it, since one message's several status updates share the same `messageId`. The entry-level `timestamp` on `Messages`/`MessageStatuses` is shared across a whole batch, so it is not a valid key by itself.

`onError` may also declare an optional second `Caller` parameter. It's the same `Caller` instance passed to the handler whose failure triggered `onError` — so `caller->complete()` there acknowledges that *original* notification, letting you still send a `200 OK` even though the handler that was supposed to acknowledge it failed before doing so.

#### Step 4: Run the Ballerina application

```bash
bal run
```

Point your Meta app's webhook callback URL at the listener (via a public tunnel during development) to start receiving events.

## Examples

The `whatsapp.business` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/tree/main/examples).

1. [Send a WhatsApp message](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/tree/main/examples/send-message) — send a text message and receive replies/status updates over a webhook listener.
