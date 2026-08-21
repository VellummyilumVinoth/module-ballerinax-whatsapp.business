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

# Listener for WhatsApp Business Cloud webhook notifications. It wraps an `http:Listener`,
# handles the Meta subscription handshake and `X-Hub-Signature-256` verification, and dispatches
# inbound messages and status updates to an attached `WhatsAppService`.
#
# ```ballerina
# listener business:Listener whatsappListener = new (8090, verifyToken = "my-token", appSecret = "my-secret");
#
# service business:WhatsAppService on whatsappListener {
#     remote function onMessages(business:MessagesNotification notification) returns error? {
#         if notification is business:Messages {
#             // handle inbound messages: notification.messages
#         } else {
#             // handle status updates: notification.statuses
#         }
#     }
#     // ... plus any of the other nine (all optional) handlers you need
# }
# ```
#
# By default, each notification is acknowledged (`200 OK`) automatically as soon as it's received,
# before any handler runs. Annotate an attached service with `ServiceConfig` and set
# `autoAck: false` to take control of this yourself — declare a handler's optional second
# parameter as a `Caller` and call `caller->complete()` when ready; see `Caller` and
# `ServiceConfig`.
@display {label: "Whatsapp Business", iconPath: "icon.png"}
public class Listener {
    private final http:Listener httpListener;
    private final string verifyToken;
    private final string appSecret;
    private HttpService? httpService = ();

    # Initializes the webhook listener.
    #
    # + listenTo - A port number to bind a new `http:Listener` to, or an existing `http:Listener`
    # + config - The listener configuration (verify token and app secret; both required)
    # + return - A `business:Error` (specifically a `business:ListenerError`) if the listener could
    #            not be initialized, otherwise `()`
    public function init(int|http:Listener listenTo, *ListenerConfig config) returns Error? {
        if listenTo is int {
            http:Listener|error newListener = new (listenTo);
            if newListener is error {
                return error ListenerError("Failed to initialize the underlying HTTP listener", newListener);
            }
            self.httpListener = newListener;
        } else {
            self.httpListener = listenTo;
        }
        self.verifyToken = config.verifyToken;
        self.appSecret = config.appSecret;
    }

    # Attaches a `WhatsAppService` implementation to the listener.
    #
    # + whatsappService - The service that handles webhook events
    # + name - The path (or path segments) to attach the service on; defaults to the listener root
    # + return - A `business:Error` (specifically a `business:ListenerError`) if attaching failed,
    #            otherwise `()`
    public function attach(WhatsAppService whatsappService, string[]|string? name = ()) returns Error? {
        WhatsAppServiceConfig serviceConfig = (typeof whatsappService).@ServiceConfig ?: {};
        HttpService httpService = new (whatsappService, self.verifyToken, self.appSecret, serviceConfig.autoAck);
        self.httpService = httpService;
        error? result = self.httpListener.attach(httpService, name);
        if result is error {
            return error ListenerError("Failed to attach the service to the listener", result);
        }
    }

    # Detaches the attached `WhatsAppService` from the listener.
    #
    # + whatsappService - The service to detach
    # + return - A `business:Error` (specifically a `business:ListenerError`) if detaching failed,
    #            otherwise `()`
    public function detach(WhatsAppService whatsappService) returns Error? {
        HttpService? httpService = self.httpService;
        if httpService is HttpService {
            error? result = self.httpListener.detach(httpService);
            if result is error {
                return error ListenerError("Failed to detach the service from the listener", result);
            }
            self.httpService = ();
        }
    }

    # Starts the listener.
    #
    # + return - A `business:Error` (specifically a `business:ListenerError`) if the listener could
    #            not be started, otherwise `()`
    public function 'start() returns Error? {
        error? result = self.httpListener.'start();
        if result is error {
            return error ListenerError("Failed to start the listener", result);
        }
    }

    # Gracefully stops the listener, allowing in-flight requests to complete.
    #
    # + return - A `business:Error` (specifically a `business:ListenerError`) if the listener could
    #            not be stopped, otherwise `()`
    public function gracefulStop() returns Error? {
        error? result = self.httpListener.gracefulStop();
        if result is error {
            return error ListenerError("Failed to gracefully stop the listener", result);
        }
    }

    # Immediately stops the listener.
    #
    # + return - A `business:Error` (specifically a `business:ListenerError`) if the listener could
    #            not be stopped, otherwise `()`
    public function immediateStop() returns Error? {
        error? result = self.httpListener.immediateStop();
        if result is error {
            return error ListenerError("Failed to immediately stop the listener", result);
        }
    }
}
