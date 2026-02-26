import 'dart:convert';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/mcp/domain/mcp_server_config.dart';
import 'package:aurora/features/mcp/presentation/mcp_connection_provider.dart';
import 'package:aurora/features/skills/domain/skill_entity.dart';
import 'package:aurora/shared/services/llm_service.dart';
import 'package:aurora/shared/services/worker_service.dart';
import 'package:uuid/uuid.dart';

import '../../domain/agent_workflow/agent_workflow_models.dart';
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

  Future<String> call(
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
      case AgentWorkflowNodeType.start:
      case AgentWorkflowNodeType.end:
        return '';
    }
  }

  Future<String> _executeLlm(
    AgentWorkflowNode node,
    AgentWorkflowNodeExecutionRequest request,
  ) async {
    final messages = <Message>[];
    final systemPrompt = node.systemPrompt.trim();
    if (systemPrompt.isNotEmpty) {
      messages.add(Message(
        id: const Uuid().v4(),
        content: systemPrompt,
        isUser: false,
        timestamp: DateTime.now(),
        role: 'system',
      ));
    }
    messages.add(Message.user(request.renderedBody));

    final response = await llmService.getResponse(
      messages,
      model: node.model?.modelId,
      providerId: node.model?.providerId,
      cancelToken: request.cancelToken,
    );
    return response.content ?? '';
  }

  Future<String> _executeSkill(
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
    return worker.executeSkillTask(
      skill,
      request.renderedBody,
      model: node.model?.modelId,
      providerId: node.model?.providerId,
      cancelToken: request.cancelToken,
    );
  }

  Future<String> _executeMcp(
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

    final result = await mcpConnection.callTool(
      server,
      name: toolName,
      arguments: args,
    );

    return jsonEncode(result);
  }
}

