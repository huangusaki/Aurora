import 'dart:io';

import 'package:flutter/material.dart';

class ChatMessageAvatar extends StatelessWidget {
  const ChatMessageAvatar({
    super.key,
    required this.fallbackIcon,
    required this.backgroundColor,
    this.avatarPath,
  });

  final String? avatarPath;
  final IconData fallbackIcon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 32,
          height: 32,
          child: Image.file(
            File(avatarPath!),
            fit: BoxFit.cover,
            cacheWidth: 64,
            cacheHeight: 64,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
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
