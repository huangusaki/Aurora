import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../chat_provider.dart';
import '../../../domain/chat_message_transformers.dart';
import '../../../domain/message_transformer.dart';
import '../../../domain/ui_message.dart';
import '../../../../settings/presentation/settings_provider.dart';
import 'chat_message_assembler.dart';
import 'chat_message_avatar.dart';
import 'chat_message_content_renderer.dart';
import 'chat_message_frame.dart';
import 'chat_utils.dart';

class MergedMessageBubble extends ConsumerStatefulWidget {
  const MergedMessageBubble({
    super.key,
    required this.group,
    this.isLast = false,
    this.isGenerating = false,
    this.animateStreamingContent = true,
  });

  final MergedGroupItem group;
  final bool isLast;
  final bool isGenerating;
  final bool animateStreamingContent;

  @override
  ConsumerState<MergedMessageBubble> createState() =>
      _MergedMessageBubbleState();
}

class _MergedMessageBubbleState extends ConsumerState<MergedMessageBubble>
    with AutomaticKeepAliveClientMixin {
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _editScrollController = ScrollController();

  @override
  bool get wantKeepAlive =>
      _isEditing ||
      widget.group.messages.any(
        (message) =>
            message.attachments.isNotEmpty || message.images.isNotEmpty,
      );

  @override
  void initState() {
    super.initState();
    _editController =
        TextEditingController(text: widget.group.messages.last.content);
  }

  @override
  void didUpdateWidget(MergedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContent = oldWidget.group.messages.last.content;
    final newContent = widget.group.messages.last.content;
    if (!_isEditing && oldContent != newContent) {
      _editController.text = newContent;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    _editScrollController.dispose();
    super.dispose();
  }

  void _handleAction(String action) async {
    final group = widget.group;
    final notifier = ref.read(historyChatProvider);
    switch (action) {
      case 'retry':
        notifier.regenerateResponse(group.messages.first.id);
        break;
      case 'edit':
        setState(() => _isEditing = true);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _focusNode.requestFocus());
        break;
      case 'copy':
        final msg = group.messages.last;
        final settingsState = ref.read(settingsProvider);
        final transformContext = MessageTransformContext(
          language: settingsState.language,
          model: msg.model ?? settingsState.selectedModel,
          providerName: msg.provider ?? settingsState.activeProvider.name,
        );
        final transformed = chatMessageTransformers.visualTransform(
          UiMessage.fromLegacy(msg),
          transformContext,
        );
        await Clipboard.setData(ClipboardData(text: transformed.text));
        break;
      case 'delete':
        for (final message in group.messages) {
          notifier.deleteMessage(message.id);
        }
        break;
      case 'branch':
        final sessionId = ref.read(selectedHistorySessionIdProvider);
        if (sessionId == null) break;
        final sessions = ref.read(sessionsProvider).sessions;
        final session =
            sessions.where((item) => item.sessionId == sessionId).firstOrNull;
        if (session == null) break;
        final branchSuffix = AppLocalizations.of(context)?.branch ?? 'Branch';
        final lastMessage = group.messages.last;
        final newSessionId =
            await ref.read(sessionsProvider.notifier).createBranchSession(
                  originalSessionId: sessionId,
                  originalTitle: session.title,
                  upToMessageId: lastMessage.id,
                  branchSuffix: '-$branchSuffix',
                );
        if (newSessionId != null) {
          ref.read(selectedHistorySessionIdProvider.notifier).state =
              newSessionId;
        }
        break;
    }
  }

  void _saveEdit() {
    final lastMessage = widget.group.messages.last;
    if (_editController.text.trim().isNotEmpty) {
      ref
          .read(historyChatProvider)
          .editMessage(lastMessage.id, _editController.text);
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settingsState = ref.watch(settingsProvider);
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final messages = widget.group.messages;
    final headerMessage = messages.firstWhere(
      (message) => message.role != 'tool',
      orElse: () => messages.last,
    );
    final transformContext = MessageTransformContext(
      language: settingsState.language,
      model: headerMessage.model ?? settingsState.selectedModel,
      providerName: headerMessage.provider ?? settingsState.activeProvider.name,
    );
    final renderData = ChatMessageAssembler.assembleMerged(
      messages: messages,
      transformContext: transformContext,
      isGenerating: widget.isGenerating,
      animateStreamingContent: widget.animateStreamingContent,
      loadingLabel: '${l10n?.deepThinking ?? 'Thinking'}...',
    );
    final headerTextColor = (settingsState.useCustomTheme &&
            settingsState.backgroundImagePath != null &&
            settingsState.backgroundImagePath!.isNotEmpty)
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.grey[600];
    final mobileActionColor = (settingsState.useCustomTheme &&
            settingsState.backgroundImagePath != null &&
            settingsState.backgroundImagePath!.isNotEmpty)
        ? Colors.white.withValues(alpha: 0.7)
        : null;

    return ChatMessageFrame(
      isUser: false,
      settingsState: settingsState,
      theme: theme,
      isEditing: _isEditing,
      leadingAvatar: ChatMessageAvatar(
        avatarPath: settingsState.llmAvatar,
        fallbackIcon: AuroraIcons.robot,
        backgroundColor: theme.accentColor,
      ),
      header: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(
          '${headerMessage.model ?? 'AI'} | ${headerMessage.provider ?? 'Assistant'}',
          style: TextStyle(
            color: headerTextColor,
            fontSize: 12,
          ),
        ),
      ),
      body: _isEditing
          ? _MergedEditPanel(
              messageId: widget.group.messages.last.id,
              controller: _editController,
              focusNode: _focusNode,
              scrollController: _editScrollController,
              onCancel: () => setState(() => _isEditing = false),
              onSave: _saveEdit,
            )
          : ChatMessageContentRenderer(
              blocks: renderData.blocks,
              theme: theme,
            ),
      desktopActionItems: [
        ActionButton(
          icon: AuroraIcons.retry,
          tooltip: l10n?.retry ?? 'Retry',
          onPressed: () => _handleAction('retry'),
        ),
        ActionButton(
          icon: AuroraIcons.edit,
          tooltip: l10n?.edit ?? 'Edit',
          onPressed: () => _handleAction('edit'),
        ),
        ActionButton(
          icon: AuroraIcons.copy,
          tooltip: l10n?.copy ?? 'Copy',
          onPressed: () => _handleAction('copy'),
        ),
        ActionButton(
          icon: AuroraIcons.branch,
          tooltip: l10n?.branch ?? 'Branch',
          onPressed: () => _handleAction('branch'),
        ),
        ActionButton(
          icon: AuroraIcons.delete,
          tooltip: l10n?.delete ?? 'Delete',
          onPressed: () => _handleAction('delete'),
        ),
      ],
      mobileActionItems: [
        MobileActionButton(
          icon: AuroraIcons.retry,
          color: mobileActionColor,
          onPressed: () => _handleAction('retry'),
        ),
        MobileActionButton(
          icon: AuroraIcons.edit,
          color: mobileActionColor,
          onPressed: () => _handleAction('edit'),
        ),
        MobileActionButton(
          icon: AuroraIcons.copy,
          color: mobileActionColor,
          onPressed: () => _handleAction('copy'),
        ),
        MobileActionButton(
          icon: AuroraIcons.branch,
          color: mobileActionColor,
          onPressed: () => _handleAction('branch'),
        ),
        MobileActionButton(
          icon: AuroraIcons.delete,
          color: mobileActionColor,
          onPressed: () => _handleAction('delete'),
        ),
      ],
      showDesktopActions: !_isEditing && !widget.isGenerating,
      showMobileActions: !_isEditing && !widget.isGenerating,
      desktopActionsPadding: const EdgeInsets.only(top: 4, left: 4),
      mobileActionsPadding: const EdgeInsets.only(top: 4, left: 4),
    );
  }
}

