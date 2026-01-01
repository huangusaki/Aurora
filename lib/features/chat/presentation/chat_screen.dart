import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/message.dart';
import 'chat_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:window_manager/window_manager.dart';
import '../../settings/presentation/settings_content.dart'; 
import '../../settings/presentation/settings_provider.dart';
import '../../settings/presentation/mobile_settings_page.dart';
import '../../settings/presentation/mobile_user_page.dart';
import 'mobile_translation_page.dart';
import '../../history/presentation/history_content.dart';
import 'widgets/reasoning_display.dart';
import 'widgets/chat_image_bubble.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:flutter/services.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isWindows = !kIsWeb && Platform.isWindows;
    final isMobile = !isWindows;
    
    if (isMobile) {
      return _buildMobileLayout(context);
    }
    
    // --- Windows Layout (NavigationView) ---
    final theme = fluent.FluentTheme.of(context);
    
    final List<fluent.NavigationPaneItem> items = [
      fluent.PaneItem(
        icon: const Icon(fluent.FluentIcons.history),
        title: const Text('历史'),
        body: const SizedBox.shrink(),
      ),
      fluent.PaneItem(
        icon: const Icon(fluent.FluentIcons.translate),
        title: const Text('翻译'),
        body: const SizedBox.shrink(),
      ),
      fluent.PaneItem(
        icon: const Icon(fluent.FluentIcons.settings),
        title: const Text('设置'),
        body: const SizedBox.shrink(),
      ),
    ];

    return fluent.NavigationView(
      appBar: fluent.NavigationAppBar(
        automaticallyImplyLeading: false,
        title: () {
          final titleWidget = const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text('Aurora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          );
          return DragToMoveArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: titleWidget,
            ),
          );
        }(),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ModelSelector(isWindows: true), 
            const _WindowButtons(),
          ],
        ),
      ),
      pane: fluent.NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) {
          if (index == 0) {
             if (_selectedIndex == 0) {
                ref.read(isHistorySidebarVisibleProvider.notifier).update((state) => !state);
             } else {
                ref.read(isHistorySidebarVisibleProvider.notifier).state = true;
             }
          }
          setState(() => _selectedIndex = index);
        },
        displayMode: fluent.PaneDisplayMode.auto, 
        size: const fluent.NavigationPaneSize(openWidth: 200),
        items: items,
        footerItems: [
           fluent.PaneItemAction(
             icon: Consumer(builder: (_, ref, __) {
                final mode = ref.watch(settingsProvider).themeMode;
                final isDark = mode == 'dark' || (mode == 'system' && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                return Icon(isDark ? fluent.FluentIcons.clear_night : fluent.FluentIcons.sunny);
             }),
             title: const Text('切换主题'),
             onTap: () {
               ref.read(settingsProvider.notifier).toggleThemeMode();
             },
           ),
        ],
      ),
      content: IndexedStack(
        index: _selectedIndex,
        children: const [
           HistoryContent(),
           _TranslationContent(),
           SettingsContent(),
        ],
      ),
    );
  }

  // --- Mobile Chat-First Layout ---
  Widget _buildMobileLayout(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);
    
    // Determine session title
    String sessionTitle = '新对话';
    if (selectedSessionId != null && selectedSessionId != 'new_chat' && sessionsState.sessions.isNotEmpty) {
      final sessionMatch = sessionsState.sessions.where((s) => s.sessionId == selectedSessionId);
      if (sessionMatch.isNotEmpty) {
        sessionTitle = sessionMatch.first.title;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: !isDark,
      backgroundColor: isDark ? fluent.FluentTheme.of(context).scaffoldBackgroundColor : Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent, // No Material 3 tint
        elevation: 0,
        toolbarHeight: 64, // Taller for mobile
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 26),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openModelSwitcher,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sessionTitle,
                      style: TextStyle(
                        fontSize: 18, // Larger
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            settingsState.selectedModel ?? '未选择模型',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: '新对话',
            onPressed: () {
              ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: fluent.FluentTheme.of(context).scaffoldBackgroundColor, // Solid background from FluentTheme
        child: SafeArea(
          child: Column(
            children: [
              // Search bar area (functional)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            ref.read(sessionSearchQueryProvider.notifier).state = value;
                          },
                          decoration: InputDecoration(
                            hintText: '搜索聊天记录',
                            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                            prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () {
                        ref.read(sessionSearchQueryProvider.notifier).state = '';
                      },
                    ),
                  ],
                ),
              ),
              
              // "New Chat" Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: InkWell(
                  onTap: () {
                    ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Text('新对话', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Session List
              Expanded(
                child: SessionListWidget(
                  sessionsState: sessionsState,
                  selectedSessionId: selectedSessionId,
                  onSessionSelected: (sessionId) {
                    ref.read(selectedHistorySessionIdProvider.notifier).state = sessionId;
                    Navigator.pop(context);
                  },
                  onSessionDeleted: (sessionId) {
                    ref.read(sessionsProvider.notifier).deleteSession(sessionId);
                    if (sessionId == selectedSessionId) {
                      ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
                    }
                  },
                ),
              ),
              
              // Bottom Navigation Grid (2 rows x 3 columns)
              Container(
                decoration: BoxDecoration(
                  color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: 用户 翻译 主题
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MobileDrawerNavItem(
                            icon: Icons.person_outline,
                            label: '用户',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileUserPage()));
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: Icons.translate,
                            label: '翻译',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTranslationPage()));
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: _getThemeIcon(ref.watch(settingsProvider).themeMode),
                            label: '主题',
                            onTap: () {
                              _cycleTheme();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 2: 供应商 其它 关于
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MobileDrawerNavItem(
                            icon: Icons.cloud_outlined,
                            label: '模型',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileSettingsPage()));
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: Icons.link_outlined,
                            label: '其它',
                            onTap: () {
                              // Placeholder for future GitHub, project info etc
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('敬请期待'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: Icons.info_outline,
                            label: '关于',
                            onTap: () {
                              Navigator.pop(context);
                              _showAboutDialog();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: !isDark ? const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9)],
          ),
        ) : null,
        child: Padding(
          padding: EdgeInsets.only(top: !isDark ? 64 + MediaQuery.of(context).padding.top : 0),
          child: const MobileChatBody(),
        ),
      ),
    );
  }

  void _openModelSwitcher() {
    final settingsState = ref.read(settingsProvider);
    final provider = settingsState.activeProvider;
    if (provider == null || provider.models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置模型')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('选择模型', style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.models.length,
                  itemBuilder: (context, index) {
                    final model = provider.models[index];
                    final isSelected = model == settingsState.selectedModel;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(model),
                      onTap: () {
                        ref.read(settingsProvider.notifier).updateProvider(
                          id: provider.id,
                          selectedModel: model,
                        );
                        ref.read(settingsProvider.notifier).selectProvider(provider.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getThemeIcon(String themeMode) {
    switch (themeMode) {
      case 'dark':
        return Icons.dark_mode;
      case 'light':
        return Icons.light_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  void _cycleTheme() {
    final current = ref.read(settingsProvider).themeMode;
    String next;
    switch (current) {
      case 'system':
        next = 'light';
        break;
      case 'light':
        next = 'dark';
        break;
      default:
        next = 'system';
    }
    ref.read(settingsProvider.notifier).setThemeMode(next);
    
    final message = next == 'light' ? '浅色模式' : (next == 'dark' ? '深色模式' : '跟随系统');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到$message'), duration: const Duration(seconds: 1)),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Aurora'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: v1.0.0'),
            SizedBox(height: 8),
            Text('一款优雅的跨平台 AI 对话助手'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// Mobile drawer bottom navigation item
class _MobileDrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MobileDrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TranslationContent extends ConsumerStatefulWidget {
  const _TranslationContent();

  @override
  ConsumerState<_TranslationContent> createState() => __TranslationContentState();
}

class __TranslationContentState extends ConsumerState<_TranslationContent> {
  final TextEditingController _sourceController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  String _sourceLang = '自动检测';
  String _targetLang = '简体中文';
  bool _showComparison = true;
  bool _hasRestored = false; // Track if we have restored history
  
  // Resizable Split View State
  double _leftRatio = 0.5; // 0.0 to 1.0
  
  final List<String> _sourceLanguages = ['自动检测', '英语', '日语', '韩语', '简体中文', '繁体中文', '俄语', '法语', '德语'];
  final List<String> _targetLanguages = ['简体中文', '英语', '日语', '韩语', '繁体中文', '俄语', '法语', '德语'];

  @override
  void initState() {
    super.initState();
    // Proactive check (in case data is already there from tab switch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryRestore();
    });
  }

  void _tryRestore() {
    if (_hasRestored) return;
    final chatState = ref.read(translationProvider);
    if (chatState.messages.isNotEmpty) {
       // Find last user message
       final lastUserMsg = chatState.messages.lastWhere(
         (m) => m.isUser, 
         orElse: () => Message(content: '', isUser: true, id: '', timestamp: DateTime.now())
       );
       
       if (lastUserMsg.content.isNotEmpty) {
         _sourceController.text = lastUserMsg.content;
       }
       _hasRestored = true;
       // No setState needed if called during build via listen, but usually safer to just let controller notify listeners
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _translate() {
    if (_sourceController.text.trim().isEmpty) return;
    
    // Clear previous results
    final notifier = ref.read(translationProvider.notifier);
    notifier.clearContext().then((_) {
      // Construct Prompt (API Content)
      final sb = StringBuffer();
      sb.writeln('你是一位精通多国语言的专业翻译专家。请将以下${_sourceLang == '自动检测' ? '' : _sourceLang}文本翻译成$_targetLang。');
      sb.writeln('要求：');
      sb.writeln('1. 翻译准确、地道，符合目标语言的表达习惯。');
      sb.writeln('2. 严格保留原文的换行格式和段落结构，不要合并段落。');
      sb.writeln('3. 只输出翻译后的内容，不要包含任何解释、前言或后缀。');
      sb.writeln('');
      sb.writeln('原文内容：');
      sb.writeln(_sourceController.text);
      
      // Send message: 
      // 1. First arg is 'text' (Saved to DB/State -> Displayed to User)
      // 2. apiContent is the 'Prompt' (Sent to LLM)
      notifier.sendMessage(_sourceController.text, apiContent: sb.toString());
    });
  }

  Widget _buildSourceInput(fluent.FluentThemeData theme, bool isWindows) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              fluent.Text('原文', style: TextStyle(color: theme.resources.textFillColorSecondary)),
              if (_sourceController.text.isNotEmpty)
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.clear),
                  onPressed: () => _sourceController.clear(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: fluent.TextBox(
              controller: _sourceController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              placeholder: '在此输入要翻译的文本...',
              decoration: null,
              highlightColor: Colors.transparent,
              unfocusedColor: Colors.transparent,
              style: TextStyle(
                fontSize: 16, 
                height: 1.5, 
                fontFamily: isWindows ? 'Microsoft YaHei' : null,
                color: theme.typography.body?.color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetOutput(fluent.FluentThemeData theme, bool isWindows, ChatState chatState, Message? aiMessage) {
    return Container(
      padding: const EdgeInsets.all(0),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 fluent.Text(_showComparison ? '双语对照' : '译文', style: TextStyle(color: theme.resources.textFillColorSecondary)),
                 fluent.IconButton(
                   icon: const Icon(fluent.FluentIcons.copy),
                   onPressed: () {
                     final text = aiMessage?.content;
                     if (text != null && text.isNotEmpty) {
                        final item = DataWriterItem();
                        item.add(Formats.plainText(text));
                        SystemClipboard.instance?.write([item]);
                     }
                   },
                 ),
              ],
            ),
          ),
          Container(height: 1, color: theme.resources.dividerStrokeColorDefault),
          Expanded(
            child: Builder(
              builder: (context) {
                if (aiMessage == null && !chatState.isLoading) {
                   return const Center(child: Text('翻译结果将显示在这里', style: TextStyle(color: Colors.grey)));
                }
                
                String sourceText = _sourceController.text;
                if (sourceText.isEmpty && chatState.messages.isNotEmpty) {
                   final lastUserMsg = chatState.messages.lastWhere((m) => m.isUser, orElse: () => Message(content: '', isUser: true, id: '', timestamp: DateTime.now()));
                   sourceText = lastUserMsg.content;
                }

                final sourceLines = sourceText.split('\n');
                final targetText = aiMessage?.content ?? '';
                final targetLines = targetText.split('\n');
                
                if (chatState.isLoading && targetText.isEmpty) {
                   return const Center(child: Text('正在翻译...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)));
                }
                
                final int itemCount = _showComparison 
                    ? (sourceLines.length > targetLines.length ? sourceLines.length : targetLines.length)
                    : targetLines.length;
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: itemCount,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tgt = index < targetLines.length ? targetLines[index] : '';
                    
                    if (!_showComparison) {
                       return SelectableText(
                          tgt,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontFamily: isWindows ? 'Microsoft YaHei' : null
                          ),
                       );
                    }
                    
                    final src = index < sourceLines.length ? sourceLines[index] : '';
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (src.isNotEmpty)
                          SelectableText(
                            src,
                            style: TextStyle(
                              color: theme.resources.textFillColorSecondary, 
                              fontSize: 14,
                              height: 1.4,
                              fontFamily: isWindows ? 'Microsoft YaHei' : null
                            ),
                          ),
                        if (src.isNotEmpty && tgt.isNotEmpty)
                          const SizedBox(height: 4),
                        if (tgt.isNotEmpty)
                          SelectableText(
                            tgt,
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              fontFamily: isWindows ? 'Microsoft YaHei' : null
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(translationProvider, (prev, next) {
      if (!_hasRestored && next.messages.isNotEmpty) {
        final lastUserMsg = next.messages.lastWhere(
           (m) => m.isUser, 
           orElse: () => Message(content: '', isUser: true, id: '', timestamp: DateTime.now())
        );
        if (lastUserMsg.content.isNotEmpty) {
           _sourceController.text = lastUserMsg.content;
           _hasRestored = true;
        }
      }
    });

    final chatState = ref.watch(translationProvider);
    final isWindows = !kIsWeb && Platform.isWindows;
    final theme = fluent.FluentTheme.of(context);
    
    final aiMessage = chatState.messages.isNotEmpty && !chatState.messages.last.isUser 
        ? chatState.messages.last 
        : null;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.resources.dividerStrokeColorDefault)),
            color: theme.navigationPaneTheme.backgroundColor,
          ),
          child: Row(
            children: [
               fluent.Text('文本翻译', style: const TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(width: 24),
               
               fluent.ComboBox<String>(
                 value: _sourceLang,
                 items: _sourceLanguages.map((e) => fluent.ComboBoxItem(child: Text(e), value: e)).toList(),
                 onChanged: (v) => setState(() => _sourceLang = v!),
               ),
               const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 12),
                 child: Icon(fluent.FluentIcons.forward, size: 12),
               ),
               fluent.ComboBox<String>(
                 value: _targetLang,
                 items: _targetLanguages.map((e) => fluent.ComboBoxItem(child: Text(e), value: e)).toList(),
                 onChanged: (v) => setState(() => _targetLang = v!),
               ),
               
               const SizedBox(width: 24),
               fluent.Checkbox(
                 checked: _showComparison,
                 onChanged: (v) => setState(() => _showComparison = v ?? true),
                 content: const Text('双语对照'),
               ),

               const Spacer(),
               if (chatState.isLoading)
                 const Padding(
                   padding: EdgeInsets.only(right: 12),
                   child: fluent.ProgressRing(strokeWidth: 2), 
                 ),
               fluent.FilledButton(
                 onPressed: chatState.isLoading ? null : _translate,
                 child: const Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(fluent.FluentIcons.translate, size: 14),
                     SizedBox(width: 6),
                     Text('翻译'),
                   ],
                 ),
               ),
            ],
          ), 
        ),

        // Responsive Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                 // Mobile: Vertical Column
                 return Column(
                    children: [
                       Expanded(child: _buildSourceInput(theme, isWindows)),
                       Container(height: 1, color: theme.resources.dividerStrokeColorDefault),
                       Expanded(child: _buildTargetOutput(theme, isWindows, chatState, aiMessage)),
                    ],
                 );
              }
              
              // Desktop: Resizable Row
              final width = constraints.maxWidth;
              final leftWidth = width * _leftRatio;
              // final rightWidth = width - leftWidth - 16; 
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: leftWidth < 100 ? 100 : leftWidth,
                    child: _buildSourceInput(theme, isWindows),
                  ),

                  // Draggable Divider
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _leftRatio += details.delta.dx / width;
                          if (_leftRatio < 0.2) _leftRatio = 0.2;
                          if (_leftRatio > 0.8) _leftRatio = 0.8;
                        });
                      },
                      child: Container(
                        width: 16,
                        color: Colors.transparent,
                        child: Center(
                          child: Container(
                             width: 1, 
                             color: theme.resources.dividerStrokeColorDefault
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: _buildTargetOutput(theme, isWindows, chatState, aiMessage),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Chat Tab (Bubble View) ---
class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const _FadeIndexedStack({
    super.key, // Use super.key
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _currentIndex = widget.index;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(
        index: _currentIndex,
        children: widget.children,
      ),
    );
  }
}

class _ChatContent extends ConsumerStatefulWidget {
  const _ChatContent();

  @override
  ConsumerState<_ChatContent> createState() => __ChatContentState();
}

class __ChatContentState extends ConsumerState<_ChatContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<String> _attachments = [];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty && _attachments.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(_controller.text, attachments: _attachments);
    _controller.clear();
    setState(() => _attachments = []);
    _focusNode.requestFocus();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg', 'bmp', 'gif']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;
    setState(() {
      _attachments.addAll(files.map((file) => file.path));
    });
  }

  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    final reader = await clipboard.read();
    
    // Check for Images
    if (reader.canProvide(Formats.png) || reader.canProvide(Formats.jpeg) || reader.canProvide(Formats.fileUri)) {
       _processReader(reader);
       return;
    }
    
    // Check for plain text
    if (reader.canProvide(Formats.plainText)) {
       final text = await reader.readValue(Formats.plainText);
       if (text != null && text.isNotEmpty) {
          final selection = _controller.selection;
          final currentText = _controller.text;
          if (selection.isValid) {
             final newText = currentText.replaceRange(selection.start, selection.end, text);
             _controller.value = TextEditingValue(
               text: newText,
               selection: TextSelection.collapsed(offset: selection.start + text.length),
             );
          } else {
             _controller.text += text;
          }
       }
       return;
    }
    
    // Fast Fallback: Try using pasteboard package directly (Robust Win+V support)
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
         debugPrint('Found image via Pasteboard fallback (Immediate).');
         final tempDir = await getTemporaryDirectory();
         final path = '${tempDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
         await File(path).writeAsBytes(imageBytes);
         if (mounted) {
            setState(() {
               _attachments.add(path);
            });
         }
         return; 
      }
    } catch (e) {
      debugPrint('Pasteboard Fallback Error: $e');
    }
    
    // Retry Logic for generic delayed clipboard
    debugPrint('No immediate format, probing for delay...');
    for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        final newReader = await clipboard.read();
        if (newReader.canProvide(Formats.png) || newReader.canProvide(Formats.jpeg)) {
           _processReader(newReader);
           return;
        }
    }
  }
  
  Future<void> _processReader(ClipboardReader reader) async {
     if (reader.canProvide(Formats.png)) {
         reader.getFile(Formats.png, (file) => _saveClipImage(file));
     } else if (reader.canProvide(Formats.jpeg)) {
         reader.getFile(Formats.jpeg, (file) => _saveClipImage(file));
     }
  }

  Future<void> _saveClipImage(file) async {
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.png'; 
        final stream = file.getStream();
        final List<int> bytes = [];
        await for (final chunk in stream) {
           bytes.addAll(chunk as List<int>);
        }
        
        if (bytes.isNotEmpty) {
           await File(path).writeAsBytes(bytes);
           if (mounted) {
              setState(() {
                 _attachments.add(path);
              });
           }
        }
      } catch (e) {
        debugPrint('Paste Error: $e');
      }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isWindows = Platform.isWindows;
    
    final isDark = isWindows 
        ? fluent.FluentTheme.of(context).brightness == fluent.Brightness.dark
        : Theme.of(context).brightness == Brightness.dark;

    final inputAreaColor = isWindows
        ? (isDark ? fluent.Colors.grey[160] : fluent.Colors.grey[20])
        : (isDark ? Colors.grey[900] : Colors.grey[100]);

    final settingsState = ref.watch(settingsProvider);
    final providerName = settingsState.activeProvider?.name ?? 'Unknown';

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: chatState.messages.length,
            itemBuilder: (context, index) {
              final msg = chatState.messages[index];
              final isUser = msg.isUser;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                       Container(
                         margin: const EdgeInsets.only(right: 12, top: 0),
                         child: const CircleAvatar(
                           radius: 16,
                           backgroundColor: Colors.transparent, // Or theme color
                           child: Icon(fluent.FluentIcons.robot, size: 24), // Placeholder for Bot Avatar
                         ),
                       ),
                    ],

                    Flexible(
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                           // Header Row
                           Padding(
                             padding: const EdgeInsets.only(bottom: 4),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text(
                                   isUser ? settingsState.userName : '${msg.model ?? settingsState.selectedModel} | ${msg.provider ?? providerName}', 
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                 ),
                                 const SizedBox(width: 8),
                                 Text(
                                   '${msg.timestamp.month}/${msg.timestamp.day} ${msg.timestamp.hour.toString().padLeft(2,'0')}:${msg.timestamp.minute.toString().padLeft(2,'0')}',
                                   style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                 ),
                               ],
                             ),
                           ),
                           
                           // Bubble
                           Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser 
                                    ? (isWindows ? fluent.Colors.blue : Colors.blue) 
                                    : (isWindows ? fluent.FluentTheme.of(context).cardColor : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   if (msg.attachments.isNotEmpty)
                                     ...msg.attachments.map((path) => Padding(
                                       padding: const EdgeInsets.only(bottom: 8.0),
                                       child: Text('[Image: ${path.split(Platform.pathSeparator).last}]', 
                                         style: TextStyle(fontStyle: FontStyle.italic, color: isUser ? Colors.white70 : Colors.black54, fontSize: 12)
                                       ),
                                     )),

                                   if (!msg.isUser && msg.reasoningContent != null && msg.reasoningContent!.isNotEmpty)
                                     Padding(
                                       padding: const EdgeInsets.only(bottom: 8.0),
                                       child: ReasoningDisplay(
                                         content: msg.reasoningContent!,
                                         isWindows: isWindows,
                                         isRunning: chatState.isLoading && index == chatState.messages.length - 1,
                                       ),
                                     ),
                                   SelectionArea(
                                      child: MarkdownBody(
                                        data: msg.content,
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            fontSize: 16,
                                            height: 1.5,
                                            fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
                                            color: isUser ? Colors.white : (isWindows && isDark ? Colors.white : Colors.black87),
                                          ),
                                          code: TextStyle(
                                            backgroundColor: isUser ? Colors.white24 : Colors.grey.withOpacity(0.2),
                                            fontFamily: isWindows ? 'Consolas' : 'monospace',
                                          ),
                                        ),
                                        onTapLink: (text, href, title) {},
                                      ),
                                   ),
                                   if (msg.images.isNotEmpty) ...[
                                     const SizedBox(height: 8),
                                     Wrap(
                                       spacing: 8,
                                       runSpacing: 8,
                                       children: msg.images.map((img) => ChatImageBubble(
                                         imageUrl: img,
                                       )).toList(),
                                     ),
                                   ],
                                 ],
                               ),
                           ),
                        ],
                      ),
                    ),

                    if (isUser) ...[
                       Container(
                         margin: const EdgeInsets.only(left: 12, top: 0),
                         child: const CircleAvatar(
                           radius: 16,
                           backgroundColor: Colors.blue, 
                           child: Icon(Icons.person, color: Colors.white, size: 20),
                         ),
                       ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (chatState.isLoading)
           LinearProgressIndicator(
            backgroundColor: Colors.transparent, 
            color: isWindows ? fluent.Colors.blue : Colors.blue,
           ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), // Adjusted padding to move down
          color: inputAreaColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (_attachments.isNotEmpty)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_attachments[index].split(Platform.pathSeparator).last),
                        onDeleted: () {
                          setState(() {
                            _attachments.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   isWindows
                    ? fluent.IconButton(
                        icon: const fluent.Icon(fluent.FluentIcons.attach),
                        onPressed: _pickFiles, 
                      )
                    : IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _pickFiles,
                      ),
                   const SizedBox(width: 8),
                   Expanded(
                    child: isWindows
                      ? CallbackShortcuts(
                          bindings: {
                             SingleActivator(LogicalKeyboardKey.keyV, control: true): _handlePaste,
                          },
                          child: fluent.TextBox(
                            controller: _controller,
                            focusNode: _focusNode,
                            placeholder: '输入消息...',
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: '输入消息...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 32,
                    child: isWindows
                      ? fluent.FilledButton(
                          onPressed: _sendMessage,
                          child: const fluent.Icon(fluent.FluentIcons.send),
                        )
                      : IconButton.filled(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TranslationPairCard extends StatelessWidget {
  final Message userMessage;
  final Message? aiMessage;
  final bool isWindows;
  final bool isRunning;

  const _TranslationPairCard({
    required this.userMessage,
    this.aiMessage,
    required this.isWindows,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isWindows) {
      final theme = fluent.FluentTheme.of(context);
      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Content (Source) - LEFT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        fluent.Text(
                          '原文',
                          style: theme.typography.caption?.copyWith(
                            color: fluent.Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      userMessage.content,
                      style: theme.typography.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: theme.resources.dividerStrokeColorDefault,
              ),

              // AI Content (Target) - RIGHT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        fluent.Text(
                          '译文',
                          style: theme.typography.caption?.copyWith(
                            color: fluent.Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Copy Button
                        fluent.IconButton(
                          icon: const fluent.Icon(fluent.FluentIcons.copy, size: 14),
                          onPressed: () {
                             // TODO: Implement copy to clipboard
                          },
                          style: fluent.ButtonStyle(
                            padding: fluent.ButtonState.all(const EdgeInsets.all(4)),
                            foregroundColor: fluent.ButtonState.resolveWith((states) {
                               if (states.isHovering) return fluent.Colors.blue;
                               return fluent.Colors.grey;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (aiMessage != null) ...[
                      if (aiMessage!.reasoningContent != null && aiMessage!.reasoningContent!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ReasoningDisplay(
                            content: aiMessage!.reasoningContent!,
                            isWindows: isWindows,
                            isRunning: isRunning,
                          ),
                        ),
                      SelectableText(
                        aiMessage!.content,
                        style: theme.typography.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ] else if (isRunning) ...[
                       const fluent.ProgressRing(strokeWidth: 2, activeColor: fluent.Colors.grey),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Android / Material implementation
      // ... For brevity, focusing on Windows as per user context, 
      // but keeping Scaffold structure valid.
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('原文', style: Theme.of(context).textTheme.labelSmall),
              SelectableText(userMessage.content),
              const Divider(height: 24),
              if (aiMessage != null) ...[
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('译文', style: Theme.of(context).textTheme.labelSmall),
                     IconButton(
                       icon: const Icon(Icons.copy, size: 16), 
                       onPressed: () {},
                       visualDensity: VisualDensity.compact,
                     ),
                   ],
                 ),
                 SelectableText(aiMessage!.content),
              ]
            ],
          ),
        ),
      );
    }
  }
}



class _ModelSelector extends ConsumerStatefulWidget {
  final bool isWindows;

  const _ModelSelector({this.isWindows = true});

  @override
  ConsumerState<_ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends ConsumerState<_ModelSelector> {
  final fluent.FlyoutController _flyoutController = fluent.FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final selected = settingsState.selectedModel;
    final activeProvider = settingsState.activeProvider;
    final providers = settingsState.providers;

    // Check if any provider has models
    final hasAnyModels = providers.any((p) => p.models.isNotEmpty);
    if (!hasAnyModels) {
      return const SizedBox.shrink();
    }

    // Common logic to switch provider and model
    Future<void> switchModel(String providerId, String model) async {
      await ref.read(settingsProvider.notifier).selectProvider(providerId);
      await ref.read(settingsProvider.notifier).setSelectedModel(model);
    }

    // Windows (Fluent UI) Implementation
    if (widget.isWindows) {
      // Build grouped items
      final List<fluent.MenuFlyoutItemBase> items = [];
      
      for (final provider in providers) {
        if (provider.models.isEmpty) continue;
        
        // Add Provider Header
        items.add(fluent.MenuFlyoutItem(
          text: fluent.Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold, color: fluent.Colors.grey)),
          onPressed: null, // Disabled / Header
        ));
        
        // Add Models
        for (final model in provider.models) {
          items.add(fluent.MenuFlyoutItem(
            text: fluent.Padding(
               padding: const EdgeInsets.only(left: 12),
               child: fluent.Text(model),
            ),
            onPressed: () => switchModel(provider.id, model),
            trailing: (activeProvider.id == provider.id && selected == model)
                ? const fluent.Icon(fluent.FluentIcons.check_mark, size: 12) 
                : null,
          ));
        }
        // Divider
        if (provider != providers.last && providers.any((p) => providers.indexOf(p) > providers.indexOf(provider) && p.models.isNotEmpty)) {
           items.add(const fluent.MenuFlyoutSeparator());
        }
      }

      final theme = fluent.FluentTheme.of(context);

      return fluent.FlyoutTarget(
        controller: _flyoutController,
        child: fluent.HoverButton(
          onPressed: () {
            _flyoutController.showFlyout(
              autoModeConfiguration: fluent.FlyoutAutoConfiguration(
                preferredMode: fluent.FlyoutPlacementMode.bottomCenter,
              ),
              barrierDismissible: true,
              dismissOnPointerMoveAway: false,
              dismissWithEsc: true,
              builder: (context) {
                return fluent.MenuFlyout(items: items);
              },
            );
          },
          builder: (context, states) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: states.isHovering 
                  ? theme.resources.subtleFillColorSecondary 
                  : fluent.Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  fluent.Icon(fluent.FluentIcons.auto_enhance_on, color: fluent.Colors.yellow, size: 14),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: fluent.Text(
                      selected ?? '选择模型',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Provider Tag
                  if (activeProvider.name.isNotEmpty) ...[
                     const SizedBox(width: 8),
                     fluent.Text('|', style: TextStyle(color: fluent.Colors.grey.withOpacity(0.5))),
                     const SizedBox(width: 8),
                     fluent.Text(
                       activeProvider.name.toUpperCase(), 
                       style: TextStyle(
                         fontWeight: FontWeight.bold, 
                         color: fluent.Colors.grey,
                         fontSize: 10,
                       ),
                     ),
                  ],
                  const SizedBox(width: 4),
                  fluent.Icon(fluent.FluentIcons.chevron_down, size: 8, color: theme.typography.caption?.color),
                ],
              ),
            );
          },
        ),
      );
    } 
    
    // Android (Material) Implementation
    else {
      final List<PopupMenuEntry<String>> items = [];
      
      for (final provider in providers) {
        if (provider.models.isEmpty) continue;
        
        // Header
        items.add(PopupMenuItem<String>(
          enabled: false,
          child: Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ));
        
        // Models
        for (final model in provider.models) {
           // We need to pass both IDs. PopupMenu value is String. 
           // Format: "pid|mid"
           items.add(PopupMenuItem<String>(
             value: '${provider.id}|$model',
             height: 32,
             child: Padding(
               padding: const EdgeInsets.only(left: 16),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(model),
                   if (activeProvider.id == provider.id && selected == model)
                     const Icon(Icons.check, size: 16, color: Colors.blue),
                 ],
               ),
             ),
           ));
        }
        if (provider != providers.last) {
           items.add(const PopupMenuDivider());
        }
      }

      return PopupMenuButton<String>(
        tooltip: '切换模型',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          final parts = value.split('|');
          if (parts.length == 2) {
             switchModel(parts[0], parts[1]);
          }
        },
        itemBuilder: (context) => items,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  selected ?? '选择模型',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activeProvider.name.isNotEmpty) ...[
                 const SizedBox(width: 8),
                 Text('|', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                 const SizedBox(width: 8),
                 Text(
                   activeProvider.name.toUpperCase(), 
                   style: const TextStyle(
                     fontWeight: FontWeight.bold, 
                     color: Colors.grey,
                     fontSize: 10,
                   ),
                 ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      );
    }
  }
}

class _WindowButtons extends StatefulWidget {
  const _WindowButtons();

  @override
  State<_WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<_WindowButtons> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    
    return Row(
      children: [
        fluent.IconButton(
          icon: fluent.Icon(fluent.FluentIcons.chrome_minimize, size: 10, color: theme.typography.caption?.color),
          onPressed: () => windowManager.minimize(),
        ),
        FutureBuilder<bool>(
          future: windowManager.isMaximized(),
          builder: (context, snapshot) {
            final isMaximized = snapshot.data ?? false;
            return fluent.IconButton(
              icon: fluent.Icon(
                 isMaximized ? fluent.FluentIcons.chrome_restore : fluent.FluentIcons.square_shape, 
                 size: 10,
                 color: theme.typography.caption?.color
              ),
              onPressed: () {
                if (isMaximized) {
                  windowManager.restore();
                } else {
                  windowManager.maximize();
                }
                setState(() {});
              },
            );
          },
        ),
        fluent.IconButton(
          icon: fluent.Icon(fluent.FluentIcons.chrome_close, size: 10, color: theme.typography.caption?.color),
          onPressed: () => windowManager.close(),
          style: fluent.ButtonStyle(
            backgroundColor: fluent.ButtonState.resolveWith((states) {
               if (states.isHovering) return fluent.Colors.red;
               return fluent.Colors.transparent;
            }),
            foregroundColor: fluent.ButtonState.resolveWith((states) {
               if (states.isHovering) return fluent.Colors.white;
               return theme.typography.caption?.color;
            }),
          ),
        ),
      ],
    );
  }
  
  @override
  void onWindowMaximize() => setState(() {});
  @override
  void onWindowUnmaximize() => setState(() {});
  @override
  void onWindowRestore() => setState(() {});
}
