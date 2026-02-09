import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum AvatarOwner {
  assistant,
  user,
  llm,
}

class AvatarStorage {
  const AvatarStorage._();

  static Future<String> persistAvatar({
    required String sourcePath,
    required AvatarOwner owner,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Avatar source file not found', sourcePath);
    }

    final supportDir = await getApplicationSupportDirectory();
    final avatarDir = Directory(p.join(supportDir.path, 'avatars'));
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final extension = _normalizeExtension(sourcePath);
    final fileName =
        'avatar_${owner.name}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = p.join(avatarDir.path, fileName);

    final normalizedSource = p.normalize(source.path);
    final normalizedTarget = p.normalize(targetPath);
    if (normalizedSource.toLowerCase() == normalizedTarget.toLowerCase()) {
      return normalizedTarget;
    }

    await source.copy(targetPath);
    return targetPath;
  }

  static String _normalizeExtension(String path) {
    final extension = p.extension(path).trim().toLowerCase();
    if (extension.isEmpty) {
      return '.png';
    }
    if (!RegExp(r'^\.[a-z0-9]{1,7}$').hasMatch(extension)) {
      return '.png';
    }
    return extension;
  }
}
