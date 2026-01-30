import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aurora/l10n/app_localizations.dart';
import '../../data/topic_entity.dart';
import '../topic_provider.dart';
import 'topic_management_dialog.dart';

class TopicDropdown extends ConsumerStatefulWidget {
  final bool isMobile;
  const TopicDropdown({super.key, this.isMobile = false});
  @override
  ConsumerState<TopicDropdown> createState() => _TopicDropdownState();
}

class _TopicDropdownState extends ConsumerState<TopicDropdown> {
  final fluent.FlyoutController _flyoutController = fluent.FlyoutController();
  final GlobalKey _buttonKey = GlobalKey();
  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final selectedTopicId = ref.watch(selectedTopicIdProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);
    final selectedTopicName = selectedTopicId == null
        ? l10n.allChats
        : topicsAsync.value
                ?.firstWhere((t) => t.id == selectedTopicId,
                    orElse: () => TopicEntity()
                      ..id = -1
                      ..name = 'Unknown')
                .name ??
            l10n.allChats;
    if (widget.isMobile) {
      return LayoutBuilder(builder: (context, constraints) {
        return GestureDetector(
          onTap: () => _showMobileTopicBottomSheet(context, topicsAsync, selectedTopicId, theme, l10n),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.label_outline, size: 14, color: theme.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTopicName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.typography.body?.color,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Icon(Icons.arrow_drop_down,
                    size: 20, color: theme.resources.textFillColorSecondary),
              ],
            ),
          ),
        );
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fluent.FlyoutTarget(
          controller: _flyoutController,
          child: fluent.HoverButton(
            key: _buttonKey,
            onPressed: () {
              final renderBox =
                  _buttonKey.currentContext?.findRenderObject() as RenderBox?;
              final width = renderBox?.size.width;
              _flyoutController.showFlyout(
                  placementMode: fluent.FlyoutPlacementMode.bottomLeft,
                  barrierDismissible: true,
                  dismissOnPointerMoveAway: false,
                  dismissWithEsc: true,
                  builder: (context) {
                    return SizedBox(
                      width: width,
                      child: fluent.MenuFlyout(
                        items: [
                          fluent.MenuFlyoutItem(
                            text: Text(l10n.allChats),
                            leading: const SizedBox(width: 14, height: 14),
                            onPressed: () {
                              ref.read(selectedTopicIdProvider.notifier).state =
                                  null;
                              fluent.Navigator.of(context).pop();
                            },
                            trailing: selectedTopicId == null
                                ? Icon(AuroraIcons.check,
                                    size: 12)
                                : null,
                          ),
                          const fluent.MenuFlyoutSeparator(),
                          ...topicsAsync.when(
                            data: (topics) => topics.map((topic) {
                              return fluent.MenuFlyoutItem(
                                text: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                        child: Text(topic.name,
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                leading: const SizedBox(width: 14, height: 14),
                                onPressed: () {
                                  ref
                                      .read(selectedTopicIdProvider.notifier)
                                      .state = topic.id;
                                  fluent.Navigator.of(context).pop();
                                },
                                trailing: selectedTopicId == topic.id
                                    ? Icon(AuroraIcons.check,
                                        size: 12)
                                    : null,
                              );
                            }),
                            loading: () => [
                              fluent.MenuFlyoutItem(
                                  text: const Text('Loading...'),
                                  onPressed: null)
                            ],
                            error: (e, s) => [
                              fluent.MenuFlyoutItem(
                                  text: const Text('Error loading topics'),
                                  onPressed: null)
                            ],
                          ),
                          const fluent.MenuFlyoutSeparator(),
                          fluent.MenuFlyoutItem(
                            text: Text(l10n.createTopic),
                            leading:
                                Icon(AuroraIcons.add, size: 14),
                            onPressed: () {
                              fluent.Navigator.of(context).pop();
                              _showCreateDialog(context, ref);
                            },
                          ),
                          fluent.MenuFlyoutItem(
                            text: Text(l10n.topics),
                            leading: Icon(AuroraIcons.settings,
                                size: 14),
                            onPressed: () {
                              fluent.Navigator.of(context).pop();
                              _showManageTopicsDialog(context, ref);
                            },
                          ),
                        ],
                      ),
                    );
                  });
            },
            builder: (context, states) {
              final isHovering = states.isHovered;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isHovering
                      ? theme.resources.subtleFillColorSecondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isHovering
                        ? theme.resources.surfaceStrokeColorDefault
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(AuroraIcons.tag,
                        size: 14, color: theme.accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedTopicName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.typography.body?.color,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Icon(AuroraIcons.chevronDown,
                        size: 10,
                        color: theme.resources.textFillColorSecondary),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMobileTopicBottomSheet(
    BuildContext context,
    AsyncValue<List<TopicEntity>> topicsAsync,
    int? selectedTopicId,
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
  ) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(context, l10n.topics),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Icon(Icons.all_inclusive,
                      size: 20, color: theme.accentColor),
                  title: Text(l10n.allChats),
                  trailing: selectedTopicId == null
                      ? Icon(Icons.check, size: 20, color: theme.accentColor)
                      : null,
                  onTap: () {
                    ref.read(selectedTopicIdProvider.notifier).state = null;
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                ...topicsAsync.when(
                  data: (topics) => topics.map((topic) => ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 32, right: 16),
                        title: Text(topic.name),
                        trailing: selectedTopicId == topic.id
                            ? Icon(Icons.check,
                                size: 20, color: theme.accentColor)
                            : null,
                        onTap: () {
                          ref.read(selectedTopicIdProvider.notifier).state =
                              topic.id;
                          Navigator.pop(ctx);
                        },
                      )),
                  loading: () => [
                    const ListTile(
                      title: Text('Loading...'),
                      enabled: false,
                    )
                  ],
                  error: (_, __) => [
                    const ListTile(
                      title: Text('Error'),
                      enabled: false,
                    )
                  ],
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, size: 20),
                  title: Text(l10n.createTopic),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCreateDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, size: 20),
                  title: Text(l10n.topics),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showManageTopicsDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    if (widget.isMobile) {
      AuroraBottomSheet.show(
        context: context,
        builder: (context) => TopicManagementDialog(
          onConfirm: (name) {
            ref.read(topicNotifierProvider.notifier).createTopic(name);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => TopicManagementDialog(
          onConfirm: (name) {
            ref.read(topicNotifierProvider.notifier).createTopic(name);
          },
        ),
      );
    }
  }

  void _showManageTopicsDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isMobile) {
      AuroraBottomSheet.show(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(context, l10n.editTopic),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Consumer(builder: (context, ref, _) {
                  final topicsAsync = ref.watch(topicsProvider);
                  return topicsAsync.when(
                    data: (topics) {
                      if (topics.isEmpty)
                        return Center(child: Text(l10n.noCustomParams));
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: topics.map((topic) {
                          return _TopicItem(
                            name: topic.name,
                            isSelected: false,
                            onTap: () {},
                            isMobile: widget.isMobile,
                            onEdit: () => _showEditDialog(
                                context, ref, topic.id, topic.name),
                            onDelete: () =>
                                _showDeleteConfirm(context, ref, topic.id),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: fluent.ProgressRing()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: Text(l10n.editTopic),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Consumer(builder: (context, ref, _) {
              final topicsAsync = ref.watch(topicsProvider);
              return topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) return Center(child: Text("No groups"));
                  return ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return _TopicItem(
                        name: topic.name,
                        isSelected: false,
                        onTap: () {},
                        isMobile: widget.isMobile,
                        onEdit: () =>
                            _showEditDialog(context, ref, topic.id, topic.name),
                        onDelete: () =>
                            _showDeleteConfirm(context, ref, topic.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: fluent.ProgressRing()),
                error: (e, s) => Center(child: Text('Error: $e')),
              );
            }),
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, int id, String name) {
    if (widget.isMobile) {
      AuroraBottomSheet.show(
        context: context,
        builder: (context) => TopicManagementDialog(
          existingTopicId: id,
          initialName: name,
          onConfirm: (newName) {
            ref.read(topicNotifierProvider.notifier).updateTopic(id, newName);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => TopicManagementDialog(
          existingTopicId: id,
          initialName: name,
          onConfirm: (newName) {
            ref.read(topicNotifierProvider.notifier).updateTopic(id, newName);
          },
        ),
      );
    }
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, int id) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isMobile) {
      AuroraBottomSheet.show(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(context, l10n.deleteTopic),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.deleteTopicConfirm, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        ref.read(topicNotifierProvider.notifier).deleteTopic(id);
                        if (ref.read(selectedTopicIdProvider) == id) {
                          ref.read(selectedTopicIdProvider.notifier).state =
                              null;
                        }
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteTopic),
          content: Text(l10n.deleteTopicConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                ref.read(topicNotifierProvider.notifier).deleteTopic(id);
                if (ref.read(selectedTopicIdProvider) == id) {
                  ref.read(selectedTopicIdProvider.notifier).state = null;
                }
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
    }
  }
}

class _TopicItem extends StatefulWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAction;
  final IconData? icon;
  final bool isMobile;
  const _TopicItem({
    required this.name,
    required this.onTap,
    this.isSelected = false,
    this.onEdit,
    this.onDelete,
    this.isAction = false,
    this.icon,
    required this.isMobile,
  });
  @override
  State<_TopicItem> createState() => _TopicItemState();
}

class _TopicItemState extends State<_TopicItem> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final showButtons = (_isHovering || widget.isMobile) &&
        !widget.isAction &&
        widget.onEdit != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.accentColor.withOpacity(0.1)
                : (_isHovering
                    ? theme.resources.subtleFillColorSecondary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (widget.icon != null)
                fluent.Icon(widget.icon!,
                    size: 12,
                    color: widget.isAction
                        ? theme.accentColor
                        : theme.typography.caption?.color)
              else
                const SizedBox(width: 12),
              if (widget.icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isSelected
                        ? theme.accentColor
                        : theme.typography.body?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onEdit != null) ...[
                Opacity(
                  opacity: showButtons ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: AuroraIcons.edit,
                        onTap: widget.onEdit!,
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: AuroraIcons.delete,
                        onTap: widget.onDelete!,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ActionButton(
      {required this.icon, required this.onTap, this.isDestructive = false});
  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return fluent.IconButton(
      icon: fluent.Icon(icon,
          size: 12,
          color: isDestructive
              ? Colors.red
              : theme.resources.textFillColorSecondary),
      onPressed: onTap,
    );
  }
}
