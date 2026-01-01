import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../chat/presentation/chat_provider.dart';
import '../../chat/domain/message.dart';
import 'package:aurora/features/chat/presentation/widgets/reasoning_display.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../chat/presentation/widgets/chat_image_bubble.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';
import '../../settings/presentation/settings_provider.dart'; 
import 'widgets/hover_image_preview.dart'; 

class HistoryContent extends ConsumerStatefulWidget {
  const HistoryContent({super.key});

  @override
  ConsumerState<HistoryContent> createState() => _HistoryContentState();
}

class _HistoryContentState extends ConsumerState<HistoryContent> {
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
       await ref.read(sessionsProvider.notifier).loadSessions();
       // Auto-select logic moved to handle interaction better or kept minimal
       if (ref.read(selectedHistorySessionIdProvider) == null) {
          final sessions = ref.read(sessionsProvider).sessions;
          if (sessions.isNotEmpty) {
             // On Mobile, maybe don't auto-open? 
             // Ideally we check screen size here but context is tricky.
             // For now keep desktop behavior as default (auto-open).
             ref.read(selectedHistorySessionIdProvider.notifier).state = sessions.first.sessionId;
          } else {
             ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
          }
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(sessionsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        // --- Mobile View ---
        if (isMobile) {
          if (selectedSessionId != null && selectedSessionId != '') {
             // Show Chat Detail with Back Button
             return Column(
               children: [
                 Container(
                   height: 48,
                   padding: const EdgeInsets.symmetric(horizontal: 8),
                   decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault)),
                      color: fluent.FluentTheme.of(context).navigationPaneTheme.backgroundColor,
                   ),
                   child: Row(
                     children: [
                       fluent.IconButton(
                         icon: const Icon(Icons.arrow_back),
                         onPressed: () {
                            ref.read(selectedHistorySessionIdProvider.notifier).state = null;
                         },
                       ),
                       const SizedBox(width: 8),
                       const Text('会话详情', style: TextStyle(fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),
                 const Expanded(child: _HistoryChatView()),
               ],
             );
          } else {
             // Show Session List (Full Width)
             return _SessionList(
               sessionsState: sessionsState, 
               selectedSessionId: selectedSessionId,
               isMobile: true,
             );
          }
        }

        // --- Desktop View (Split) ---
        final isSidebarVisible = ref.watch(isHistorySidebarVisibleProvider);
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSidebarVisible ? 250 : 0,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 250,
                  maxWidth: 250,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault)),
                      color: fluent.FluentTheme.of(context).cardColor,
                    ),
                    child: _SessionList(
                      sessionsState: sessionsState, 
                      selectedSessionId: selectedSessionId,
                      isMobile: false,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: selectedSessionId == null
                ? const Center(child: Text('请选择或新建一个话题'))
                : const _HistoryChatView(),
            ),
          ],
        );
      },
    );
  }
}

class _SessionList extends ConsumerWidget {
  final SessionsState sessionsState;
  final String? selectedSessionId;
  final bool isMobile;

