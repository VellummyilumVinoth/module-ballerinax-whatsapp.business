# WhatsApp Business Cloud — setup guide

Follow these steps to obtain the credentials needed by the connector and listener.

## 1. Create a Meta app

1. Go to [Meta for Developers](https://developers.facebook.com/) and create a new app of type
   **Business**.
2. Add the **WhatsApp** product to the app.

## 2. Get the messaging credentials (client)

From **WhatsApp → API Setup**:

- **Phone number ID** — the test or production business phone number ID.
- **Access token** — a temporary token is shown for testing. For production, create a
  **System User** in Meta Business Settings and generate a permanent token with the
  `whatsapp_business_messaging` and `whatsapp_business_management` permissions.

Use this as the `token` in `whatsapp:ConnectionConfig.auth` — the client attaches it to every
request automatically.

## 3. Configure webhooks (listener)

From **WhatsApp → Configuration → Webhooks**:

1. Set the **Callback URL** to your listener's public URL (e.g. via a tunnel during development).
2. Set a **Verify token** — this must match the `verifyToken` you pass to `whatsapp:Listener`.
3. Subscribe to the fields you want notifications for. Each maps 1:1 to one `WhatsAppService`
   handler: `messages` (`onMessages` — inbound messages and status updates both arrive here, as
   two mutually exclusive payload shapes; narrow the `MessagesNotificationEvent` parameter with
   `event is MessagesEvent`), `account_review_update` (`onAccountReviewUpdate`),
   `account_update` (`onAccountUpdate`), `business_capability_update`
   (`onBusinessCapabilityUpdate`), `message_template_quality_update`
   (`onMessageTemplateQualityUpdate`), `message_template_status_update`
   (`onMessageTemplateStatusUpdate`), `phone_number_name_update` (`onPhoneNumberNameUpdate`),
   `phone_number_quality_update` (`onPhoneNumberQualityUpdate`), `security` (`onSecurity`),
   `template_category_update` (`onTemplateCategoryUpdate`). A field outside this set is logged and
   dropped.
4. Copy the app's **App secret** (App Settings → Basic) and pass it as the listener's `appSecret`
   so inbound notifications are authenticated via `X-Hub-Signature-256`.

Both `verifyToken` and `appSecret` are required fields on `whatsapp:Listener` — there is no way to
start it without them.

Meta will call your callback URL with a `GET` handshake (echoing `hub.challenge`) when you save the
configuration, then deliver notifications via `POST`.
