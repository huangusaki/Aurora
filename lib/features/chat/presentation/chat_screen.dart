import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'desktop/desktop_chat_screen.dart';
import 'mobile/mobile_chat_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWindows = !kIsWeb && Platform.isWindows;
    if (isWindows) {
      return const DesktopChatScreen();
    } else {
      return const MobileChatScreen();
    }
  }
}
