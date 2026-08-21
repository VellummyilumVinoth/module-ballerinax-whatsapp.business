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

import ballerina/http;

# Acknowledges a WhatsApp webhook notification. Declare it as a handler's optional second
# parameter (e.g. `onMessages(MessagesNotification notification, Caller caller)`) to take control
# of when the notification is acknowledged — otherwise irrelevant unless the service is annotated
# `ServiceConfig` with `autoAck: false`; an unannotated service defaults to `autoAck: true`
# (automatic acknowledgement).
#
# ```ballerina
# remote function onMessages(business:MessagesNotification notification, business:Caller caller) returns error? {
#     check performSlowWork(notification);
#     check caller->complete();
# }
# ```
#
# If `autoAck` is `false` and a handler never calls `caller->complete()`, the underlying HTTP
# resource function returns having never sent a response, so `http:Service` sends its own default
# `500 Internal Server Error` — a non-`2xx`, so Meta's own webhook retry behavior (retry, then
# eventually give up) is what happens next; this connector does not add a separate timeout or
# retry mechanism of its own.
#
# Conversely, if `autoAck` is `true` (the default) and a handler still calls `caller->complete()`,
# it's a safe no-op — see `complete`.
#
# Meta may redeliver a notification if the acknowledgement is slow, dropped, or never sent — under
# either `autoAck` setting, not just `false`. Make handler processing idempotent, or deduplicate
# using a scoped key: `InboundMessage.messageId` (`wamid`) alone for messages, but
# `MessageStatusUpdate.messageId` needs `status` alongside it, since one message's several status
# updates share the same `messageId`. The entry-level `timestamp` on `Messages`/`MessageStatuses` is
# shared across a whole batch, so it is not a valid key by itself.
public isolated client class Caller {
    private final http:Caller httpCaller;
    private boolean completed;

    isolated function init(http:Caller httpCaller) {
        self.httpCaller = httpCaller;
        self.completed = false;
    }

    # Acknowledges the notification by responding `200 OK` to Meta. A no-op if the notification was
    # already *successfully* acknowledged (automatically, or by an earlier call to this method). A
    # failed call does not mark the notification as acknowledged, so a later call is not a no-op —
    # it attempts to acknowledge again.
    #
    # + return - An `Error` if the acknowledgement could not be sent, otherwise `()`
    isolated remote function complete() returns Error? {
        lock {
            if self.completed {
                return;
            }
            error? result = self.httpCaller->respond(<http:Ok>{});
            if result is error {
                return error ClientError(ERR_ACK_FAILED, result);
            }
            self.completed = true;
        }
    }
}
