import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/message.dart';
import 'chat_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:window_manager/window_manager.dart';
import '../../settings/presentation/settings_content.dart'; 
import '../../settings/presentation/settings_provider.dart';
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
  fluent.PaneDisplayMode _displayMode = fluent.PaneDisplayMode.compact;
  bool _isRailExtended = false;

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      final theme = fluent.FluentTheme.of(context);
      final isExpanded = _displayMode == fluent.PaneDisplayMode.open;
      
      // Navigation Items Data (Order: History, Translate, Settings)
      final navItems = [
        (icon: fluent.FluentIcons.history, label: '历史', body: const HistoryContent()),
        (icon: fluent.FluentIcons.translate, label: '翻译', body: const _TranslationContent()),
        (icon: fluent.FluentIcons.settings, label: '设置', body: const SettingsContent()),
      ];
      
      return Column(
        children: [
          // Custom Top Bar
          // Custom Top Bar
          Container(
            height: 32,
            color: theme.navigationPaneTheme.backgroundColor,
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Hamburger Toggle
                fluent.IconButton(
                  icon: const fluent.Icon(fluent.FluentIcons.global_nav_button, size: 16),
                  onPressed: () {
                     setState(() {
                       _displayMode = isExpanded 
                          ? fluent.PaneDisplayMode.compact 
                          : fluent.PaneDisplayMode.open;
                     });
                  },
                ),
                const SizedBox(width: 12),
                // Title Removed
                // const DragToMoveArea(
                //   child: Align(
                //     alignment: Alignment.centerLeft,
                //     child: fluent.Text('LLM Trans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                //   ),
                // ),
                // const SizedBox(width: 12), // Removed extra space before selector
                const _ModelSelector(isWindows: true),
                Expanded(child: DragToMoveArea(child: Container(color: Colors.transparent))),
                const _WindowButtons(),
              ],
            ),
          ),
          
          // Main Content: Custom Sidebar + Body
          Expanded(
            child: Row(
              children: [
                // Custom Sidebar with Fixed Item Positions
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: isExpanded ? 200 : 50,
                  decoration: BoxDecoration(
                    color: theme.navigationPaneTheme.backgroundColor,
                    border: Border(right: BorderSide(color: theme.resources.dividerStrokeColorDefault)),
                  ),
                  child: Column(
                    children: [
                      // Navigation Items - Fixed Position (Render all except Settings)
                      ...navItems.take(navItems.length - 1).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = _selectedIndex == index;
                        
                        return fluent.HoverButton(
                          onPressed: () {
                            if (index == 0) {
                               // History Tab (index 0) - Toggle Sidebar
                               if (_selectedIndex == 0) {
                                  ref.read(isHistorySidebarVisibleProvider.notifier).update((state) => !state);
                               } else {
                                  setState(() => _selectedIndex = 0);
                                  ref.read(isHistorySidebarVisibleProvider.notifier).state = true;
                               }
                            } else {
                               setState(() => _selectedIndex = index);
                            }
                          },
                          builder: (context, states) {
                            return Container(
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? theme.accentColor.withOpacity(0.1)
                                  : states.isHovering ? theme.resources.subtleFillColorSecondary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  // Icon - Always Centered
                                  SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: fluent.Icon(
                                        item.icon, 
                                        size: 18,
                                        color: isSelected ? theme.accentColor : null,
                                      ),
                                    ),
                                  ),
                                  // Label - Show/Hide based on expanded state
                                  if (isExpanded)
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSelected ? theme.accentColor : null,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                      
                        const Spacer(),

                        // Settings Button (Moved to Bottom)
                        Builder(
                          builder: (context) {
                            final index = navItems.length - 1; // Last item is Settings
                            final item = navItems[index];
                            final isSelected = _selectedIndex == index;

                            return fluent.HoverButton(
                              onPressed: () => setState(() => _selectedIndex = index),
                              builder: (context, states) {
                                return Container(
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? theme.accentColor.withOpacity(0.1)
                                      : states.isHovering ? theme.resources.subtleFillColorSecondary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Center(
                                          child: fluent.Icon(
                                            item.icon, 
                                            size: 18,
                                            color: isSelected ? theme.accentColor : null,
                                          ),
                                        ),
                                      ),
                                      if (isExpanded)
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              color: isSelected ? theme.accentColor : null,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        ),
                        const SizedBox(height: 4),
                        // Theme Toggle using Consumer for reliable state updates
                        Consumer(
                          builder: (context, ref, child) {
                            final currentTheme = ref.watch(settingsProvider).themeMode;
                            
                            // Determine the ACTUAL effective brightness
                            final bool isActuallyDark;
                            if (currentTheme == 'dark') {
                              isActuallyDark = true;
                            } else if (currentTheme == 'light') {
                              isActuallyDark = false;
                            } else {
                              // System mode - check actual platform brightness
                              isActuallyDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
                            }
                            
                            // Icon and label based on effective brightness
                            final IconData icon = isActuallyDark ? fluent.FluentIcons.clear_night : fluent.FluentIcons.sunny;
                            final String label = currentTheme == 'system' 
                                ? '跟随系统' 
                                : (isActuallyDark ? '夜间模式' : '日间模式');
                            
                            return fluent.HoverButton(
                              onPressed: () {
                                ref.read(settingsProvider.notifier).toggleThemeMode();
                              },
                              builder: (context, states) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: states.isHovering ? theme.resources.subtleFillColorSecondary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: fluent.Icon(
                                              icon,
                                              key: ValueKey(isActuallyDark),
                                              size: 18,
                                              color: theme.typography.body?.color,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isExpanded)
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: const TextStyle(fontWeight: FontWeight.normal),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                    ],
                  ),
                ),
                
                // Body Content - with proper background
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: _FadeIndexedStack(
                      index: _selectedIndex,
                      children: navItems.map((item) => item.body).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Mobile / Android Layout
      return Scaffold(
        appBar: AppBar(
          title: const Text('LLM Trans'),
          // Android Toggle
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
          ),
          actions: const [
             _ModelSelector(isWindows: false),
             SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            NavigationRail(
              extended: _isRailExtended, // Toggle width
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                 setState(() => _selectedIndex = index);
              },
              
              // Only show labels when extended to keep compact mode clean
              labelType: _isRailExtended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.history), 
                  selectedIcon: Icon(Icons.history, color: Colors.blue),
                  label: Text('历史')
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.translate), 
                  selectedIcon: Icon(Icons.translate, color: Colors.blue),
                  label: Text('翻译')
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings), 
                  selectedIcon: Icon(Icons.settings, color: Colors.blue),
                  label: Text('设置')
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _FadeIndexedStack(
                index: _selectedIndex,
                children: const [
                  HistoryContent(),
                  _TranslationContent(),
                  SettingsContent(),
                ],
              ),
            ),
          ],
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    // Listen for state changes to handle async restoration
    ref.listen<ChatState>(translationProvider, (prev, next) {
      if (!_hasRestored && next.messages.isNotEmpty) {
        // We found data, try to restore
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
    final isWindows = Platform.isWindows;
    final theme = fluent.FluentTheme.of(context);
    
    // Find the latest AI response
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
               
               // Language Selectors
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

        // Split Editor Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final leftWidth = width * _leftRatio;
              final rightWidth = width - leftWidth - 16; // 16 for divider handle
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Source Input
                  SizedBox(
                    width: leftWidth < 100 ? 100 : leftWidth, // Min width constraint
                    child: Container(
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
                    ),
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
                        color: Colors.transparent, // Invisible area for easier grabbing
                        child: Center(
                          child: Container(
                             width: 1, 
                             color: theme.resources.dividerStrokeColorDefault
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right: Target Output (Line-by-Line / Vertical Stack)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(0),
                      color: theme.scaffoldBackgroundColor, // Same as left panel
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
                                     // Copy logic
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
                                
                                // 1. Prepare Data
                                // Use controller text first, if empty (e.g. sync lag?), try to find last user message.
                                String sourceText = _sourceController.text;
                                if (sourceText.isEmpty && chatState.messages.isNotEmpty) {
                                   final lastUserMsg = chatState.messages.lastWhere((m) => m.isUser, orElse: () => Message(content: '', isUser: true, id: '', timestamp: DateTime.now()));
                                   sourceText = lastUserMsg.content;
                                }

                                final sourceLines = sourceText.split('\n');
                                final targetText = aiMessage?.content ?? '';
                                final targetLines = targetText.split('\n');
                                
                                // If loading and no content yet
                                if (chatState.isLoading && targetText.isEmpty) {
                                   return const Center(child: Text('正在翻译...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)));
                                }
                                
                                // 2. Display Strategy
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
                                    
                                    // Vertical Stack with Source (Brighter) -> Target
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (src.isNotEmpty)
                                          SelectableText(
                                            src,
                                            style: TextStyle(
                                              // Improve visibility: lighter grey or secondary text color, not dark grey
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
                    ),
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
