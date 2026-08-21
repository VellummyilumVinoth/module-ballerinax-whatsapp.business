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

package io.ballerinax.whatsapp.business.plugin;

import java.util.Map;

/**
 * Compiler plugin constants for the WhatsApp Business connector.
 */
final class PluginConstants {

    static final String PACKAGE_ORG = "ballerinax";
    static final String PACKAGE_PREFIX = "whatsapp.business";
    static final String EXPECTED_RETURN_SIGNATURE = "error?";

    // Handler name -> the simple name of its expected (sole) parameter type.
    static final Map<String, String> HANDLER_PARAM_TYPES = Map.ofEntries(
            Map.entry("onMessages", "MessagesNotification"),
            Map.entry("onAccountReviewUpdate", "AccountReviewUpdate"),
            Map.entry("onAccountUpdate", "AccountUpdate"),
            Map.entry("onBusinessCapabilityUpdate", "BusinessCapabilityUpdate"),
            Map.entry("onMessageTemplateQualityUpdate", "MessageTemplateQualityUpdate"),
            Map.entry("onMessageTemplateStatusUpdate", "MessageTemplateStatusUpdate"),
            Map.entry("onPhoneNumberNameUpdate", "PhoneNumberNameUpdate"),
            Map.entry("onPhoneNumberQualityUpdate", "PhoneNumberQualityUpdate"),
            Map.entry("onSecurity", "Security"),
            Map.entry("onTemplateCategoryUpdate", "TemplateCategoryUpdate"),
            Map.entry("onError", "HandlerError")
    );

    /**
     * Compilation errors reported by the WhatsApp Business compiler plugin.
     */
    enum CompilationErrors {
        INVALID_RESOURCE_FUNCTION("Resource functions are not allowed on a WhatsAppService; " +
                "declare the handlers you need as remote functions instead.", "WHATSAPP_101"),
        FUNCTION_SHOULD_BE_REMOTE("The '%s' handler must have the remote qualifier.", "WHATSAPP_102"),
        UNKNOWN_HANDLER("Unknown WhatsAppService handler '%s'. Must be one of: onMessages, " +
                "onAccountReviewUpdate, onAccountUpdate, onBusinessCapabilityUpdate, " +
                "onMessageTemplateQualityUpdate, onMessageTemplateStatusUpdate, onPhoneNumberNameUpdate, " +
                "onPhoneNumberQualityUpdate, onSecurity, onTemplateCategoryUpdate, onError.", "WHATSAPP_103"),
        INVALID_PARAMETER_COUNT("Invalid parameter count. The '%s' handler accepts a mandatory '%s' parameter " +
                "and an optional 'business:Caller' parameter.", "WHATSAPP_104"),
        INVALID_PARAMETER_TYPE("Invalid type for the '%s' handler's %s parameter. Expected '%s'.", "WHATSAPP_105"),
        INVALID_RETURN_TYPE("Invalid return type for the '%s' handler. Must return error?.", "WHATSAPP_106");

        private final String error;
        private final String errorCode;

        CompilationErrors(String error, String errorCode) {
            this.error = error;
            this.errorCode = errorCode;
        }

        String getError() {
            return error;
        }

        String getErrorCode() {
            return errorCode;
        }
    }

    private PluginConstants() {
    }
}
