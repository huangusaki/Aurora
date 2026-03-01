import 'dart:convert';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/mcp/domain/mcp_server_config.dart';
import 'package:aurora/features/mcp/presentation/mcp_connection_provider.dart';
import 'package:aurora/features/skills/domain/skill_entity.dart';
import 'package:aurora/shared/services/llm_service.dart';
import 'package:aurora/shared/services/worker_service.dart';
import 'package:uuid/uuid.dart';

import '../../domain/agent_workflow/agent_workflow_json_schema.dart';
import '../../domain/agent_workflow/agent_workflow_models.dart';
import 'agent_workflow_value.dart';
import 'agent_workflow_runner.dart';

class AgentWorkflowDefaultExecutor {
  final LLMService llmService;
  final List<Skill> skills;
  final McpConnectionNotifier mcpConnection;
  final List<McpServerConfig> mcpServers;

  const AgentWorkflowDefaultExecutor({
    required this.llmService,
    required this.skills,
    required this.mcpConnection,
    required this.mcpServers,
  });

  Future<AgentWorkflowValue> call(
    AgentWorkflowNode node,
    AgentWorkflowNodeExecutionRequest request,
  ) async {
    switch (node.type) {
      case AgentWorkflowNodeType.llm:
        return _executeLlm(node, request);
      case AgentWorkflowNodeType.skill:
        return _executeSkill(node, request);
      case AgentWorkflowNodeType.mcp:
        return _executeMcp(node, request);
      case AgentWorkflowNodeType.userInput:
      case AgentWorkflowNodeType.start:
      case AgentWorkflowNodeType.end:
        return AgentWorkflowValue.fromText('');
    }
  }

  Future<AgentWorkflowValue> _executeLlm(
    AgentWorkflowNode node,
    AgentWorkflowNodeExecutionRequest request,
  ) async {
    final baseMessages = <Message>[];
    final systemPrompt = node.systemPrompt.trim();
    if (systemPrompt.isNotEmpty) {
      baseMessages.add(Message(
        id: const Uuid().v4(),
        content: systemPrompt,
        isUser: false,
        timestamp: DateTime.now(),
        role: 'system',
      ));
    }
    baseMessages.add(Message.user(request.renderedBody));

    final primaryOutput = node.outputs
        .where((p) => p.name.trim() != 'error')
        .cast<AgentWorkflowPort?>()
        .firstOrNull;
    final schema = primaryOutput?.schema;
    final shouldUseStructured = node.structuredOutput &&
        primaryOutput != null &&
        primaryOutput.valueType == AgentWorkflowPortValueType.json &&
        schema != null;

    if (!shouldUseStructured) {
      final response = await llmService.getResponse(
        baseMessages,
        model: node.model?.modelId,
        providerId: node.model?.providerId,
        cancelToken: request.cancelToken,
      );
      return AgentWorkflowValue.fromText(response.content ?? '');
    }

    final tool = <String, dynamic>{
      'type': 'function',
      'function': {
        'name': 'workflow_output',
        'description': 'Return structured output for this workflow node.',
        'parameters': schema,
      },
    };

    final maxAttempts = node.autoRepairAttempts.clamp(0, 5);
    final messages = <Message>[...baseMessages];
    for (var attempt = 0; attempt <= maxAttempts; attempt += 1) {
      final response = await llmService.getResponse(
        messages,
        tools: [tool],
        toolChoice: 'function:workflow_output',
        model: node.model?.modelId,
        providerId: node.model?.providerId,
        cancelToken: request.cancelToken,
      );

      final toolCall = (response.toolCalls ?? const [])
          .where((c) => (c.name ?? '').trim() == 'workflow_output')
          .cast<Object?>()
          .firstOrNull;
      if (toolCall is ToolCallChunk) {
        final argsText = toolCall.arguments ?? '';
        dynamic decoded;
        try {
          decoded = jsonDecode(argsText);
        } catch (e) {
          decoded = null;
        }
        if (decoded is Map) {
          final args = decoded.map((k, v) => MapEntry('$k', v));
          final errors = AgentWorkflowJsonSchema.validateInstance(
            schema: schema,
            instance: args,
          );
          if (errors.isEmpty) {
            return AgentWorkflowValue.fromJson(args, raw: response.content);
          }
          if (attempt >= maxAttempts) {
            throw StateError(
                'Structured output validation failed: ${errors.join('; ')}');
          }

          messages.add(Message.user(
              'Your previous `workflow_output` arguments were invalid.\n'
              'Errors:\n${errors.join('\n')}\n\n'
              'Call `workflow_output` again with corrected arguments only.'));
          continue;
        }
      }

      if (attempt >= maxAttempts) {
        throw StateError('Model did not call `workflow_output`.');
      }
      messages.add(Message.user(
          'You must call the `workflow_output` tool with JSON arguments that match the schema.'));
    }

    throw StateError('Structured output failed.');
  }

  Future<AgentWorkflowValue> _executeSkill(
    AgentWorkflowNode node,
    AgentWorkflowNodeExecutionRequest request,
  ) async {
    final skillId = (node.skillId ?? '').trim();
    if (skillId.isEmpty) {
      throw StateError('Skill node is missing skillId.');
    }

    final skill = skills.firstWhere(
      (s) => s.id == skillId || s.name == skillId,
      orElse: () =>
          throw StateError('Skill "$skillId" not found or not loaded.'),
    );

    final worker = WorkerService(llmService);
    final output = await worker.executeSkillTask(
      skill,
      request.renderedBody,
      model: node.model?.modelId,
      providerId: node.model?.providerId,
      cancelToken: request.cancelToken,
    );
    return AgentWorkflowValue.fromText(output);
  }

  Future<AgentWorkflowValue> _executeMcp(
    AgentWorkflowNode node,
    AgentWorkflowNodeExecutionRequest request,
  ) async {
    final serverId = (node.mcpServerId ?? '').trim();
    final toolName = (node.mcpToolName ?? '').trim();
    if (serverId.isEmpty) {
      throw StateError('MCP node is missing serverId.');
    }
    if (toolName.isEmpty) {
      throw StateError('MCP node is missing toolName.');
    }

    final server = mcpServers.firstWhere(
      (s) => s.id == serverId,
      orElse: () => throw StateError('MCP server "$serverId" not found.'),
    );
    if (!server.enabled) {
      throw StateError('MCP server "$serverId" is disabled.');
    }

    final decoded = jsonDecode(request.renderedBody);
    if (decoded is! Map) {
      throw StateError('MCP args must be a JSON object.');
    }
    final args = decoded.map((k, v) => MapEntry('$k', v));

    final schema = node.mcpToolInputSchema;
    if (schema != null) {
      final errors = AgentWorkflowJsonSchema.validateInstance(
        schema: schema,
        instance: args,
      );
      if (errors.isNotEmpty) {
        throw StateError('MCP args validation failed: ${errors.join('; ')}');
      }
    }

    final result = await mcpConnection.callTool(
      server,
      name: toolName,
      arguments: args,
    );

    try {
      final encoded = jsonEncode(result);
      final jsonValue = jsonDecode(encoded);
      return AgentWorkflowValue.fromJson(jsonValue, raw: encoded);
    } catch (_) {
      return AgentWorkflowValue.fromText(result.toString());
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
