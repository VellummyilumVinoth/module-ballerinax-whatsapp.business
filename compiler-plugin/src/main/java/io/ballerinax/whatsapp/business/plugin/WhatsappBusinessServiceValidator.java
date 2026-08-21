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

import io.ballerina.compiler.api.symbols.FunctionTypeSymbol;
import io.ballerina.compiler.api.symbols.MethodSymbol;
import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ParameterSymbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerinax.whatsapp.business.plugin.PluginConstants.CompilationErrors;

import java.util.List;
import java.util.Optional;

/**
 * Validates the remote functions declared on a {@code WhatsAppService} implementation: each must
 * be one of the ten documented handlers, with the expected parameter type and an {@code error?}
 * return type.
 */
public class WhatsappBusinessServiceValidator {

    public void validate(SyntaxNodeAnalysisContext context) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) context.node();
        NodeList<Node> memberNodes = serviceDeclarationNode.members();

        for (Node node : memberNodes) {
            if (node.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_RESOURCE_FUNCTION,
                        DiagnosticSeverity.ERROR, node.location()));
                continue;
            }
            if (node.kind() != SyntaxKind.OBJECT_METHOD_DEFINITION) {
                continue;
            }
            FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) node;
            Optional<MethodSymbol> methodSymbol = PluginUtils.getMethodSymbol(context, functionDefinitionNode);
            if (methodSymbol.isEmpty()) {
                continue;
            }
            validateMethod(context, functionDefinitionNode, methodSymbol.get());
        }
    }

    private void validateMethod(SyntaxNodeAnalysisContext context, FunctionDefinitionNode functionDefinitionNode,
            MethodSymbol methodSymbol) {
        Optional<String> functionName = methodSymbol.getName();
        if (functionName.isEmpty()) {
            return;
        }
        String name = functionName.get();
        String expectedParamType = PluginConstants.HANDLER_PARAM_TYPES.get(name);

        if (!PluginUtils.isRemoteFunction(methodSymbol)) {
            if (expectedParamType != null) {
                context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.FUNCTION_SHOULD_BE_REMOTE,
                        DiagnosticSeverity.ERROR, functionDefinitionNode.location(), name));
            }
            return;
        }

        if (expectedParamType == null) {
            context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.UNKNOWN_HANDLER,
                    DiagnosticSeverity.ERROR, functionDefinitionNode.location(), name));
            return;
        }

        FunctionTypeSymbol functionTypeSymbol = methodSymbol.typeDescriptor();
        List<ParameterSymbol> parameters = functionTypeSymbol.params().orElse(List.of());
        if (parameters.isEmpty() || parameters.size() > 2 || functionTypeSymbol.restParam().isPresent()) {
            context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_PARAMETER_COUNT,
                    DiagnosticSeverity.ERROR, functionDefinitionNode.location(), name, expectedParamType));
        } else {
            if (!isExpectedEventType(parameters.get(0).typeDescriptor(), expectedParamType)) {
                context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_PARAMETER_TYPE,
                        DiagnosticSeverity.ERROR, functionDefinitionNode.location(), name, "first",
                        expectedParamType));
            }
            if (parameters.size() == 2 && !isExpectedEventType(parameters.get(1).typeDescriptor(), "Caller")) {
                context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_PARAMETER_TYPE,
                        DiagnosticSeverity.ERROR, functionDefinitionNode.location(), name, "second",
                        "business:Caller"));
            }
        }

        Optional<TypeSymbol> returnType = functionTypeSymbol.returnTypeDescriptor();
        if (returnType.isEmpty() || !PluginConstants.EXPECTED_RETURN_SIGNATURE.equals(returnType.get().signature())) {
            context.reportDiagnostic(PluginUtils.getDiagnostic(CompilationErrors.INVALID_RETURN_TYPE,
                    DiagnosticSeverity.ERROR, functionDefinitionNode.location(), name));
        }
    }

    private boolean isExpectedEventType(TypeSymbol typeSymbol, String expectedSimpleName) {
        if (typeSymbol.typeKind() != TypeDescKind.TYPE_REFERENCE) {
            return false;
        }
        Optional<String> name = typeSymbol.getName();
        Optional<ModuleSymbol> module = typeSymbol.getModule();
        return name.isPresent() && name.get().equals(expectedSimpleName) &&
                module.isPresent() && PluginUtils.isWhatsAppBusinessModule(module.get());
    }
}
