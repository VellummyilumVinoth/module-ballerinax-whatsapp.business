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

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.concurrent.StrandMetadata;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

/**
 * Dispatches an inbound webhook event to a {@code WhatsAppService} handler by name, if (and only
 * if) the attached service implementation declares that handler.
 *
 * <p>{@code WhatsAppService} declares no remote methods of its own (all ten handlers are
 * optional), so the dispatcher cannot invoke handlers via a statically typed Ballerina remote call
 * — the compiler has no method to bind to. Instead, this class looks up the method by name on the
 * service object's runtime type and invokes it reflectively via the Ballerina runtime, mirroring
 * the pattern used by other Ballerina connectors whose listener handlers are optional (e.g.
 * RabbitMQ's {@code onMessage}/{@code onRequest}/{@code onError}).</p>
 *
 * <p>A declared handler may take either one parameter (just the event) or two (the event, then a
 * {@code Caller} for manual acknowledgement) — which form is present is detected here from the
 * declared method's parameter count.</p>
 *
 * @since 2.0.0
 */
public final class HandlerDispatcher {

    private HandlerDispatcher() {
    }

    /**
     * Invokes the named handler on the given service object with the given event (and, if the
     * handler declares a second parameter, the given caller), if the service declares that
     * handler. Does nothing (returns {@code null}, i.e. Ballerina {@code ()}) if the handler is
     * not declared.
     *
     * @param env           the Ballerina runtime environment for this call
     * @param serviceObject the {@code WhatsAppService} implementation attached to the listener
     * @param methodName    the handler's name, e.g. {@code onMessages}
     * @param event         the event record to pass as the handler's first argument
     * @param caller        the {@code Caller} to pass as the handler's second argument, only if it
     *                      declares one
     * @return the handler's result ({@code null} for {@code ()}, a {@code BError} for an error),
     *         or {@code null} if no such handler is declared
     */
    public static Object invokeIfPresent(Environment env, BObject serviceObject, BString methodName, Object event,
            BObject caller) {
        String name = methodName.getValue();
        MethodType method = findMethod(serviceObject, name);
        if (method == null) {
            return null;
        }
        Runtime runtime = env.getRuntime();
        boolean isConcurrentSafe = isIsolated(serviceObject, name);
        StrandMetadata strandMetadata = new StrandMetadata(isConcurrentSafe, null);
        if (method.getParameters().length == 2) {
            return runtime.callMethod(serviceObject, name, strandMetadata, event, caller);
        }
        return runtime.callMethod(serviceObject, name, strandMetadata, event);
    }

    private static MethodType findMethod(BObject serviceObject, String methodName) {
        for (MethodType method : objectType(serviceObject).getMethods()) {
            if (methodName.equals(method.getName())) {
                return method;
            }
        }
        return null;
    }

    private static boolean isIsolated(BObject serviceObject, String methodName) {
        ObjectType objectType = objectType(serviceObject);
        return objectType.isIsolated() && objectType.isIsolated(methodName);
    }

    private static ObjectType objectType(BObject serviceObject) {
        return (ObjectType) TypeUtils.getReferredType(TypeUtils.getType(serviceObject));
    }
}