class _MergedEditPanel extends StatelessWidget {
  const _MergedEditPanel({
    required this.messageId,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onCancel,
    required this.onSave,
  });

  final String messageId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      key: ValueKey('merged_edit_container_$messageId'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey != LogicalKeyboardKey.enter) {
                  return KeyEventResult.ignored;
                }
                onSave();
                return KeyEventResult.handled;
              },
              child: fluent.TextBox(
                key: ValueKey('merged_edit_box_$messageId'),
                controller: controller,
                scrollController: scrollController,
                focusNode: focusNode,
                maxLines: 15,
                minLines: 1,
                decoration: const fluent.WidgetStatePropertyAll(
                  fluent.BoxDecoration(
                    color: Colors.transparent,
                    border: Border.fromBorderSide(BorderSide.none),
                  ),
                ),
                highlightColor: Colors.transparent,
                unfocusedColor: Colors.transparent,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.typography.body?.color,
                ),
                onSubmitted: (_) => onSave(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionButton(
                icon: AuroraIcons.cancel,
                tooltip: l10n?.cancel ?? 'Cancel',
                onPressed: onCancel,
              ),
              const SizedBox(width: 4),
              ActionButton(
                icon: AuroraIcons.save,
                tooltip: l10n?.save ?? 'Save',
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