  const _SessionList({
    required this.sessionsState,
    required this.selectedSessionId,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(12.0),
           child: SizedBox(
              width: double.infinity,
              child: fluent.Button(
                   child: const Row(
                     mainAxisAlignment: MainAxisAlignment.center, 
                     children: [fluent.Icon(fluent.FluentIcons.add), SizedBox(width: 8), Text('新建话题')]
                   ),
                   onPressed: () {
                      ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
                      // On mobile we don't need to hide sidebar, we just navigate.
                      // On desktop we might want to keep sidebar open.
                   },
                 ),
           ),
         ),
         const Divider(),
         Expanded(
           child: sessionsState.isLoading && sessionsState.sessions.isEmpty
             ? const Center(child: fluent.ProgressRing())
             : ListView.builder(
                 itemCount: sessionsState.sessions.length,
                 itemBuilder: (context, index) {
                   final session = sessionsState.sessions[index];
                   final isSelected = session.sessionId == selectedSessionId;
                   
                   return GestureDetector(
                     onTap: () {
                        ref.read(selectedHistorySessionIdProvider.notifier).state = session.sessionId;
                     },
                     child: Container(
                       color: isSelected 
                         ? fluent.FluentTheme.of(context).accentColor.withOpacity(0.1)
                         : Colors.transparent,
                       child: fluent.ListTile(
                             title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                             subtitle: Text(DateFormat('MM/dd HH:mm').format(session.lastMessageTime)),
                             onPressed: () {
                                ref.read(selectedHistorySessionIdProvider.notifier).state = session.sessionId;
                             },
                             trailing: fluent.IconButton(
                               icon: const fluent.Icon(fluent.FluentIcons.delete, size: 12),
                               onPressed: () {
                                 ref.read(sessionsProvider.notifier).deleteSession(session.sessionId);
                                 if (isSelected) {
                                    ref.read(selectedHistorySessionIdProvider.notifier).state = null;
                                 }
                               },
                             ),
                           ),
                     ),
                   );
                 },
               ),
         ),
       ],
    );
  }
}

class _HistoryChatView extends ConsumerStatefulWidget {
  const _HistoryChatView();

  @override
  ConsumerState<_HistoryChatView> createState() => _HistoryChatViewState();
}

