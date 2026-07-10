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

import ballerina/jballerina.java;

# Verifies the `X-Hub-Signature-256` header against the raw webhook payload using HMAC-SHA256.
# This binds to the native Java implementation in the connector's `native` module.
#
# + payload - The raw request body exactly as received
# + signatureHeader - The value of the `X-Hub-Signature-256` header (e.g. `sha256=...`)
# + appSecret - The Meta app secret used as the HMAC key
# + return - `true` if the signature is valid, `false` if it is not, or an error if the HMAC
# could not be computed
isolated function verifyWebhookSignature(string payload, string signatureHeader, string appSecret)
        returns boolean|error = @java:Method {
    'class: "io.ballerinax.whatsapp.business.WebhookSignatureUtils",
    name: "verifySignature"
} external;
