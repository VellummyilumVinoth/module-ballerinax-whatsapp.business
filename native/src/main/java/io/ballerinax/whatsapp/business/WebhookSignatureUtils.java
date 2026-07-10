/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.whatsapp.business;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * Native utilities for verifying the authenticity of inbound WhatsApp Cloud webhook
 * notifications.
 *
 * <p>Meta signs every webhook request body with an HMAC-SHA256 keyed by the app secret and
 * sends the result in the {@code X-Hub-Signature-256} header as {@code sha256=<hex-digest>}.
 * This class recomputes that signature over the raw request body and compares it against the
 * header value in constant time.</p>
 *
 * @since 2.0.0
 */
public final class WebhookSignatureUtils {

    private static final String HMAC_SHA_256 = "HmacSHA256";
    private static final String SIGNATURE_PREFIX = "sha256=";

    private WebhookSignatureUtils() {
    }

    /**
     * Verifies the {@code X-Hub-Signature-256} header against the raw webhook payload.
     *
     * @param payload         the raw (unparsed) request body exactly as received
     * @param signatureHeader the value of the {@code X-Hub-Signature-256} header
     *                        (e.g. {@code sha256=abc123...})
     * @param appSecret       the Meta app secret used as the HMAC key
     * @return {@code Boolean.TRUE} when the signatures match, {@code Boolean.FALSE} otherwise,
     *         or a Ballerina error if the HMAC could not be computed
     */
    public static Object verifySignature(BString payload, BString signatureHeader, BString appSecret) {
        try {
            Mac mac = Mac.getInstance(HMAC_SHA_256);
            mac.init(new SecretKeySpec(appSecret.getValue().getBytes(StandardCharsets.UTF_8), HMAC_SHA_256));
            byte[] digest = mac.doFinal(payload.getValue().getBytes(StandardCharsets.UTF_8));

            StringBuilder computed = new StringBuilder(SIGNATURE_PREFIX);
            for (byte b : digest) {
                computed.append(String.format("%02x", b));
            }

            byte[] expected = computed.toString().getBytes(StandardCharsets.UTF_8);
            byte[] actual = signatureHeader.getValue().trim().getBytes(StandardCharsets.UTF_8);
            return MessageDigest.isEqual(expected, actual);
        } catch (Exception e) {
            return ErrorCreator.createError(
                    StringUtils.fromString("Failed to verify webhook signature: " + e.getMessage()));
        }
    }
}
