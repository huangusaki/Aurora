import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'widgets/model_config_dialog.dart';
import 'widgets/create_project_dialog.dart';
import 'novel_provider.dart';
import 'novel_state.dart';

class NovelWritingPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const NovelWritingPage({super.key, this.onBack});

  @override
  ConsumerState<NovelWritingPage> createState() => _NovelWritingPageState();
}

class _NovelWritingPageState extends ConsumerState<NovelWritingPage> {
  final _taskInputController = TextEditingController();
  final _newChapterController = TextEditingController();
  final _projectFlyoutController = FlyoutController();
  
  int _selectedNavIndex = 0; // 0: Writing, 1: Context, 2: Preview

  @override
  void dispose() {
    _taskInputController.dispose();
    _newChapterController.dispose();
    _projectFlyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);
    final state = ref.watch(novelProvider);
    final notifier = ref.read(novelProvider.notifier);

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          // Custom Header
          _buildCustomHeader(context, l10n, theme, state, notifier),
          const Divider(),
          
          // Content Body
          Expanded(
            child: _buildBodyContent(context, l10n, theme, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.transparent,
      child: Row(
        children: [
          // Left Group: Back & Project Selector
          if (widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(FluentIcons.back, size: 14),
                onPressed: widget.onBack,
              ),
            ),
          
          _buildProjectSelector(context, l10n, theme, state, notifier),
          
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: theme.resources.dividerStrokeColorDefault),
          const SizedBox(width: 16),

          // Navigation Tabs (Left Aligned)
          _buildNavTab(context, theme, 0, l10n.writing, FluentIcons.edit),
          const SizedBox(width: 4),
          _buildNavTab(context, theme, 1, l10n.context, FluentIcons.database),
          const SizedBox(width: 4),
          _buildNavTab(context, theme, 2, l10n.preview, FluentIcons.print),
          const SizedBox(width: 8),
          // Preset Dropdown
          _buildPresetDropdown(context, theme, state, ref.read(novelProvider.notifier), l10n),

          const Spacer(),

          // Right Group: Controls
          // Review Mode Checkbox
          Checkbox(
            checked: state.isReviewEnabled,
            onChanged: (v) => notifier.toggleReviewMode(v ?? false),
            content: Text(l10n.reviewModel),
          ),
          const SizedBox(width: 16),
          
          // Execution Controls
          if (state.isRunning) ...[
            FilledButton(
              onPressed: () => notifier.stopQueue(),
              style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FluentIcons.stop, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(l10n.stopTask, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: () => notifier.togglePause(),
              child: Icon(state.isPaused ? FluentIcons.play : FluentIcons.pause, size: 12),
            ),
          ] else ...[
            Tooltip(
              message: state.allTasks.any((t) => t.status == TaskStatus.pending)
                  ? '按顺序执行所有待办任务'
                  : '没有可执行的待办任务',
              child: FilledButton(
                onPressed: state.allTasks.any((t) => t.status == TaskStatus.pending)
                    ? () => notifier.startQueue()
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.play, size: 12),
                    SizedBox(width: 4),
                    Text(l10n.startWriting),
                  ],
                ),
              ),
            ),
            // Restart button - only show when there are completed/failed tasks
            if (state.allTasks.any((t) => t.status == TaskStatus.success || t.status == TaskStatus.failed)) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: '重置所有任务状态，从头开始重新生成',
                child: Button(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ContentDialog(
                        title: const Text('重新执行所有任务'),
                        content: const Text('确定要重置所有任务吗？\n这将清空已生成的内容，所有章节需要重新生成。'),
                        actions: [
                          Button(
                            child: Text(l10n.cancel),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          FilledButton(
                            style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.orange)),
                            child: const Text('重新执行'),
                            onPressed: () {
                              notifier.restartAllTasks();
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.refresh, size: 12),
                      SizedBox(width: 4),
                      Text('重新执行'),
                    ],
                  ),
                ),
              ),
            ],
          ],
          
          const SizedBox(width: 12),
          
          // Settings
          IconButton(
            icon: const Icon(FluentIcons.settings, size: 16),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ModelConfigDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.projects.isEmpty) {
      return SizedBox(
        width: 150,
        child: Button(
          onPressed: () => _showNewProjectDialog(context, l10n, notifier),
          child: Text(l10n.createProject),
        ),
      );
    }

    final projectName = state.selectedProject?.name ?? l10n.selectProject;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlyoutTarget(
          controller: _projectFlyoutController,
          child: SizedBox(
            width: 200,
            child: Button(
              onPressed: () {
                _projectFlyoutController.showFlyout(
                  autoModeConfiguration: FlyoutAutoConfiguration(
                    preferredMode: FlyoutPlacementMode.bottomCenter,
                  ),
                  builder: (context) {
                    return MenuFlyout(
                      items: state.projects.map((p) => MenuFlyoutItem(
                        text: Text(p.name, style: const TextStyle(fontSize: 13)),
                        selected: state.selectedProjectId == p.id,
                        onPressed: () {
                          notifier.selectProject(p.id);
                        },
                      )).toList(),
                    );
                  },
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      projectName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Icon(FluentIcons.chevron_down, size: 8),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(FluentIcons.add, size: 14),
          onPressed: () => _showNewProjectDialog(context, l10n, notifier),
        ),
        IconButton(
          icon: Icon(FluentIcons.delete, size: 14, color: Colors.red.light),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                title: Text(l10n.deleteProject),
                content: Text(l10n.deleteProjectConfirm),
                actions: [
                  Button(
                    child: Text(l10n.cancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FilledButton(
                    style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                    child: Text(l10n.delete),
                    onPressed: () {
                      if (state.selectedProjectId != null) {
                        notifier.deleteProject(state.selectedProjectId!);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavTab(BuildContext context, FluentThemeData theme, int index, String title, IconData icon) {
    final isSelected = _selectedNavIndex == index;
    if (isSelected) {
      return FilledButton(
        onPressed: () => setState(() => _selectedNavIndex = index),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );
    } else {
      return Button(
        onPressed: () => setState(() => _selectedNavIndex = index),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.typography.body?.color?.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: theme.typography.body?.color)),
          ],
        ),
      );
    }
  }

  Widget _buildPresetDropdown(BuildContext context, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier, AppLocalizations l10n) {
    final presets = state.promptPresets;
    final activePresetId = state.activePromptPresetId;
    
    // Find active preset name
    String selectedLabel = l10n.systemDefault;
    if (activePresetId != null) {
      final active = presets.firstWhere(
        (p) => p.id == activePresetId,
        orElse: () => NovelPromptPreset(id: '', name: l10n.systemDefault, outlinePrompt: '', decomposePrompt: '', writerPrompt: '', reviewerPrompt: ''),
      );
      if (active.id.isNotEmpty) selectedLabel = active.name;
    }
    
    return DropDownButton(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.edit_note, size: 14),
          const SizedBox(width: 6),
          Text(selectedLabel, style: const TextStyle(fontSize: 13)),
        ],
      ),
      items: [
        MenuFlyoutItem(
          text: Text(l10n.systemDefault, style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            notifier.setOutlinePrompt(NovelPromptPresets.outline);
            notifier.setDecomposePrompt(NovelPromptPresets.decompose);
            notifier.setWriterPrompt(NovelPromptPresets.writer);
            notifier.setReviewerPrompt(NovelPromptPresets.reviewer);
            notifier.setActivePromptPresetId(null);
          },
        ),
        if (presets.isNotEmpty) const MenuFlyoutSeparator(),
        ...presets.map((preset) => MenuFlyoutItem(
          text: Text(preset.name),
          onPressed: () {
            if (preset.outlinePrompt.isNotEmpty) notifier.setOutlinePrompt(preset.outlinePrompt);
            if (preset.decomposePrompt.isNotEmpty) notifier.setDecomposePrompt(preset.decomposePrompt);
            if (preset.writerPrompt.isNotEmpty) notifier.setWriterPrompt(preset.writerPrompt);
            if (preset.reviewerPrompt.isNotEmpty) notifier.setReviewerPrompt(preset.reviewerPrompt);
            notifier.setActivePromptPresetId(preset.id);
          },
        )),
      ],
    );
  }

  Widget _buildBodyContent(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildWritingView(context, l10n, theme, state, notifier);
      case 1:
        return _buildContextView(context, l10n, theme, state, notifier);
      case 2:
        return _buildExportView(context, l10n, theme, state, notifier);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _mapProjectName(String name) {
    if (name.length > 20) {
      return Text('${name.substring(0, 20)}...', overflow: TextOverflow.ellipsis);
    }
    return Text(name);
  }

  Widget _buildCard(FluentThemeData theme, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(color: theme.resources.surfaceStrokeColorDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildWritingView(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildCard(
              theme,
              _buildOutlinePanel(context, l10n, theme, state, notifier),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildCard(
              theme,
              _buildChapterTaskTree(context, l10n, theme, state, notifier),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: _buildCard(
              theme,
              _buildTaskDetailPanel(context, l10n, theme, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinePanel(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    final outline = state.selectedProject?.outline ?? '';
    final hasOutline = outline.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(FluentIcons.text_document, size: 16),
              const SizedBox(width: 8),
              Text(l10n.outlineSettings, style: theme.typography.subtitle),
              const Spacer(),
              if (hasOutline)
                 Tooltip(
                  message: l10n.clearOutline,
                  child: IconButton(
                    icon: const Icon(FluentIcons.delete, size: 14),
                    onPressed: () => notifier.updateProjectOutline(''),
                  ),
                ),
            ],
          ),
        ),
              const Divider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: !hasOutline ? _buildOutlineEmptyState(theme, l10n, notifier, state) : _buildOutlineEditor(theme, l10n, notifier, outline),
                ),
              ),
              if (hasOutline)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.resources.layerFillColorAlt,
                    border: Border(top: BorderSide(color: theme.resources.dividerStrokeColorDefault)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: state.isDecomposing ? null : () => _handleDecompose(context, l10n, state, notifier),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (state.isDecomposing)
                                  const SizedBox(
                                    width: 16, 
                                    height: 16, 
                                    child: ProgressRing(strokeWidth: 2),
                                  )
                                else
                                  Icon(state.selectedProject!.chapters.isEmpty ? FluentIcons.add : FluentIcons.refresh, size: 16),
                                const SizedBox(width: 8),
                                Text(state.isDecomposing 
                                    ? l10n.generating 
                                    : (state.selectedProject!.chapters.isEmpty ? l10n.generateChapters : l10n.regenerateChapters)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }

        Widget _buildOutlineEmptyState(FluentThemeData theme, AppLocalizations l10n, NovelNotifier notifier, NovelWritingState state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.edit_create, size: 48, color: theme.accentColor),
              const SizedBox(height: 16),
              Text(l10n.startConceiving, style: theme.typography.bodyStrong),
              const SizedBox(height: 8),
              Text(l10n.outlineHint, style: theme.typography.caption, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextBox(
                controller: _taskInputController,
                placeholder: l10n.outlinePlaceholder,
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.isGeneratingOutline ? null : () {
                  final text = _taskInputController.text.trim();
                  if (text.isNotEmpty) {
                    notifier.generateOutline(text);
                    _taskInputController.clear();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isGeneratingOutline)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: ProgressRing(strokeWidth: 2),
                        )
                      else
                        const SizedBox.shrink(),
                      if (state.isGeneratingOutline) const SizedBox(width: 8),
                      Text(state.isGeneratingOutline ? l10n.generating : l10n.generateOutline),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        Widget _buildOutlineEditor(FluentThemeData theme, AppLocalizations l10n, NovelNotifier notifier, String outline) {
          return TextBox(
            controller: TextEditingController(text: outline),
            expands: true,
            maxLines: null,
            decoration: WidgetStateProperty.all(const BoxDecoration(color: Colors.transparent)),
            placeholder: l10n.editOutlinePlaceholder,
            style: const TextStyle(fontSize: 14, height: 1.5),
            onChanged: (value) => notifier.updateProjectOutline(value),
          );
        }

        void _handleDecompose(BuildContext context, AppLocalizations l10n, NovelWritingState state, NovelNotifier notifier) {
          if (state.selectedProject?.chapters.isNotEmpty ?? false) {
            showDialog(
              context: context,
              builder: (context) => ContentDialog(
                title: Text(l10n.clearAndRegenerate),
                content: Text(l10n.clearChaptersWarning),
                actions: [
                  Button(
                    child: Text(l10n.cancel),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FilledButton(
                    style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                    child: Text(l10n.clearAndRegenerate),
                    onPressed: () {
                      notifier.clearChaptersAndTasks();
                      notifier.decomposeFromOutline();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          } else {
            notifier.decomposeFromOutline();
          }
        }

  Widget _buildContextView(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) {
      return Center(child: Text(l10n.selectProject));
    }
    
    final ctx = state.selectedProject!.worldContext;
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: _buildCard(
        theme,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(FluentIcons.database, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.worldSettings, style: theme.typography.subtitle),
                  const Spacer(),
                  Text(l10n.autoIncludeHint, style: theme.typography.caption),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '清空所有设定',
                    child: IconButton(
                      icon: const Icon(FluentIcons.delete, size: 14),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => ContentDialog(
                            title: const Text('清空世界设定'),
                            content: const Text('确定要清空所有世界设定数据吗？\n（人物设定、人物关系、场景地点、伏笔/线索等）'),
                            actions: [
                              Button(
                                child: Text(l10n.cancel),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                              FilledButton(
                                style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                                child: const Text('清空'),
                                onPressed: () {
                                  notifier.clearWorldContext();
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ToggleButton(
                        checked: ctx.includeRules,
                        onChanged: (v) => notifier.toggleContextCategory('rules', v),
                        child: Text(l10n.worldRules),
                      ),
                      ToggleButton(
                        checked: ctx.includeCharacters,
                        onChanged: (v) => notifier.toggleContextCategory('characters', v),
                        child: Text(l10n.characterSettings),
                      ),
                      ToggleButton(
                        checked: ctx.includeRelationships,
                        onChanged: (v) => notifier.toggleContextCategory('relationships', v),
                        child: Text(l10n.relationships),
                      ),
                      ToggleButton(
                        checked: ctx.includeLocations,
                        onChanged: (v) => notifier.toggleContextCategory('locations', v),
                        child: Text(l10n.locations),
                      ),
                      ToggleButton(
                        checked: ctx.includeForeshadowing,
                        onChanged: (v) => notifier.toggleContextCategory('foreshadowing', v),
                        child: Text(l10n.foreshadowing),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildContextSection(l10n.worldRules, ctx.rules, theme, l10n),
                  const SizedBox(height: 16),
                  _buildContextSection(l10n.characterSettings, ctx.characters, theme, l10n),
                  const SizedBox(height: 16),
                  _buildContextSection(l10n.relationships, ctx.relationships, theme, l10n),
                  const SizedBox(height: 16),
                  _buildContextSection(l10n.locations, ctx.locations, theme, l10n),
                  const SizedBox(height: 16),
                  _buildForeshadowingSection(ctx.foreshadowing, theme, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSection(String title, Map<String, String> data, FluentThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.typography.bodyStrong),
        const SizedBox(height: 8),
        if (data.isEmpty)
          Text(l10n.noDataYet, style: theme.typography.caption)
        else
          ...data.entries.map((e) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                Expanded(child: Text(e.value)),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildForeshadowingSection(List<String> data, FluentThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.foreshadowing, style: theme.typography.bodyStrong),
        const SizedBox(height: 8),
        if (data.isEmpty)
          Text(l10n.noDataYet, style: theme.typography.caption)
        else
          ...data.map((f) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text('• $f'),
          )),
      ],
    );
  }

  Widget _buildExportView(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) {
      return Center(child: Text(l10n.selectProject));
    }

    final content = notifier.exportFullNovel();
    final stats = notifier.getNovelStats();
    final projectName = state.selectedProject?.name ?? '';
    final totalChapters = stats['totalChapters'] ?? 0;
    final completedChapters = stats['completedChapters'] ?? 0;
    final totalWords = stats['totalWords'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: _buildCard(
        theme,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.preview}: $projectName', style: theme.typography.subtitle),
                      const SizedBox(height: 4),
                      Text(
                        '$completedChapters/$totalChapters 章完成 · $totalWords 字',
                        style: theme.typography.caption?.copyWith(color: theme.inactiveColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.copy, size: 14),
                        const SizedBox(width: 8),
                        Text(l10n.copyFullText),
                      ],
                    ),
                    onPressed: () async {
                      if (content.isEmpty) return;
                      final item = DataWriterItem();
                      item.add(Formats.plainText(content));
                      await SystemClipboard.instance?.write([item]);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  content.isEmpty ? l10n.noContentYet : content,
                  style: theme.typography.body?.copyWith(fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterTaskTree(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) {
      return Center(child: Text(l10n.selectProject, style: theme.typography.body));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(FluentIcons.list, size: 16),
              const SizedBox(width: 8),
              Text(l10n.chaptersAndTasks, style: theme.typography.subtitle),
              const Spacer(),
              Tooltip(
                message: l10n.addChapter,
                child: IconButton(
                  icon: const Icon(FluentIcons.add, size: 14),
                  onPressed: () => _showNewChapterDialog(context, l10n, notifier),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.selectedProject!.chapters.length,
            itemBuilder: (context, index) {
              final chapter = state.selectedProject!.chapters[index];
              final tasks = state.tasksForChapter(chapter.id);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chapter header - flat style, no folding
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.resources.layerFillColorAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chapter.title, 
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(FluentIcons.add, size: 12),
                            onPressed: () => _showNewTaskDialog(context, l10n, notifier, chapter.id),
                          ),
                          IconButton(
                            icon: const Icon(FluentIcons.delete, size: 12),
                            onPressed: () {
                               showDialog(
                                context: context,
                                builder: (context) => ContentDialog(
                                  title: const Text('Delete Chapter'),
                                  content: Text(l10n.deleteChapterConfirm),
                                  actions: [
                                    Button(child: Text(l10n.cancel), onPressed: () => Navigator.pop(context)),
                                    FilledButton(
                                      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                                      child: Text(l10n.delete),
                                      onPressed: () {
                                        notifier.deleteChapter(chapter.id);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Tasks list - always visible
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                        child: Text(l10n.noTasks, style: theme.typography.caption?.copyWith(fontStyle: FontStyle.italic)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tasks.map((task) => _buildTaskListItem(context, theme, task, state, notifier)).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskListItem(BuildContext context, FluentThemeData theme, NovelTask task, NovelWritingState state, NovelNotifier notifier) {
    final isSelected = task.id == state.selectedTaskId;
    return GestureDetector(
      onTap: () => notifier.selectTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            _buildStatusIcon(task.status, theme),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.description,
                style: task.status == TaskStatus.success
                    ? TextStyle(decoration: TextDecoration.lineThrough, color: theme.inactiveColor)
                    : null,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.status == TaskStatus.success)
                    IconButton(
                      icon: const Icon(FluentIcons.refresh, size: 12),
                      onPressed: () => notifier.runSingleTask(task.id),
                    ),
                  IconButton(
                    icon: Icon(FluentIcons.delete, size: 12, color: Colors.red.light),
                    onPressed: () => notifier.deleteTask(task.id),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailPanel(BuildContext context, AppLocalizations l10n, FluentThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    final task = state.selectedTask;
    
    if (task == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.task_list, size: 48, color: theme.accentColor),
              const SizedBox(height: 16),
              Text(l10n.selectTaskToView, style: theme.typography.bodyStrong),
            ],
          ),
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(FluentIcons.entry_view, size: 16),
                const SizedBox(width: 8),
                Text(l10n.taskDetails, style: theme.typography.subtitle),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status, theme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getStatusColor(task.status, theme)),
                  ),
                  child: Text(
                    _getStatusLabel(task.status, l10n),
                    style: TextStyle(color: _getStatusColor(task.status, theme), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 8),
              if (task.status == TaskStatus.running || task.status == TaskStatus.decomposing)
                 const SizedBox(width: 20, height: 20, child: ProgressRing(strokeWidth: 2.5))
              else if (task.status == TaskStatus.pending || task.status == TaskStatus.failed)
                FilledButton(
                  onPressed: () => notifier.runSingleTask(task.id),
                  child: Text(l10n.executeTask),
                )
              else if (task.status == TaskStatus.success)
                Button(
                  onPressed: () => notifier.runSingleTask(task.id),
                  child: Text(l10n.regenerate),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.taskRequirement, style: theme.typography.bodyStrong),
                const SizedBox(height: 8),
                TextBox(
                  controller: TextEditingController(text: task.description),
                  maxLines: null,
                  onChanged: (value) => notifier.updateTaskDescription(task.id, value),
                  decoration: WidgetStateProperty.all(BoxDecoration(
                    color: theme.resources.layerFillColorAlt,
                    borderRadius: BorderRadius.circular(4),
                  )),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(l10n.generatedContent, style: theme.typography.bodyStrong),
                    const Spacer(),
                    if (task.content?.isNotEmpty ?? false)
                      Tooltip(
                        message: l10n.copy,
                        child: IconButton(
                          icon: const Icon(FluentIcons.copy, size: 14),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: task.content ?? ''));
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (task.content?.isEmpty ?? true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.resources.dividerStrokeColorDefault),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(l10n.waitingForGeneration, style: theme.typography.caption),
                    ),
                  )
                else
                  TextBox(
                     controller: TextEditingController(text: task.content),
                     maxLines: null,
                     readOnly: true,
                     decoration: WidgetStateProperty.all(BoxDecoration(
                       color: theme.resources.layerFillColorAlt,
                       borderRadius: BorderRadius.circular(4),
                     )),
                  ),
                if (task.reviewFeedback != null && task.reviewFeedback!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(l10n.reviewFeedback, style: theme.typography.bodyStrong),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(task.reviewFeedback!),
                  ),
                ],
                const SizedBox(height: 32),
                if (task.status == TaskStatus.reviewing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(
                        onPressed: () => notifier.updateTaskStatus(task.id, TaskStatus.failed),
                        child: Text('${l10n.reject} (${l10n.regenerate})', style: TextStyle(color: Colors.red.light)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => notifier.updateTaskStatus(task.id, TaskStatus.success),
                        child: Text(l10n.approve),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(TaskStatus status, FluentThemeData theme) {
    switch (status) {
      case TaskStatus.pending: return const Icon(FluentIcons.circle_ring, size: 16);
      case TaskStatus.decomposing:
      case TaskStatus.running:
      case TaskStatus.reviewing: return const SizedBox(width: 16, height: 16, child: ProgressRing(strokeWidth: 2));
      case TaskStatus.needsRevision: return Icon(FluentIcons.warning, size: 16, color: Colors.orange);
      case TaskStatus.success: return Icon(FluentIcons.completed, size: 16, color: Colors.green);
      case TaskStatus.failed: return Icon(FluentIcons.error_badge, size: 16, color: Colors.red);
      case TaskStatus.paused: return const Icon(FluentIcons.pause, size: 16);
    }
  }
  
  Color _getStatusColor(TaskStatus status, FluentThemeData theme) {
    switch (status) {
      case TaskStatus.pending: return theme.inactiveColor;
      case TaskStatus.decomposing:
      case TaskStatus.running: return Colors.blue;
      case TaskStatus.reviewing: return Colors.orange;
      case TaskStatus.needsRevision: return Colors.orange;
      case TaskStatus.success: return Colors.green;
      case TaskStatus.failed: return Colors.red;
      case TaskStatus.paused: return Colors.grey;
    }
  }

  String _getStatusLabel(TaskStatus status, AppLocalizations l10n) {
    switch (status) {
      case TaskStatus.pending: return l10n.pending;
      case TaskStatus.decomposing: return l10n.decomposing;
      case TaskStatus.running: return l10n.running;
      case TaskStatus.needsRevision: return '待重试';
      case TaskStatus.success: return l10n.success;
      case TaskStatus.failed: return l10n.failed;
      case TaskStatus.paused: return l10n.paused;
      case TaskStatus.reviewing: return l10n.reviewing;
    }
  }

  void _showNewProjectDialog(BuildContext context, AppLocalizations l10n, NovelNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => const CreateProjectDialog(),
    );
  }

  void _showNewChapterDialog(BuildContext context, AppLocalizations l10n, NovelNotifier notifier) async {
    final title = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.addChapter,
      hintText: l10n.chapterTitle,
    );
    if (title != null && title.trim().isNotEmpty) {
      notifier.addChapter(title.trim());
    }
  }

  void _showNewTaskDialog(BuildContext context, AppLocalizations l10n, NovelNotifier notifier, String chapterId) async {
    final task = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.createTask,
      hintText: l10n.taskDescription,
    );
    if (task != null && task.trim().isNotEmpty) {
      notifier.selectChapter(chapterId);
      notifier.addTask(task.trim());
    }
  }
}
