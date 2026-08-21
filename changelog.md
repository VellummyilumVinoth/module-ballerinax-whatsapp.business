# Change Log

This file contains all the notable changes done to the Ballerina WhatsApp Business Cloud connector
through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- [Add manual acknowledgement support for webhook notifications](https://github.com/ballerina-platform/ballerina-library/issues/9041)
  - Added a `ServiceConfig` annotation (`WhatsAppServiceConfig.autoAck`) and a `Caller` client, so
    a service can take control of when a notification is acknowledged instead of the listener
    always responding `200 OK` automatically before dispatch. Annotate the service `@ServiceConfig
    {autoAck: false}` and declare a handler's optional second parameter as `Caller` and call
    `caller->complete()` when ready, e.g.
    `onMessages(MessagesNotification notification, Caller caller)`.

## [2.0.2] - 2026-08-07

### Changed

- [Reduce doc verbosity in listener config, and message types](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/pull/7)

## [2.0.1] - 2026-08-03

### Fixed

- [Fix Ballerina Central doc site rendering repo-only README content](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/pull/5)

## [2.0.0] - 2026-07-29

### Added

- Initial release of the WhatsApp Business Cloud connector
  ([#8887](https://github.com/ballerina-platform/ballerina-library/issues/8887)): a `Client` for
  sending messages, templates, and media (upload/retrieve/delete), and a webhook `Listener` for
  all ten WhatsApp Business Cloud webhook event types (declare only the handlers you need), with
  built-in `X-Hub-Signature-256` (HMAC-SHA256) webhook signature verification.

### Changed

- [Rename webhook event types to drop redundant `Event` suffix](https://github.com/ballerina-platform/module-ballerinax-whatsapp.business/pull/2)