class _HistoryChatViewState extends ConsumerState<_HistoryChatView> {
  final TextEditingController _controller = TextEditingController();
  List<String> _attachments = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: <String>['jpg', 'png', 'jpeg', 'bmp', 'gif'],
    );
    final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (files.isEmpty) return;

    setState(() {
      _attachments.addAll(files.map((e) => e.path));
    });
  }

  Future<void> _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;

    final reader = await clipboard.read();
    
    // Log all formats for debugging
    final formats = reader.platformFormats;
    debugPrint('Clipboard formats: ${formats.map((f) => f.toString()).join(', ')}');
    
    // Retry logic: If no image found, wait and retry (Win+V delay populating)
    if (!reader.canProvide(Formats.png) && !reader.canProvide(Formats.jpeg) && !reader.canProvide(Formats.fileUri)) {
       debugPrint('No image formats found, probing for delay...');
       for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          // We must re-read the reader/clipboard items?
          // SystemClipboard.instance.read() returns a Reader. 
          // Does the Reader update? Or do we need to call clipboard.read() again?
          // Usually we need to get a new reader.
          final newReader = await clipboard.read();
          if (newReader.canProvide(Formats.png) || newReader.canProvide(Formats.jpeg) || newReader.canProvide(Formats.fileUri)) {
             debugPrint('Found formats after delay ${i+1}: ${newReader.platformFormats}');
             // Recursive call or continue with newReader?
             // Safest to just call _handlePaste again or refactor.
             // Let's recursively call _handlePaste but prevent infinite loop?
             // Or just continue logic with newReader.
             // Refactoring extracting logic is better but for now replacing reader variable.
             // Cannot reassign final reader.
             // So I will call checking logic with newReader.
             await _processReader(newReader);
             return;
          }
       }
       debugPrint('Retry / Probe failed. Attempting Pasteboard fallback...');
       
       // Fallback: Try using pasteboard package directly
       try {
         final imageBytes = await Pasteboard.image;
         if (imageBytes != null && imageBytes.isNotEmpty) {
            debugPrint('Found image via Pasteboard fallback.');
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
          debugPrint('Pasteboard fallback failed: $e');
       }
       debugPrint('All paste attempts failed.');
    } else {
       await _processReader(reader);
       return;
    }
  }

  Future<void> _processReader(ClipboardReader reader) async {
    // Handle Images - try PNG first (super_clipboard auto-converts DIB to PNG on Windows)
    if (reader.canProvide(Formats.png)) {
      debugPrint('Found PNG in clipboard');
      final completer = Completer<String?>();
      reader.getFile(Formats.png, (file) async {
        try {
          debugPrint('Reading PNG file stream...');
          final tempDir = await getTemporaryDirectory();
          final path = '${tempDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.png';
          final stream = file.getStream();
          final bytes = await stream.toList();
          final allBytes = bytes.expand((x) => x).toList();
          if (allBytes.isNotEmpty) {
             await File(path).writeAsBytes(allBytes);
             debugPrint('Saved PNG to $path');
             completer.complete(path);
          } else {
             debugPrint('PNG stream was empty');
             completer.complete(null);
          }
        } catch (e) {
          debugPrint('Error reading PNG from clipboard: $e');
          completer.complete(null);
        }
      });
      
      final imagePath = await completer.future;
      if (imagePath != null && mounted) {
        setState(() {
          _attachments.add(imagePath);
        });
        return;
      }
    } else {
       debugPrint('No PNG found in clipboard');
    }

    // Handle JPEG images
    if (reader.canProvide(Formats.jpeg)) {
      debugPrint('Found JPEG in clipboard');
      final completer = Completer<String?>();
      reader.getFile(Formats.jpeg, (file) async {
        try {
          debugPrint('Reading JPEG file stream...');
          final tempDir = await getTemporaryDirectory();
          final path = '${tempDir.path}${Platform.pathSeparator}paste_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final stream = file.getStream();
          final bytes = await stream.toList();
          final allBytes = bytes.expand((x) => x).toList();
          if (allBytes.isNotEmpty) {
             await File(path).writeAsBytes(allBytes);
             debugPrint('Saved JPEG to $path');
             completer.complete(path);
          } else {
             debugPrint('JPEG stream was empty');
             completer.complete(null);
          }
        } catch (e) {
          debugPrint('Error reading JPEG from clipboard: $e');
          completer.complete(null);
        }
      });
      
      final imagePath = await completer.future;
      if (imagePath != null && mounted) {
        setState(() {
          _attachments.add(imagePath);
        });
        return;
      }
    }
    
    // Handle Files (e.g. copied from Explorer)
    if (reader.canProvide(Formats.fileUri)) {
       final uri = await reader.readValue(Formats.fileUri);
       if (uri != null) {
          final path = uri.toFilePath();
          if (path.toLowerCase().endsWith('.png') || 
              path.toLowerCase().endsWith('.jpg') || 
              path.toLowerCase().endsWith('.jpeg') || 
              path.toLowerCase().endsWith('.webp')) {
               setState(() {
                 _attachments.add(path);
               });
               return;
          }
       }
    }

    // Handle HTML Format (Extract local image paths)
    if (reader.canProvide(Formats.htmlText)) {
      try {
        final html = await reader.readValue(Formats.htmlText);
        if (html != null) {
          debugPrint('Found HTML format, checking for images...');
          // Regex to find <img src="file:///...">
          final RegExp imgRegex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
          final match = imgRegex.firstMatch(html);
          if (match != null) {
            String src = match.group(1) ?? '';
            if (src.startsWith('file:///')) {
               Uri fileUri = Uri.parse(src);
               String filePath = fileUri.toFilePath();
               // Remove Windows extra slash if needed? Uri.toFilePath handles it usually.
               debugPrint('Extracted image path from HTML: $filePath');
               if (File(filePath).existsSync()) {
                 setState(() {
                   _attachments.add(filePath);
                 });
                 return;
               }
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing HTML clipboard: $e');
      }
    }
    
    // Handle Text (Fix for Win+V)
    if (reader.canProvide(Formats.plainText)) {
      final text = await reader.readValue(Formats.plainText);
      if (text != null && text.isNotEmpty) {
         final selection = _controller.selection;
         final currentText = _controller.text;
         
         String newText;
         int newSelectionIndex;
         
         if (selection.isValid && selection.start >= 0) {
           newText = currentText.replaceRange(selection.start, selection.end, text);
           newSelectionIndex = selection.start + text.length;
         } else {
           // Append if no selection/invalid
           newText = currentText + text;
           newSelectionIndex = newText.length;
         }
         
         _controller.value = TextEditingValue(
           text: newText,
           selection: TextSelection.collapsed(offset: newSelectionIndex),
         );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.trim().isEmpty && _attachments.isEmpty) return;
    
    final currentSessionId = ref.read(selectedHistorySessionIdProvider);

    final finalSessionId = await ref.read(historyChatProvider.notifier).sendMessage(text, attachments: List.from(_attachments));
    
    _controller.clear();
    setState(() {
      _attachments.clear();
    });

    if (currentSessionId == 'new_chat' && finalSessionId != 'new_chat') {
       ref.read(selectedHistorySessionIdProvider.notifier).state = finalSessionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(historyChatProvider);
    // Removed isWindows check - Pure Fluent UI

    return Column(
      children: [
        // Message List
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: ListView.builder(
              key: ValueKey(ref.watch(selectedHistorySessionIdProvider)), // Use Session ID as key for transition
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                final isLast = index == chatState.messages.length - 1;
                return _HistoryMessageBubble(
                  key: ValueKey(msg.id),
                  message: msg, 
                  isLast: isLast
                );
              },
            ),
          ),
        ),
        
        // Attachment Preview
        if (_attachments.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final path = _attachments[index];
                return HoverImagePreview(
                  imagePath: path,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: fluent.FluentTheme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 14),
                        const SizedBox(width: 4),
                        Text(path.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _attachments.removeAt(index)),
                          child: const Icon(Icons.close, size: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Input Area
      Container(
         padding: EdgeInsets.all(Platform.isWindows ? 12 : 8), // Less padding on mobile
         decoration: BoxDecoration(
           border: Border(top: BorderSide(color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault)),
           color: Platform.isWindows 
               ? fluent.FluentTheme.of(context).cardColor
               : Theme.of(context).scaffoldBackgroundColor, // Solid bg on mobile
         ),
         child: Platform.isWindows 
             ? _buildDesktopInputArea(chatState)
             : _buildMobileInputArea(chatState),
      ),
      ],
    );
  }

  // Desktop Input Area (with keyboard shortcuts)
  Widget _buildDesktopInputArea(ChatState chatState) {
    return Column(
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            
            final isControl = HardwareKeyboard.instance.isControlPressed;
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            
            if ((isControl && event.logicalKey == LogicalKeyboardKey.keyV) || 
                (isShift && event.logicalKey == LogicalKeyboardKey.insert)) {
              _handlePaste();
              return KeyEventResult.handled;
            }
            
            if (isControl && event.logicalKey == LogicalKeyboardKey.enter) {
              _sendMessage();
              return KeyEventResult.handled;
            }
            
            return KeyEventResult.ignored;
          },
          child: fluent.TextBox(
            controller: _controller,
            placeholder: '输入消息 (Enter 换行，Ctrl + Enter 发送)',
            maxLines: 3, 
            minLines: 1,
            decoration: const fluent.WidgetStatePropertyAll(fluent.BoxDecoration()), 
            style: const TextStyle(fontSize: 14),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.attach),
              onPressed: _pickFiles,
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.add),
              onPressed: () {
                 ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
              },
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.paste),
              onPressed: _handlePaste,
            ),
            const SizedBox(width: 8),
            fluent.IconButton(
              icon: const fluent.Icon(fluent.FluentIcons.broom),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => fluent.ContentDialog(
                    title: const Text('清空上下文'),
                    content: const Text('确定要清空当前对话的历史记录吗？此操作不可撤销。'),
                    actions: [
                      fluent.Button(
                        child: const Text('取消'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      fluent.FilledButton(
                        child: const Text('确定'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(historyChatProvider.notifier).clearContext();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            if (chatState.isLoading)
              const fluent.ProgressRing(strokeWidth: 2, activeColor: Colors.blue)
            else 
              fluent.IconButton(
                icon: const fluent.Icon(fluent.FluentIcons.send),
                onPressed: _sendMessage,
              ),
          ],
        ),
      ],
    );
  }

  // Mobile Input Area (simple and large)
  Widget _buildMobileInputArea(ChatState chatState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Attachment
            IconButton(
              icon: const Icon(Icons.attach_file, size: 22),
              onPressed: _pickFiles,
              tooltip: '添加附件',
            ),
            // New chat
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              onPressed: () {
                ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
              },
              tooltip: '新对话',
            ),
            // Clear context
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined, size: 22),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空上下文'),
                    content: const Text('确定要清空当前对话的历史记录吗？此操作不可撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(historyChatProvider.notifier).clearContext();
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: '清空上下文',
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Input row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            chatState.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                    iconSize: 26,
                    onPressed: _sendMessage,
                    padding: const EdgeInsets.all(8),
                  ),
          ],
        ),
      ],
    );
  }
    
  bool get _startNewLine => false; 
}

