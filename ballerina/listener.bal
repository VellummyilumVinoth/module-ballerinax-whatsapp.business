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
# listener whatsapp:Listener whatsappListener = new (8090, verifyToken = "my-token", appSecret = "my-secret");
#
# service whatsapp:WhatsAppService on whatsappListener {
#     remote function onMessages(whatsapp:MessagesNotificationEvent event) returns error? {
#         if event is whatsapp:MessagesEvent {
#             // handle inbound messages: event.messages
#         } else {
#             // handle status updates: event.statuses
#         }
#     }
#     // ... plus the other nine handlers required by the interface
# }
# ```
public class Listener {
    private final http:Listener httpListener;
    private final string verifyToken;
    private final string appSecret;
    private HttpService? httpService = ();

    # Initializes the webhook listener.
    #
    # + listenTo - A port number to bind a new `http:Listener` to, or an existing `http:Listener`
    # + config - The listener configuration (verify token and app secret; both required)
    # + return - An error if the listener could not be initialized, otherwise `()`
    public function init(int|http:Listener listenTo, *ListenerConfig config) returns error? {
        if listenTo is int {
            self.httpListener = check new (listenTo);
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
    # + return - An error if attaching failed, otherwise `()`
    public function attach(WhatsAppService whatsappService, string[]|string? name = ()) returns error? {
        HttpService httpService = new (whatsappService, self.verifyToken, self.appSecret);
        self.httpService = httpService;
        check self.httpListener.attach(httpService, name);
    }

    # Detaches the attached `WhatsAppService` from the listener.
    #
    # + whatsappService - The service to detach
    # + return - An error if detaching failed, otherwise `()`
    public function detach(WhatsAppService whatsappService) returns error? {
        HttpService? httpService = self.httpService;
        if httpService is HttpService {
            check self.httpListener.detach(httpService);
        }
    }

    # Starts the listener.
    #
    # + return - An error if the listener could not be started, otherwise `()`
    public function 'start() returns error? {
        return self.httpListener.'start();
    }

    # Gracefully stops the listener, allowing in-flight requests to complete.
    #
    # + return - An error if the listener could not be stopped, otherwise `()`
    public function gracefulStop() returns error? {
        return self.httpListener.gracefulStop();
    }

    # Immediately stops the listener.
    #
    # + return - An error if the listener could not be stopped, otherwise `()`
    public function immediateStop() returns error? {
        return self.httpListener.immediateStop();
    }
}
