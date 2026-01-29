import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../novel/novel_provider.dart';
import '../novel/novel_state.dart';
import 'mobile_model_config_sheet.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/custom_toast.dart';
import '../../../../shared/widgets/aurora_bottom_sheet.dart';

class MobileNovelWritingPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MobileNovelWritingPage({super.key, this.onBack});

  @override
  ConsumerState<MobileNovelWritingPage> createState() => _MobileNovelWritingPageState();
}

class _MobileNovelWritingPageState extends ConsumerState<MobileNovelWritingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _taskInputController = TextEditingController();
  final _newProjectController = TextEditingController();
  final _newChapterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskInputController.dispose();
    _newProjectController.dispose();
    _newChapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(novelProvider);
    final notifier = ref.read(novelProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _buildProjectSelector(context, l10n, theme, state, notifier),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          if (state.allTasks.any((t) => t.status == TaskStatus.success || t.status == TaskStatus.failed))
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: '重新执行所有任务',
              onPressed: () async {
                final confirmed = await AuroraBottomSheet.showConfirm(
                  context: context,
                  title: '重新执行所有任务',
                  content: '确定要重置所有任务吗？\n这将清空已生成的内容，所有章节需要重新生成。',
                  confirmText: '重新执行',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  notifier.restartAllTasks();
                }
              },
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('审查', style: TextStyle(fontSize: 12)),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: state.isReviewEnabled,
                  onChanged: (v) => notifier.toggleReviewMode(v),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.createProject,
            onPressed: () => _showNewProjectDialog(context, l10n, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              AuroraBottomSheet.show(
                context: context,
                builder: (context) => const MobileModelConfigSheet(),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWritingView(context, l10n, theme, state, notifier),
          _buildContextView(context, l10n, theme, state, notifier),
          _buildPreviewView(context, l10n, theme, state, notifier),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: theme.primaryColor,
          tabs: [
            Tab(icon: const Icon(Icons.edit_outlined), text: l10n.writing),
            Tab(icon: const Icon(Icons.storage_outlined), text: l10n.context),
            Tab(icon: const Icon(Icons.description_outlined), text: l10n.preview),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 && state.selectedProject != null ? _buildFab(state, notifier, l10n) : null,
    );
  }

  Widget? _buildFab(NovelWritingState state, NovelNotifier notifier, AppLocalizations l10n) {
    if (state.isRunning) {
      return FloatingActionButton(
        onPressed: () => notifier.stopQueue(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else if (state.allTasks.any((t) => t.status == TaskStatus.pending)) {
      return FloatingActionButton(
        onPressed: () => notifier.startQueue(),
        child: const Icon(Icons.play_arrow),
      );
    }
    return null;
  }

  Widget _buildProjectSelector(BuildContext context, AppLocalizations l10n, ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    final projectName = state.selectedProject?.name ?? l10n.selectProject;
    return GestureDetector(
      onTap: () => _showProjectPicker(context, l10n, state, notifier),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              projectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  void _showProjectPicker(BuildContext context, AppLocalizations l10n, NovelWritingState state, NovelNotifier notifier) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AuroraBottomSheet.buildTitle(context, l10n.selectProject),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showNewProjectDialog(context, l10n, notifier);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final p = state.projects[index];
                return AuroraBottomSheet.buildListItem(
                  context: context,
                  title: Text(p.name),
                  selected: state.selectedProjectId == p.id,
                  onTap: () {
                    notifier.selectProject(p.id);
                    Navigator.pop(ctx);
                  },
                  trailing: state.selectedProjectId == p.id 
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteProjectConfirm(context, p, l10n, notifier, ctx),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectConfirm(BuildContext context, NovelProject project, AppLocalizations l10n, NovelNotifier notifier, BuildContext pickerCtx) async {
    final confirmed = await AuroraBottomSheet.showConfirm(
      context: context,
      title: l10n.deleteProject,
      content: l10n.deleteProjectConfirm,
      confirmText: l10n.delete,
      isDestructive: true,
    );
    if (confirmed == true) {
      notifier.deleteProject(project.id);
      if (context.mounted) Navigator.pop(pickerCtx);
    }
  }

  void _showNewProjectDialog(BuildContext context, AppLocalizations l10n, NovelNotifier notifier) async {
    final name = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.createProject,
      hintText: l10n.novelName,
    );
    if (name != null && name.isNotEmpty) {
      notifier.createProject(name);
    }
  }

  Widget _buildWritingView(BuildContext context, AppLocalizations l10n, ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) {
      return _buildNoProjectState(context, l10n, theme, notifier);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildOutlineSection(context, l10n, theme, state, notifier),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.chapters, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showNewChapterDialog(context, l10n, notifier),
                ),
              ],
            ),
          ),
        ),
        if (state.selectedProject?.chapters.isEmpty ?? true)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.noDataYet, style: TextStyle(color: theme.hintColor)),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = state.selectedProject!.chapters[index];
                final tasks = state.tasksForChapter(chapter.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildChapterItem(context, chapter, tasks, l10n, theme, notifier),
                );
              },
              childCount: state.selectedProject!.chapters.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildOutlineSection(BuildContext context, AppLocalizations l10n, ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    final outline = state.selectedProject?.outline ?? '';
    final hasOutline = outline.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !hasOutline,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Expanded(child: Text(l10n.outlineSettings, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (hasOutline)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                  onPressed: () => notifier.updateProjectOutline(''),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          leading: Icon(Icons.auto_stories, color: theme.primaryColor),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            hasOutline 
                ? Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: TextEditingController(text: outline),
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => notifier.updateProjectOutline(v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: state.isDecomposing ? null : () => _handleDecompose(context, l10n, state, notifier),
                          icon: state.isDecomposing 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(state.isDecomposing ? l10n.generating : l10n.generateChapters),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildOutlineEmptyState(theme, l10n, notifier, state),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineEmptyState(ThemeData theme, AppLocalizations l10n, NovelNotifier notifier, NovelWritingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _taskInputController,
          decoration: InputDecoration(
            hintText: l10n.outlinePlaceholder,
            hintStyle: TextStyle(color: theme.hintColor, fontSize: 13),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: state.isGeneratingOutline ? null : () {
            final text = _taskInputController.text.trim();
            if (text.isNotEmpty) {
              notifier.generateOutline(text);
              _taskInputController.clear();
            }
          },
          style: ElevatedButton.styleFrom(
             elevation: 0,
             backgroundColor: theme.primaryColor.withOpacity(0.1),
             foregroundColor: theme.primaryColor,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
             padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(state.isGeneratingOutline ? l10n.generating : l10n.generateOutline),
        ),
      ],
    );
  }

  void _handleDecompose(BuildContext context, AppLocalizations l10n, NovelWritingState state, NovelNotifier notifier) async {
    if (state.selectedProject?.chapters.isNotEmpty ?? false) {
      final confirmed = await AuroraBottomSheet.showConfirm(
        context: context,
        title: l10n.confirm,
        content: l10n.clearChaptersWarning,
        confirmText: l10n.confirm,
        isDestructive: true,
      );
      if (confirmed == true) {
        notifier.clearChaptersAndTasks();
        notifier.decomposeFromOutline();
      }
    } else {
      notifier.decomposeFromOutline();
    }
  }

  // Removed old _buildChaptersSection as it's now part of slivers in _buildWritingView

  Widget _buildChapterItem(BuildContext context, NovelChapter chapter, List<NovelTask> tasks, AppLocalizations l10n, ThemeData theme, NovelNotifier notifier) {
    final status = tasks.isEmpty ? TaskStatus.pending : tasks.first.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(chapter.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          leading: _getStatusIcon(status),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () => _showDeleteChapterConfirm(context, chapter, l10n, notifier),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (tasks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.taskDescription, style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(tasks.first.description, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tasks.first.content != null && tasks.first.content!.isNotEmpty) ...[
                    Text(l10n.preview, style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Text(tasks.first.content!, style: const TextStyle(height: 1.5)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (tasks.first.status == TaskStatus.reviewing) ...[
                        TextButton.icon(
                          onPressed: () => notifier.updateTaskStatus(tasks.first.id, TaskStatus.failed),
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          label: Text(l10n.reject, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => notifier.updateTaskStatus(tasks.first.id, TaskStatus.success),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(l10n.approve, style: const TextStyle(fontSize: 13)),
                        ),
                      ] else if (tasks.first.status == TaskStatus.pending || tasks.first.status == TaskStatus.failed) ...[
                        ElevatedButton.icon(
                          onPressed: () => notifier.runSingleTask(tasks.first.id),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: Text(l10n.executeTask, style: const TextStyle(fontSize: 13)),
                        ),
                      ] else if (tasks.first.status == TaskStatus.success) ...[
                        TextButton.icon(
                          onPressed: () => notifier.runSingleTask(tasks.first.id),
                          icon: const Icon(Icons.replay, size: 16),
                          label: Text(l10n.regenerate, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChapterConfirm(BuildContext context, NovelChapter chapter, AppLocalizations l10n, NovelNotifier notifier) async {
    final confirmed = await AuroraBottomSheet.showConfirm(
      context: context,
      title: l10n.confirm,
      content: l10n.deleteChapterConfirm,
      confirmText: l10n.delete,
      isDestructive: true,
    );
    if (confirmed == true) {
      notifier.deleteChapter(chapter.id);
    }
  }

  void _showNewChapterDialog(BuildContext context, AppLocalizations l10n, NovelNotifier notifier) async {
    final title = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.addChapter,
      hintText: l10n.chapterTitle,
    );
    if (title != null && title.isNotEmpty) {
      notifier.addChapter(title);
    }
  }

  Widget _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending: return const Icon(Icons.circle_outlined, color: Colors.grey, size: 20);
      case TaskStatus.running: return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
      case TaskStatus.success: return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case TaskStatus.failed: return const Icon(Icons.error_outline, color: Colors.red, size: 20);
      case TaskStatus.paused: return const Icon(Icons.pause_circle_outline, color: Colors.orange, size: 20);
      case TaskStatus.reviewing: return const Icon(Icons.rate_review_outlined, color: Colors.blue, size: 20);
      case TaskStatus.needsRevision: return const Icon(Icons.warning_amber, color: Colors.orange, size: 20);
      case TaskStatus.decomposing: return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple));
    }
  }

  Widget _buildContextView(BuildContext context, AppLocalizations l10n, ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) return _buildNoProjectState(context, l10n, theme, notifier);
    
    final ctx = state.selectedProject!.worldContext;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text(l10n.worldRules),
              selected: ctx.includeRules,
              onSelected: (v) => notifier.toggleContextCategory('rules', v),
            ),
            FilterChip(
              label: Text(l10n.characterSettings),
              selected: ctx.includeCharacters,
              onSelected: (v) => notifier.toggleContextCategory('characters', v),
            ),
            FilterChip(
              label: Text(l10n.relationships),
              selected: ctx.includeRelationships,
              onSelected: (v) => notifier.toggleContextCategory('relationships', v),
            ),
            FilterChip(
              label: Text(l10n.locations),
              selected: ctx.includeLocations,
              onSelected: (v) => notifier.toggleContextCategory('locations', v),
            ),
            FilterChip(
              label: Text(l10n.foreshadowing),
              selected: ctx.includeForeshadowing,
              onSelected: (v) => notifier.toggleContextCategory('foreshadowing', v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildContextSection(l10n.worldRules, ctx.rules, theme, l10n),
        _buildContextSection(l10n.characterSettings, ctx.characters, theme, l10n),
        _buildContextSection(l10n.relationships, ctx.relationships, theme, l10n),
        _buildContextSection(l10n.locations, ctx.locations, theme, l10n),
        _buildForeshadowingSection(ctx.foreshadowing, theme, l10n),
      ],
    );
  }

  Widget _buildContextSection(String title, Map<String, String> data, ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (data.isEmpty)
          Text(l10n.noDataYet, style: theme.textTheme.bodySmall)
        else
          ...data.entries.map((e) => ListTile(
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(e.value),
            dense: true,
          )),
        const Divider(),
      ],
    );
  }

  Widget _buildForeshadowingSection(List<String> data, ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(l10n.foreshadowing, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (data.isEmpty)
          Text(l10n.noDataYet, style: theme.textTheme.bodySmall)
        else
          ...data.map((f) => ListTile(
            title: Text(f),
            dense: true,
            leading: const Icon(Icons.flag_outlined, size: 16),
          )),
        const Divider(),
      ],
    );
  }

  Widget _buildPreviewView(BuildContext context, AppLocalizations l10n, ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) return _buildNoProjectState(context, l10n, theme, notifier);
    final content = notifier.exportFullNovel();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${state.selectedProject?.name} - ${l10n.preview}',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (content.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: content));
                    showTopToast(context, '已复制到剪贴板');
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content.isEmpty ? l10n.noContentYet : content,
              style: const TextStyle(height: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoProjectState(BuildContext context, AppLocalizations l10n, ThemeData theme, NovelNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: theme.primaryColor.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noProjectSelected,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createProjectDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showNewProjectDialog(context, l10n, notifier),
              icon: const Icon(Icons.add),
              label: Text(l10n.createProject),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
