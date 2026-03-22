import 'package:aurora/features/chat/presentation/widgets/chat_image_bubble.dart';
import 'package:aurora/features/chat/presentation/widgets/reasoning_display.dart';
import 'package:aurora/features/chat/presentation/widgets/selectable_markdown/animated_streaming_markdown.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/utils/stats_calculator.dart';
import 'package:aurora/shared/widgets/aurora_selection.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../domain/message.dart';
import 'chat_attachment_pill.dart';
import 'chat_message_content.dart';
import 'tool_output.dart';

class ChatMessageContentRenderer extends StatelessWidget {
  const ChatMessageContentRenderer({
    super.key,
    required this.blocks,
    required this.theme,
  });

  final List<ChatMessageContentBlock> blocks;
  final fluent.FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) _buildBlock(context, block),
      ],
    );
  }

  Widget _buildBlock(BuildContext context, ChatMessageContentBlock block) {
    return switch (block) {
      ChatReasoningBlock() => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ReasoningDisplay(
            content: block.content,
            isRunning: block.isRunning,
            duration: block.duration,
            startTime: block.startTime,
          ),
        ),
      ChatToolOutputBlock() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: BuildToolOutput(content: block.content),
        ),
      ChatTextBlock() => _buildTextBlock(block),
      ChatAttachmentsBlock() => _buildAttachmentBlock(block),
      ChatImagesBlock() => _buildImagesBlock(block),
      ChatLoadingBlock() => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: PlatformUtils.isDesktop
                    ? const fluent.ProgressRing(strokeWidth: 2)
                    : const CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                block.label,
                style: TextStyle(
                  color: theme.typography.body?.color?.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ChatFooterBlock() => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _MessageFooterRow(message: block.message, theme: theme),
        ),
    };
  }

  Widget _buildTextBlock(ChatTextBlock block) {
    if (block.presentation == ChatTextPresentation.markdown) {
      return fluent.FluentTheme(
        data: theme,
        child: AnimatedStreamingMarkdown(
          data: block.text,
          isDark: theme.brightness == Brightness.dark,
          textColor: theme.typography.body!.color!,
          animate: block.animate,
        ),
      );
    }
    return AuroraSelectableText(
      block.text,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: theme.typography.body?.color,
      ),
    );
  }

  Widget _buildAttachmentBlock(ChatAttachmentsBlock block) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: block.paths.map((path) {
          final lower = path.toLowerCase();
          final isImage = lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.webp') ||
              lower.endsWith('.gif');
          if (isImage) {
            return ChatImageBubble(
              key: ValueKey(path),
              imageUrl: path,
            );
          }
          return ChatAttachmentPill(path: path, theme: theme);
        }).toList(),
      ),
    );
  }

  Widget _buildImagesBlock(ChatImagesBlock block) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: block.urls
            .map(
              (img) => ChatImageBubble(
                key: ValueKey(img),
                imageUrl: img,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MessageFooterRow extends StatelessWidget {
  const _MessageFooterRow({
    required this.message,
    required this.theme,
  });

  final Message message;
  final fluent.FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (message.tokenCount != null && message.tokenCount! > 0) ...[
          Builder(builder: (context) {
            final total = message.tokenCount!;
            final tokenText = formatFullTokenCount(total);

            return Text(
              '$tokenText Tokens',
              style: TextStyle(
                fontSize: 10,
                color: theme.typography.body?.color?.withValues(alpha: 0.5),
              ),
            );
          }),
        ],
        if (message.firstTokenMs != null && message.firstTokenMs! > 0) ...[
          _separator(),
          Text(
            AppLocalizations.of(context)?.averageFirstToken(
                    (message.firstTokenMs! / 1000).toStringAsFixed(2)) ??
                'TTFT: ${(message.firstTokenMs! / 1000).toStringAsFixed(2)}s',
            style: TextStyle(
              fontSize: 10,
              color: theme.typography.body?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
        if (message.durationMs != null && message.durationMs! > 0) ...[
          _separator(),
          Builder(builder: (context) {
            final completion = message.completionTokens ?? 0;
            final reasoning = message.reasoningTokens ?? 0;
            final prompt = message.promptTokens ?? 0;

            int effectiveGenerated = completion + reasoning;
            if (effectiveGenerated == 0 && (message.tokenCount ?? 0) > 0) {
              effectiveGenerated = message.tokenCount! - prompt;
            }

            final tps = StatsCalculator.calculateTPS(
              completionTokens: effectiveGenerated,
              reasoningTokens: 0,
              durationMs: message.durationMs ?? 0,
              firstTokenMs: message.firstTokenMs ?? 0,
            );

            if (tps <= 0) {
              return const SizedBox.shrink();
            }
            return Text(
              '${tps.toStringAsFixed(2)} T/s',
              style: TextStyle(
                fontSize: 10,
                color: theme.typography.body?.color?.withValues(alpha: 0.5),
              ),
            );
          }),
        ],
        _separator(),
        Text(
          '${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 10,
            color: theme.typography.body?.color?.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _separator() {
    return Text(
      ' | ',
      style: TextStyle(
        fontSize: 10,
        color: theme.typography.body?.color?.withValues(alpha: 0.5),
      ),
    );
  }
}
