import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/features/knowledge/domain/knowledge_models.dart';
import 'package:aurora/shared/widgets/aurora_card.dart';
import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import '../novel/novel_provider.dart';
import '../novel/novel_state.dart';
import 'mobile_model_config_sheet.dart';
import 'package:flutter/services.dart';
import '../../../../shared/widgets/aurora_bottom_sheet.dart';
import '../../../../shared/widgets/aurora_notice.dart';

class MobileNovelWritingPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MobileNovelWritingPage({super.key, this.onBack});

  @override
  ConsumerState<MobileNovelWritingPage> createState() =>
      _MobileNovelWritingPageState();
}

class _MobileNovelWritingPageState extends ConsumerState<MobileNovelWritingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _taskInputController = TextEditingController();
  final _outlineController = TextEditingController();
  final _styleSampleController = TextEditingController();
  bool _isProjectKnowledgeBusy = false;
  int _projectKnowledgeRefreshToken = 0;
  String? _boundOutlineProjectId;
  bool _isSyncingOutlineText = false;
  String? _boundStyleSampleProjectId;
  bool _isSyncingStyleSampleText = false;

  static const double _cardRadius = 16;
  static const double _controlRadius = 12;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskInputController.dispose();
    _outlineController.dispose();
    _styleSampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(novelProvider);
    final notifier = ref.read(novelProvider.notifier);
    _syncOutlineController(state);
    _syncStyleSampleController(state);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _buildProjectSelector(context, l10n, theme, state, notifier),
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(AuroraIcons.back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          if (state.allTasks.any((t) =>
              t.status == TaskStatus.success || t.status == TaskStatus.failed))
            IconButton(
              icon: const Icon(AuroraIcons.refresh, size: 20),
              tooltip: l10n.restartAllTasksTooltip,
              onPressed: () async {
                final confirmed = await AuroraBottomSheet.showConfirm(
                  context: context,
                  title: l10n.restartAllTasksTitle,
                  content: l10n.restartAllTasksConfirm,
                  confirmText: l10n.restartAllTasksAction,
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
              Text(l10n.reviewModel, style: const TextStyle(fontSize: 12)),
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
            icon: const Icon(AuroraIcons.add),
            tooltip: l10n.createProject,
            onPressed: () => _showNewProjectDialog(context, l10n, notifier),
          ),
          IconButton(
            icon: const Icon(AuroraIcons.settings),
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
          border: Border(
              top:
                  BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: theme.primaryColor,
          tabs: [
            Tab(icon: const Icon(AuroraIcons.edit), text: l10n.writing),
            Tab(icon: const Icon(AuroraIcons.database), text: l10n.context),
            Tab(icon: const Icon(AuroraIcons.file), text: l10n.preview),
          ],
        ),
      ),
      floatingActionButton:
          _tabController.index == 0 && state.selectedProject != null
              ? _buildFab(state, notifier, l10n)
              : null,
    );
  }

  Widget? _buildFab(
      NovelWritingState state, NovelNotifier notifier, AppLocalizations l10n) {
    if (state.isRunning) {
      return FloatingActionButton(
        onPressed: () => notifier.stopQueue(),
        backgroundColor: Colors.red,
        child: const Icon(AuroraIcons.stop),
      );
    } else if (notifier.hasRunnableTasksInSelectedProject()) {
      return FloatingActionButton(
        onPressed: () => notifier.startQueue(),
        child: const Icon(AuroraIcons.play),
      );
    }
    return null;
  }

  Widget _buildProjectSelector(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
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
          const Icon(AuroraIcons.chevronDown),
        ],
      ),
    );
  }

  void _syncOutlineController(NovelWritingState state) {
    final projectId = state.selectedProjectId;
    final outline = state.selectedProject?.outline ?? '';
    if (_boundOutlineProjectId == projectId &&
        _outlineController.text == outline) {
      return;
    }

    _boundOutlineProjectId = projectId;
    _isSyncingOutlineText = true;
    _outlineController.value = TextEditingValue(
      text: outline,
      selection: TextSelection.collapsed(offset: outline.length),
    );
    _isSyncingOutlineText = false;
  }

  void _syncStyleSampleController(NovelWritingState state) {
    final projectId = state.selectedProjectId;
    final sample = state.selectedProject?.styleSample ?? '';
    if (_boundStyleSampleProjectId == projectId &&
        _styleSampleController.text == sample) {
      return;
    }

    _boundStyleSampleProjectId = projectId;
    _isSyncingStyleSampleText = true;
    _styleSampleController.value = TextEditingValue(
      text: sample,
      selection: TextSelection.collapsed(offset: sample.length),
    );
    _isSyncingStyleSampleText = false;
  }

  void _showProjectPicker(BuildContext context, AppLocalizations l10n,
      NovelWritingState state, NovelNotifier notifier) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(
            context,
            l10n.selectProject,
            trailing: IconButton(
              icon: const Icon(AuroraIcons.add, size: 20),
              onPressed: () {
                Navigator.pop(ctx);
                _showNewProjectDialog(context, l10n, notifier);
              },
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
                  title: Text(p.name, style: const TextStyle(fontSize: 15)),
                  selected: state.selectedProjectId == p.id,
                  onTap: () {
                    notifier.selectProject(p.id);
                    Navigator.pop(ctx);
                  },
                  trailing: state.selectedProjectId == p.id
                      ? IconButton(
                          icon: const Icon(AuroraIcons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => _showDeleteProjectConfirm(
                              context, p, l10n, notifier, ctx),
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

  void _showDeleteProjectConfirm(
      BuildContext context,
      NovelProject project,
      AppLocalizations l10n,
      NovelNotifier notifier,
      BuildContext pickerCtx) async {
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

  void _showNewProjectDialog(BuildContext context, AppLocalizations l10n,
      NovelNotifier notifier) async {
    final name = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.createProject,
      hintText: l10n.novelName,
    );
    if (name != null && name.isNotEmpty) {
      notifier.createProject(name);
    }
  }

  Widget _buildWritingView(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child:
                _buildStyleImitationCard(context, l10n, theme, state, notifier),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.chapters,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(AuroraIcons.add),
                  onPressed: () =>
                      _showNewChapterDialog(context, l10n, notifier),
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
                child: Text(l10n.noDataYet,
                    style: TextStyle(color: theme.hintColor)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildChapterItem(
                    context,
                    chapter,
                    tasks,
                    l10n,
                    theme,
                    notifier,
                    state.isRunning,
                  ),
                );
              },
              childCount: state.selectedProject!.chapters.length,
            ),
          ),
        const SliverToBoxAdapter(
            child: SizedBox(height: 80)), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildOutlineSection(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    final outline = state.selectedProject?.outline ?? '';
    final hasOutline = outline.isNotEmpty;
    final hasStoredRequirement =
        state.selectedProject?.outlineRequirement?.trim().isNotEmpty ?? false;
    final decomposeStatus = state.decomposeStatus?.trim() ?? '';

    return AuroraCard(
      borderRadius: _cardRadius,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !hasOutline,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              Expanded(
                  child: Text(l10n.outlineSettings,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              if (hasOutline)
                IconButton(
                  icon: const Icon(AuroraIcons.delete,
                      size: 20, color: Colors.grey),
                  onPressed: () => notifier.updateProjectOutline(''),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          leading: Icon(AuroraIcons.book, color: theme.primaryColor),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            hasOutline
                ? Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(_controlRadius),
                        ),
                        child: TextField(
                          controller: _outlineController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) {
                            if (_isSyncingOutlineText) return;
                            notifier.updateProjectOutline(v);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (state.isGeneratingOutline ||
                                      state.isDecomposing ||
                                      !hasStoredRequirement)
                                  ? null
                                  : () => notifier.rerunOutline(),
                              icon: state.isGeneratingOutline
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(AuroraIcons.refresh, size: 16),
                              label: Text(state.isGeneratingOutline
                                  ? l10n.generating
                                  : l10n.rerunOutline),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(_controlRadius)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: (state.isDecomposing ||
                                      state.isGeneratingOutline)
                                  ? null
                                  : () => _handleDecompose(
                                      context, l10n, state, notifier),
                              icon: state.isDecomposing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(AuroraIcons.autoAwesome,
                                      size: 18),
                              label: Text(state.isDecomposing
                                  ? l10n.generating
                                  : l10n.generateChapters),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(_controlRadius)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (decomposeStatus.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(_controlRadius),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            state.decomposeTotalBatches > 0 &&
                                    state.isDecomposing
                                ? '$decomposeStatus\n批次进度：${state.decomposeCurrentBatch}/${state.decomposeTotalBatches}'
                                : decomposeStatus,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  )
                : _buildOutlineEmptyState(theme, l10n, notifier, state),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineEmptyState(ThemeData theme, AppLocalizations l10n,
      NovelNotifier notifier, NovelWritingState state) {
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
              borderRadius: BorderRadius.circular(_controlRadius),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isGeneratingOutline
              ? null
              : () {
                  final text = _taskInputController.text.trim();
                  if (text.isNotEmpty) {
                    notifier.generateOutline(text);
                    _taskInputController.clear();
                  }
                },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_controlRadius),
            ),
          ),
          child: Text(state.isGeneratingOutline
              ? l10n.generating
              : l10n.generateOutline),
        ),
      ],
    );
  }

  void _handleDecompose(BuildContext context, AppLocalizations l10n,
      NovelWritingState state, NovelNotifier notifier) async {
    if (state.selectedProject?.chapters.isNotEmpty ?? false) {
      final confirmed = await AuroraBottomSheet.showConfirm(
        context: context,
        title: l10n.regenerateChapterOutlineTitle,
        content: l10n.regenerateChapterOutlineConfirm,
        confirmText: l10n.continueGenerate,
        isDestructive: false,
      );
      if (confirmed == true) {
        notifier.decomposeFromOutline();
      }
    } else {
      notifier.decomposeFromOutline();
    }
  }

  // Removed old _buildChaptersSection as it's now part of slivers in _buildWritingView

  Widget _buildChapterItem(
      BuildContext context,
      NovelChapter chapter,
      List<NovelTask> tasks,
      AppLocalizations l10n,
      ThemeData theme,
      NovelNotifier notifier,
      bool isQueueRunning) {
    final status = tasks.isEmpty ? TaskStatus.pending : tasks.first.status;
    return AuroraCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: _cardRadius,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(chapter.title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          leading: _getStatusIcon(status),
          trailing: IconButton(
            icon: const Icon(AuroraIcons.delete, size: 18, color: Colors.grey),
            onPressed: () =>
                _showDeleteChapterConfirm(context, chapter, l10n, notifier),
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
                      borderRadius: BorderRadius.circular(_controlRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.taskDescription,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.hintColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(tasks.first.description,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tasks.first.content != null &&
                      tasks.first.content!.isNotEmpty) ...[
                    Text(l10n.preview,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(_controlRadius),
                        border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.1)),
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Text(tasks.first.content!,
                            style: const TextStyle(height: 1.5)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (tasks.first.status == TaskStatus.reviewing) ...[
                        OutlinedButton.icon(
                          onPressed: isQueueRunning
                              ? null
                              : () => notifier.runSingleTask(tasks.first.id),
                          icon: const Icon(AuroraIcons.close, size: 16),
                          label: Text(l10n.reject,
                              style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_controlRadius),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: isQueueRunning
                              ? null
                              : () => notifier.approveTask(tasks.first.id),
                          icon: const Icon(AuroraIcons.check, size: 16),
                          label: Text(l10n.approve,
                              style: const TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_controlRadius),
                            ),
                          ),
                        ),
                      ] else if (tasks.first.status == TaskStatus.pending ||
                          tasks.first.status == TaskStatus.failed) ...[
                        FilledButton.icon(
                          onPressed: isQueueRunning
                              ? null
                              : () => notifier.runSingleTask(tasks.first.id),
                          icon: const Icon(AuroraIcons.play, size: 16),
                          label: Text(l10n.executeTask,
                              style: const TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_controlRadius),
                            ),
                          ),
                        ),
                      ] else if (tasks.first.status == TaskStatus.success) ...[
                        OutlinedButton.icon(
                          onPressed: isQueueRunning
                              ? null
                              : () => notifier.runSingleTask(tasks.first.id),
                          icon: const Icon(AuroraIcons.retry, size: 16),
                          label: Text(l10n.regenerate,
                              style: const TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_controlRadius),
                            ),
                          ),
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

  void _showDeleteChapterConfirm(BuildContext context, NovelChapter chapter,
      AppLocalizations l10n, NovelNotifier notifier) async {
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

  void _showNewChapterDialog(BuildContext context, AppLocalizations l10n,
      NovelNotifier notifier) async {
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
      case TaskStatus.pending:
        return const Icon(AuroraIcons.pending, color: Colors.grey, size: 20);
      case TaskStatus.running:
        return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2));
      case TaskStatus.success:
        return const Icon(AuroraIcons.success, color: Colors.green, size: 20);
      case TaskStatus.failed:
        return const Icon(AuroraIcons.error, color: Colors.red, size: 20);
      case TaskStatus.paused:
        return const Icon(AuroraIcons.pausedCircle,
            color: Colors.orange, size: 20);
      case TaskStatus.reviewing:
        return const Icon(AuroraIcons.reviewing, color: Colors.blue, size: 20);
      case TaskStatus.needsRevision:
        return const Icon(AuroraIcons.warning, color: Colors.orange, size: 20);
      case TaskStatus.decomposing:
        return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.purple));
    }
  }

  Widget _buildContextView(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) {
      return _buildNoProjectState(context, l10n, theme, notifier);
    }

    final ctx = state.selectedProject!.worldContext;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProjectKnowledgeCard(context, l10n, theme, state, notifier),
        const SizedBox(height: 16),
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
              onSelected: (v) =>
                  notifier.toggleContextCategory('characters', v),
            ),
            FilterChip(
              label: Text(l10n.relationships),
              selected: ctx.includeRelationships,
              onSelected: (v) =>
                  notifier.toggleContextCategory('relationships', v),
            ),
            FilterChip(
              label: Text(l10n.locations),
              selected: ctx.includeLocations,
              onSelected: (v) => notifier.toggleContextCategory('locations', v),
            ),
            FilterChip(
              label: Text(l10n.foreshadowing),
              selected: ctx.includeForeshadowing,
              onSelected: (v) =>
                  notifier.toggleContextCategory('foreshadowing', v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildContextSection(l10n.worldRules, ctx.rules, theme, l10n),
        const SizedBox(height: 12),
        _buildContextSection(
            l10n.characterSettings, ctx.characters, theme, l10n),
        const SizedBox(height: 12),
        _buildContextSection(
            l10n.relationships, ctx.relationships, theme, l10n),
        const SizedBox(height: 12),
        _buildContextSection(l10n.locations, ctx.locations, theme, l10n),
        const SizedBox(height: 12),
        _buildForeshadowingSection(ctx.foreshadowing, theme, l10n),
      ],
    );
  }

  Widget _buildStyleImitationCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    NovelWritingState state,
    NovelNotifier notifier,
  ) {
    final project = state.selectedProject;
    if (project == null) return const SizedBox.shrink();

    final hasAnalysis = (project.analyzedStyle ?? '').trim().isNotEmpty;
    final hasSample = (project.styleSample ?? '').trim().isNotEmpty;

    return AuroraCard(
      borderRadius: _cardRadius,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasAnalysis || hasSample,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(AuroraIcons.autoAwesome, size: 20),
          title: Row(
            children: [
              Text(l10n.styleImitation),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasAnalysis
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.hintColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasAnalysis ? l10n.styleAnalyzed : l10n.styleNotAnalyzed,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasAnalysis ? Colors.green : theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.styleSampleHint,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _styleSampleController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: l10n.styleSamplePlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_controlRadius),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                if (_isSyncingStyleSampleText) return;
                notifier.updateStyleSample(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isAnalyzingStyle || !hasSample
                        ? null
                        : () async {
                            try {
                              await notifier.analyzeWritingStyle();
                            } catch (e) {
                              if (!context.mounted) return;
                              showAuroraNotice(
                                context,
                                e.toString(),
                                icon: AuroraIcons.error,
                              );
                            }
                          },
                    icon: state.isAnalyzingStyle
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(AuroraIcons.autoAwesome, size: 18),
                    label: Text(
                      state.isAnalyzingStyle
                          ? l10n.analyzingStyle
                          : l10n.analyzeStyle,
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_controlRadius),
                      ),
                    ),
                  ),
                ),
                if (hasSample || hasAnalysis) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: state.isAnalyzingStyle
                        ? null
                        : () async {
                            final confirmed =
                                await AuroraBottomSheet.showConfirm(
                              context: context,
                              title: l10n.clearStyle,
                              content: l10n.clearStyleConfirm,
                              confirmText: l10n.clear,
                              isDestructive: true,
                            );
                            if (confirmed == true) {
                              notifier.clearStyleSample();
                            }
                          },
                    icon: const Icon(AuroraIcons.delete, size: 16),
                    label: Text(l10n.clearStyle),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_controlRadius),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (hasAnalysis) ...[
              const SizedBox(height: 16),
              Text(
                l10n.styleAnalysisResult,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(_controlRadius),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: SelectableText(
                  project.analyzedStyle!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContextSection(String title, Map<String, String> data,
      ThemeData theme, AppLocalizations l10n) {
    return AuroraCard(
      borderRadius: _cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Text(l10n.noDataYet, style: theme.textTheme.bodySmall)
          else
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectKnowledgeCard(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    final projectOnlyHint = l10n.projectOnlyKnowledgeBaseHint;
    final importingLabel = l10n.importingEllipsis;

    return AuroraCard(
      borderRadius: _cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AuroraIcons.database, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.knowledgeBase,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(AuroraIcons.refresh, size: 18),
                onPressed: _isProjectKnowledgeBusy
                    ? null
                    : () => setState(() => _projectKnowledgeRefreshToken++),
              ),
            ],
          ),
          Text(
            projectOnlyHint,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FutureBuilder<KnowledgeBaseSummary?>(
            key: ValueKey(
              '${state.selectedProjectId}-${state.selectedProject?.knowledgeBaseId}-$_projectKnowledgeRefreshToken',
            ),
            future: notifier.getSelectedProjectKnowledgeBaseSummary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: theme.colorScheme.error),
                );
              }

              final summary = snapshot.data;
              if (summary == null) {
                return Text(l10n.noDataYet, style: theme.textTheme.bodySmall);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.knowledgeDocsAndChunks(
                      summary.documentCount,
                      summary.chunkCount,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProjectKnowledgeBusy
                  ? null
                  : () => _importProjectKnowledgeFiles(context, l10n, notifier),
              icon: const Icon(AuroraIcons.backup, size: 16),
              label: Text(l10n.importFiles),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_controlRadius),
                ),
              ),
            ),
          ),
          if (_isProjectKnowledgeBusy) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(importingLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importProjectKnowledgeFiles(BuildContext context,
      AppLocalizations l10n, NovelNotifier notifier) async {
    final typeGroup = XTypeGroup(
      label: l10n.knowledgeFiles,
      extensions: ['txt', 'md', 'csv', 'json', 'xml', 'yaml', 'yml', 'docx'],
    );

    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;

    setState(() {
      _isProjectKnowledgeBusy = true;
    });

    try {
      final report = await notifier.importKnowledgeFilesForSelectedProject(
        files.map((f) => f.path).toList(growable: false),
      );
      if (!context.mounted) return;

      if (report == null) {
        showAuroraNotice(context, l10n.noDataYet, icon: AuroraIcons.info);
        return;
      }

      final summary = StringBuffer()
        ..write(l10n.knowledgeImportSummary(
            report.successCount, report.failureCount));
      if (report.errors.isNotEmpty) {
        summary
          ..writeln()
          ..writeln()
          ..write(report.errors.join('\n'));
      }

      await AuroraBottomSheet.show(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.importFinished,
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: SelectableText(summary.toString()),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showAuroraNotice(context, e.toString(), icon: AuroraIcons.error);
    } finally {
      if (mounted) {
        setState(() {
          _isProjectKnowledgeBusy = false;
          _projectKnowledgeRefreshToken++;
        });
      }
    }
  }

  Widget _buildForeshadowingSection(
      List<String> data, ThemeData theme, AppLocalizations l10n) {
    return AuroraCard(
      borderRadius: _cardRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.foreshadowing,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Text(l10n.noDataYet, style: theme.textTheme.bodySmall)
          else
            ...data.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(AuroraIcons.flag, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewView(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelWritingState state, NovelNotifier notifier) {
    if (state.selectedProject == null) {
      return _buildNoProjectState(context, l10n, theme, notifier);
    }
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
                icon: const Icon(AuroraIcons.copy),
                onPressed: () {
                  if (content.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: content));
                    showAuroraNotice(
                      context,
                      l10n.contentCopied,
                      icon: AuroraIcons.copy,
                      top: MediaQuery.of(context).padding.top + 64 + 60,
                    );
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

  Widget _buildNoProjectState(BuildContext context, AppLocalizations l10n,
      ThemeData theme, NovelNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AuroraIcons.bookOpen,
              size: 80,
              color: theme.primaryColor.withValues(alpha: 0.2),
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
            FilledButton.icon(
              onPressed: () => _showNewProjectDialog(context, l10n, notifier),
              icon: const Icon(AuroraIcons.add),
              label: Text(l10n.createProject),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_controlRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

