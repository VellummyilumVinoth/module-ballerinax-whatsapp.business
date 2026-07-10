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

# The service object a consumer implements to handle WhatsApp Business Cloud webhook events.
# Attach an implementation to a `Listener` to receive notifications.
#
# There are exactly ten handlers, one per webhook field the WhatsApp Business Cloud webhook
# subscription can select. A field outside this set (e.g. `account_alerts`,
# `group_lifecycle_update`, `smb_message_echoes`) is logged and dropped rather than delivered to a
# handler, since such fields can never be subscribed to in the first place.
public type WhatsAppService distinct isolated service object {

    # Invoked once per `messages` webhook notification — either a batch of inbound messages or a
    # batch of status updates; Meta always sends these as two mutually exclusive shapes under this
    # one field, never both together.
    #
    # + event - The received messages or status updates; narrow with `event is MessagesEvent` /
    #           `event is MessageStatusEvent`
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onMessages(MessagesNotificationEvent event) returns error?;

    # Invoked when a WhatsApp Business Account's review decision changes.
    #
    # + event - The review decision
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onAccountReviewUpdate(AccountReviewUpdateEvent event) returns error?;

    # Invoked on account-lifecycle and compliance changes (verification, violations, partner
    # changes, pricing-tier updates, restrictions, disconnection).
    #
    # + event - The account update
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onAccountUpdate(AccountUpdateEvent event) returns error?;

    # Invoked when a WABA's messaging or phone-number capability limits change.
    #
    # + event - The capability update
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onBusinessCapabilityUpdate(BusinessCapabilityUpdateEvent event) returns error?;

    # Invoked when a message template's quality score changes.
    #
    # + event - The quality update
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onMessageTemplateQualityUpdate(MessageTemplateQualityUpdateEvent event) returns error?;

    # Invoked when a message template's status changes (approved, rejected, disabled, ...).
    #
    # + event - The status update
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onMessageTemplateStatusUpdate(MessageTemplateStatusUpdateEvent event) returns error?;

    # Invoked when a business phone number's display-name review outcome is available.
    #
    # + event - The name-review outcome
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onPhoneNumberNameUpdate(PhoneNumberNameUpdateEvent event) returns error?;

    # Invoked when a business phone number's messaging throughput/quality tier changes.
    #
    # + event - The quality update
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onPhoneNumberQualityUpdate(PhoneNumberQualityUpdateEvent event) returns error?;

    # Invoked on two-step-verification PIN changes and reset requests for a business phone number.
    #
    # + event - The security event
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onSecurity(SecurityEvent event) returns error?;

    # Invoked when a message template's category changes, or is about to change.
    #
    # + event - The category update
    # + return - An error if handling failed, otherwise `()`
    isolated remote function onTemplateCategoryUpdate(TemplateCategoryUpdateEvent event) returns error?;
};
