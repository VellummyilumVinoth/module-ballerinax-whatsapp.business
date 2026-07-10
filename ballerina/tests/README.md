# Tests

This directory contains the package tests for the WhatsApp Business Cloud connector.

- `test.bal` — verifies the native (Java) `X-Hub-Signature-256` HMAC-SHA256 webhook signature
  binding (valid / tampered / wrong-secret cases) and the connector client initialization.

## Running the tests

The tests depend on the native jar. Build it first (via Gradle
`./gradlew :whatsapp.business-native:build`, or manually), then run:

```bash
cd ballerina
bal test
```

Adding live API tests: create a `Config.toml` with `accessToken`, `phoneNumberId`, and
`recipientNumber`, and gate the tests with a test group so they are skipped by default in CI.
