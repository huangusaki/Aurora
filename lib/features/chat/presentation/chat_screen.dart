import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_legacy.dart';
import 'desktop/desktop_chat_screen.dart';
import 'mobile/mobile_chat_screen.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PlatformUtils.isDesktop) {
      return const DesktopChatScreen();
    } else {
      return const MobileChatScreen();
    }
  }
}


