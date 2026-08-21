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

# The service type a consumer implements to handle WhatsApp Business Cloud webhook events. Attach
# an implementation to a `Listener` to receive notifications.
#
# There are ten possible handlers, one per webhook field the subscription can select. None are
# required — declare only the ones you care about; a field whose handler you did not declare (or
# a field outside this closed set) is logged and dropped rather than delivered anywhere.
#
# An eleventh, optional handler, `onError`, does not correspond to a webhook field. It fires when
# one of the ten handlers above returns an `error` while being dispatched — with the default
# `autoAck: true`, the notification has already been acknowledged to Meta by that point, so this is
# the only way to react to a handler failure other than logging (which always happens regardless of
# whether `onError` is declared).
#
# Each handler may optionally declare a second `Caller` parameter for manual acknowledgement (see
# `ServiceConfig`/`WhatsAppServiceConfig.autoAck`), e.g.
# `onMessages(MessagesNotification notification, Caller caller)`.
#
# A compiler plugin validates every remote function you do declare: its name must be one of the
# eleven below, its parameter(s) must match the documented event type (and, if a second parameter
# is declared, `Caller`), and it must return `error?`.
#
# - `remote function onMessages(MessagesNotification notification) returns error?` — Inbound
#   messages or status updates; see `MessagesNotification` for narrowing.
# - `remote function onAccountReviewUpdate(AccountReviewUpdate update) returns error?` — A WABA
#   review decision changes.
# - `remote function onAccountUpdate(AccountUpdate update) returns error?` — Account-lifecycle or
#   compliance changes.
# - `remote function onBusinessCapabilityUpdate(BusinessCapabilityUpdate update) returns error?` —
#   A WABA's messaging or phone-number capability limits change.
# - `remote function onMessageTemplateQualityUpdate(MessageTemplateQualityUpdate update) returns error?`
#   — A message template's quality score changes.
# - `remote function onMessageTemplateStatusUpdate(MessageTemplateStatusUpdate update) returns error?`
#   — A message template's status changes.
# - `remote function onPhoneNumberNameUpdate(PhoneNumberNameUpdate update) returns error?` — A
#   phone number's display-name review outcome is available.
# - `remote function onPhoneNumberQualityUpdate(PhoneNumberQualityUpdate update) returns error?` —
#   A phone number's messaging throughput/quality tier changes.
# - `remote function onSecurity(Security security) returns error?` — A two-step-verification PIN
#   change or reset request for a phone number.
# - `remote function onTemplateCategoryUpdate(TemplateCategoryUpdate update) returns error?` — A
#   message template's category changes, or is about to change.
# - `remote function onError(HandlerError handlerError) returns error?` — Any handler above
#   returned an error while being dispatched.
public type WhatsAppService distinct service object {
    // remote function onMessages(MessagesNotification notification) returns error?;
    // remote function onAccountReviewUpdate(AccountReviewUpdate update) returns error?;
    // remote function onAccountUpdate(AccountUpdate update) returns error?;
    // remote function onBusinessCapabilityUpdate(BusinessCapabilityUpdate update) returns error?;
    // remote function onMessageTemplateQualityUpdate(MessageTemplateQualityUpdate update) returns error?;
    // remote function onMessageTemplateStatusUpdate(MessageTemplateStatusUpdate update) returns error?;
    // remote function onPhoneNumberNameUpdate(PhoneNumberNameUpdate update) returns error?;
    // remote function onPhoneNumberQualityUpdate(PhoneNumberQualityUpdate update) returns error?;
    // remote function onSecurity(Security security) returns error?;
    // remote function onTemplateCategoryUpdate(TemplateCategoryUpdate update) returns error?;
    // remote function onError(HandlerError handlerError) returns error?;
};

# Configuration for a `WhatsAppService`'s acknowledgement behavior.
@display {label: "Service Config"}
public type WhatsAppServiceConfig record {|
    # Whether the listener acknowledges (`200 OK`) a notification automatically as soon as it's
    # received, before any handler runs. Set to `false` to take control of this yourself —
    # declare a handler's optional second parameter as a `Caller` and call `caller->complete()`
    # when ready; see `Caller`. Defaults to `true` (automatic acknowledgement).
    @display {label: "Auto Ack"}
    boolean autoAck = true;
|};

# Configures a `WhatsAppService`'s acknowledgement behavior. Optional — a service with no
# `@ServiceConfig` behaves as though `autoAck: true` were set.
public annotation WhatsAppServiceConfig ServiceConfig on service, class;
