# Change Log

This file contains all the notable changes done to the Ballerina WhatsApp Business Cloud connector
through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Initial release of the WhatsApp Business Cloud connector: a hand-written `Client` covering
  sending messages, templates, and media (upload/retrieve/delete), and a webhook `Listener`.
- `WhatsAppService` has exactly ten handlers, one per WhatsApp Business Cloud webhook field:
  `onMessages` (inbound messages and status updates — Meta delivers these as two mutually
  exclusive shapes under this one field, so there is a single handler taking the
  `MessagesNotificationEvent` union (`MessagesEvent|MessageStatusEvent`), narrowed with
  `event is MessagesEvent`), `onAccountReviewUpdate`, `onAccountUpdate`, `onBusinessCapabilityUpdate`,
  `onMessageTemplateQualityUpdate`, `onMessageTemplateStatusUpdate`, `onPhoneNumberNameUpdate`,
  `onPhoneNumberQualityUpdate`, `onSecurity`, and `onTemplateCategoryUpdate`. There is no
  catch-all handler; a field outside this set is logged and dropped.
- The webhook acknowledges Meta with a `200` before dispatching events, so slow handlers (e.g. an
  AI agent invocation) do not risk Meta's delivery timeout and retries. Inbound event dispatch is
  resilient: a failing handler is logged and does not abort the rest of the notification batch.
- The `Client` is hand-written directly against Meta's official Cloud API reference (and
  cross-checked against Meta's `whatsapp-business-nodejs-sdk` TypeScript types), rather than
  generated from an OpenAPI specification. Its public surface is scoped to sending
  messages/templates and managing media; the broader Graph API surface (groups, flows, QR codes,
  business management, calls, encryption, compliance) is out of scope.
- `ListenerConfig.verifyToken` and `appSecret` are both required, with no bypass.
- Native Java module for `X-Hub-Signature-256` (HMAC-SHA256) webhook signature verification.
