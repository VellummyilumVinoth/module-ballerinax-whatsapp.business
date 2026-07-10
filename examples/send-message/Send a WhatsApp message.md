# Send a WhatsApp message

This example sends a WhatsApp text message with the connector and receives replies and
delivery/read receipts through the webhook `Listener`.

## Prerequisites

Create a `Config.toml` in this directory:

```toml
accessToken = "<META_ACCESS_TOKEN>"
phoneNumberId = "<PHONE_NUMBER_ID>"
recipientNumber = "<RECIPIENT_MSISDN>"
verifyToken = "<WEBHOOK_VERIFY_TOKEN>"
appSecret = "<META_APP_SECRET>"
# apiVersion = "v23.0"   # optional
```

See [`docs/setup`](../../docs/setup) for how to obtain these values.

## Run the example

```bash
bal run
```

`main` sends one text message. The webhook `Listener` starts on port `8090`; point your Meta app's
webhook callback URL at it (via a public tunnel during development) to receive inbound messages and
status updates. Inbound notifications are authenticated using the `appSecret`
(`X-Hub-Signature-256`).