class _HistoryMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isLast;

  const _HistoryMessageBubble({super.key, required this.message, required this.isLast});

  @override
  ConsumerState<_HistoryMessageBubble> createState() => _HistoryMessageBubbleState();
}

class _HistoryMessageBubbleState extends ConsumerState<_HistoryMessageBubble> {
  bool _isHovering = false;
  bool _isEditing = false;
  late TextEditingController _editController;
  final FocusNode _focusNode = FocusNode();
  late List<String> _newAttachments;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _newAttachments = List.from(widget.message.attachments);
    // _focusNode is initialized directly in the class definition
  }
  
  @override
  void didUpdateWidget(_HistoryMessageBubble oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (oldWidget.message.content != widget.message.content) {
        _editController.text = widget.message.content;
     }
     if (oldWidget.message.attachments != widget.message.attachments) {
        if (!_isEditing) {
           _newAttachments = List.from(widget.message.attachments);
        }
     }
  }

  Future<void> _pickFiles() async {
    const typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg', 'bmp', 'gif']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;
    setState(() {
      _newAttachments.addAll(files.map((file) => file.path));
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
          final selection = _editController.selection;
          final currentText = _editController.text;
          if (selection.isValid) {
             final newText = currentText.replaceRange(selection.start, selection.end, text);
             _editController.value = TextEditingValue(
               text: newText,
               selection: TextSelection.collapsed(offset: selection.start + text.length),
             );
          } else {
             _editController.text += text;
          }
       }
       return;
    }
    
    // Fast Fallback: Try using pasteboard package directly (Robust Win+V support)
    // This is moved BEFORE the delay loop because logs showed Pasteboard often works immediately 
    // when super_clipboard fails for Win+V items.
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
         debugPrint('Found image via Pasteboard fallback (Immediate).');
         final tempDir = await getTemporaryDirectory();
         final path = '${tempDir.path}${Platform.pathSeparator}paste_fb_${DateTime.now().millisecondsSinceEpoch}.png';
         await File(path).writeAsBytes(imageBytes);
         if (mounted) {
            setState(() {
               _newAttachments.add(path);
            });
         }
         return; // Success, skip delay loop
      }
    } catch (e) {
      debugPrint('Pasteboard Fallback Error: $e');
    }
    
    // Retry Logic for generic delayed clipboard (only if Pasteboard also failed)
    debugPrint('No immediate format and Pasteboard failed, probing for delay...');
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
                 _newAttachments.add(path);
              });
           }
        }
      } catch (e) {
        debugPrint('Paste Error: $e');
      }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleAction(String action) {
     final msg = widget.message;
     final notifier = ref.read(historyChatProvider.notifier);
     
     switch (action) {
       case 'retry':
          notifier.regenerateResponse(msg.id);
          break;
       case 'edit':
          setState(() { _isEditing = true; });
          WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
          break;
       case 'copy':
          final item = DataWriterItem();
          item.add(Formats.plainText(msg.content));
          SystemClipboard.instance?.write([item]);
          break;
       case 'delete':
          notifier.deleteMessage(msg.id);
          break;
     }
  }

  void _saveEdit() {
     if (_editController.text.trim().isNotEmpty) {
        ref.read(historyChatProvider.notifier).editMessage(
           widget.message.id, 
           _editController.text,
           newAttachments: _newAttachments
        );
     }
     setState(() { _isEditing = false; });
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isUser = message.isUser;
    final settingsState = ref.watch(settingsProvider);
    final theme = fluent.FluentTheme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row( // Message Row
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                   _buildAvatar(
                     avatarPath: settingsState.llmAvatar,
                     fallbackIcon: Icons.smart_toy,
                     backgroundColor: Colors.teal,
                   ),
                   const SizedBox(width: 8),
                ],
                
                Flexible(
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                       // Header Row
                       Padding(
                         padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                         child: Column(
                           crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               isUser 
                                 ? (settingsState.userName.isNotEmpty ? settingsState.userName : '用户')
                                 : '${message.model ?? settingsState.selectedModel} | ${message.provider ?? settingsState.activeProvider?.name ?? 'AI'}', 
                               style: TextStyle(color: Colors.grey[600], fontSize: 12),
                             ),
                             Text(
                               '${message.timestamp.month}/${message.timestamp.day} ${message.timestamp.hour.toString().padLeft(2,'0')}:${message.timestamp.minute.toString().padLeft(2,'0')}',
                               style: TextStyle(color: Colors.grey[600], fontSize: 11),
                             ),
                           ],
                         ),
                       ),
                       // Bubble
                       Container(
                    padding: _isEditing ? EdgeInsets.zero : const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isEditing 
                        ? fluent.Colors.transparent 
                        : (isUser ? theme.accentColor : theme.cardColor),
                      borderRadius: BorderRadius.circular(12),
                      border: _isEditing ? null : Border.all(
                          color: isUser ? theme.accentColor : theme.resources.dividerStrokeColorDefault
                      ),
                    ),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [

                          if (!message.isUser && message.reasoningContent != null && message.reasoningContent!.isNotEmpty)
                             Padding(
                               padding: _isEditing 
                                  ? const EdgeInsets.fromLTRB(12, 0, 12, 8) 
                                  : const EdgeInsets.only(bottom: 8.0),
                               child: ReasoningDisplay(
                                 content: message.reasoningContent!,
                                 isWindows: true, // Force Fluent Style
                                 isRunning: false,
                               ),
                             ),
                          
                          if (_isEditing)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: theme.resources.dividerStrokeColorDefault),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                         if (_newAttachments.isNotEmpty)
                                           Container(
                                             height: 40,
                                             margin: const EdgeInsets.only(bottom: 8),
                                             child: ListView.builder(
                                               scrollDirection: Axis.horizontal,
                                               itemCount: _newAttachments.length,
                                               itemBuilder: (context, index) => Padding(
                                                 padding: const EdgeInsets.only(right: 8),
                                                 child: MouseRegion( // Use specific widget for deleting
                                                   cursor: SystemMouseCursors.click,
                                                   child: GestureDetector(
                                                      onTap: () => setState(() => _newAttachments.removeAt(index)),
                                                      child: Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                         decoration: BoxDecoration(
                                                            color: theme.accentColor.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                                                         ),
                                                         child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                               ConstrainedBox(
                                                                  constraints: const BoxConstraints(maxWidth: 100),
                                                                  child: Text(
                                                                     _newAttachments[index].split(Platform.pathSeparator).last,
                                                                     style: const TextStyle(fontSize: 12),
                                                                     overflow: TextOverflow.ellipsis,
                                                                  ),
                                                               ),
                                                               const SizedBox(width: 4),
                                                               Icon(fluent.FluentIcons.chrome_close, size: 8, color: theme.accentColor),
                                                            ],
                                                         ),
                                                      ),
                                                   ),
                                                 ),
                                               ),
                                             ),
                                           ),
                                         
                                         CallbackShortcuts(
                                           bindings: {
                                              const SingleActivator(LogicalKeyboardKey.keyV, control: true): _handlePaste,
                                           },
                                           child: fluent.TextBox(
                                               controller: _editController,
                                               focusNode: _focusNode,
                                               maxLines: null,
                                               minLines: 1,
                                               placeholder: '编辑消息...',
                                               decoration: null,
                                               highlightColor: fluent.Colors.transparent,
                                               unfocusedColor: fluent.Colors.transparent,
                                               style: TextStyle(
                                                  fontSize: 14, 
                                                  height: 1.5,
                                                  color: theme.typography.body?.color
                                               ),
                                               cursorColor: theme.accentColor,
                                               textInputAction: TextInputAction.send,
                                               onSubmitted: (_) => _saveEdit(),
                                           ),
                                         ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                       // Upload Button
                                       fluent.IconButton(
                                          icon: const Icon(fluent.FluentIcons.attach, size: 14),
                                          onPressed: _pickFiles,
                                          style: fluent.ButtonStyle(
                                              foregroundColor: fluent.ButtonState.resolveWith((states) {
                                                  if (states.isHovering) return fluent.Colors.blue;
                                                  return fluent.Colors.grey;
                                              }),
                                          ),
                                       ),
                                       const SizedBox(width: 8),

                                       _ActionButton(
                                          icon: fluent.FluentIcons.cancel, 
                                          tooltip: 'Cancel', 
                                          onPressed: () => setState(() => _isEditing = false)
                                       ),
                                       const SizedBox(width: 4),
                                       _ActionButton(
                                          icon: fluent.FluentIcons.save, 
                                          tooltip: 'Save', 
                                          onPressed: _saveEdit
                                       ),
                                       if (message.isUser) ...[
                                          const SizedBox(width: 4),
                                          _ActionButton(
                                             icon: fluent.FluentIcons.send, 
                                             tooltip: 'Send & Regenerate', 
                                             onPressed: () {
                                                 _saveEdit();
                                                 ref.read(historyChatProvider.notifier).regenerateResponse(message.id);
                                             }
                                          ),
                                       ],
                                    ],
                                  ),
                                ],
                              )
                          else
                             fluent.FluentTheme(
                               data: theme,
                               child: SelectionArea(
                                 child: MarkdownBody(
                                   data: message.content,
                                   selectable: false, // Handled by SelectionArea
                                   styleSheet: MarkdownStyleSheet(
                                     p: TextStyle(
                                       fontSize: 14, 
                                       height: 1.5,
                                       color: isUser ? Colors.white : theme.typography.body!.color,
                                     ),
                                     code: TextStyle(
                                       backgroundColor: isUser ? Colors.white.withOpacity(0.2) : theme.micaBackgroundColor,
                                       color: isUser ? Colors.white : theme.typography.body!.color,
                                     ),
                                   ),
                                 ),
                               ),
                             ),

                          if (message.images.isNotEmpty && !(isUser && _isEditing)) ...[
                             const SizedBox(height: 8),
                             Wrap(
                               spacing: 8,
                               runSpacing: 8,
                               children: message.images.map((img) => ChatImageBubble(
                                 imageUrl: img,
                               )).toList(),
                             ),
                          ],
                       ],
                    ),
                  ),
                ],  // Close outer Column children
              ),  // Close outer Column
            ),  // Close Flexible


                
                if (isUser) ...[
                   const SizedBox(width: 8),
                   _buildAvatar(
                     avatarPath: settingsState.userAvatar,
                     fallbackIcon: Icons.person,
                     backgroundColor: Colors.blue,
                   ),
                ],
              ],
            ),
            
            // Action Toolbar - Always visible on mobile, hover on desktop
            Platform.isWindows
                ? Visibility(
                    visible: _isHovering && !_isEditing,
                    maintainSize: true, 
                    maintainAnimation: true,
                    maintainState: true,
                    child: Padding(
                      padding: EdgeInsets.only(
                         top: 4, 
                         left: isUser ? 0 : 40, 
                         right: isUser ? 40 : 0
                      ),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                           _ActionButton(icon: fluent.FluentIcons.refresh, tooltip: 'Retry', onPressed: () => _handleAction('retry')),
                           const SizedBox(width: 4),
                           _ActionButton(icon: fluent.FluentIcons.edit, tooltip: 'Edit', onPressed: () => _handleAction('edit')),
                           const SizedBox(width: 4),
                           _ActionButton(icon: fluent.FluentIcons.copy, tooltip: 'Copy', onPressed: () => _handleAction('copy')),
                           const SizedBox(width: 4),
                           _ActionButton(icon: fluent.FluentIcons.delete, tooltip: 'Delete', onPressed: () => _handleAction('delete')),
                        ],
                      ),
                    ),
                  )
                // Mobile: Always visible action buttons
                : _isEditing
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsets.only(
                          top: 4, 
                          left: isUser ? 0 : 40, 
                          right: isUser ? 40 : 0
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            _MobileActionButton(
                              icon: Icons.refresh,
                              onPressed: () => _handleAction('retry'),
                            ),
                            _MobileActionButton(
                              icon: Icons.edit_outlined,
                              onPressed: () => _handleAction('edit'),
                            ),
                            _MobileActionButton(
                              icon: Icons.copy_outlined,
                              onPressed: () => _handleAction('copy'),
                            ),
                            _MobileActionButton(
                              icon: Icons.delete_outline,
                              onPressed: () => _handleAction('delete'),
                            ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String? avatarPath,
    required IconData fallbackIcon,
    required Color backgroundColor,
  }) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 32,
          height: 32,
          child: Image.file(
            File(avatarPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: 16,
              backgroundColor: backgroundColor,
              child: Icon(fallbackIcon, size: 16, color: Colors.white),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: backgroundColor,
      child: Icon(fallbackIcon, size: 16, color: Colors.white),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return fluent.Tooltip(
      message: tooltip,
      child: fluent.IconButton(
        icon: fluent.Icon(icon, size: 14),
        onPressed: onPressed,
      ),
    );
  }
}

// --- Public Widgets for Mobile UI ---

/// Public session list widget for use in mobile drawer
class SessionListWidget extends ConsumerWidget {
  final SessionsState sessionsState;
  final String? selectedSessionId;
  final Function(String sessionId) onSessionSelected;
  final Function(String sessionId) onSessionDeleted;

  const SessionListWidget({
    super.key,
    required this.sessionsState,
    required this.selectedSessionId,
    required this.onSessionSelected,
    required this.onSessionDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(sessionSearchQueryProvider).toLowerCase();
    
    if (sessionsState.isLoading && sessionsState.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter sessions by search query
    final filteredSessions = searchQuery.isEmpty 
        ? sessionsState.sessions 
        : sessionsState.sessions.where((s) => 
            s.title.toLowerCase().contains(searchQuery) ||
            (s.snippet?.toLowerCase().contains(searchQuery) ?? false)
          ).toList();

    if (filteredSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            searchQuery.isEmpty ? '暂无对话历史' : '未找到匹配的对话',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        final isSelected = session.sessionId == selectedSessionId;

        return ListTile(
          selected: isSelected,
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            DateFormat('MM/dd HH:mm').format(session.lastMessageTime),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => onSessionDeleted(session.sessionId),
          ),
          onTap: () => onSessionSelected(session.sessionId),
        );
      },
    );
  }
}

/// Public chat body widget for mobile UI (reuses _HistoryChatView internally)
class MobileChatBody extends ConsumerWidget {
  const MobileChatBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Directly use the private _HistoryChatView which handles all chat logic
    return const _HistoryChatView();
  }
}

/// Mobile action button for message bubble actions
class _MobileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MobileActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: Colors.grey[600]),
        onPressed: onPressed,
      ),
    );
  }
}
