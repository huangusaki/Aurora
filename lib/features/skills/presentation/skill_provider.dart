import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/skill_entity.dart';
import '../data/skill_parser.dart';
import '../../settings/presentation/settings_provider.dart';

class SkillState {
  final List<Skill> skills;
  final bool isLoading;
  final String? error;
  final String? skillsDirectory;

  const SkillState({
    this.skills = const [],
    this.isLoading = false,
    this.error,
    this.skillsDirectory,
  });

  SkillState copyWith({
    List<Skill>? skills,
    bool? isLoading,
    String? error,
    String? skillsDirectory,
  }) {
    return SkillState(
      skills: skills ?? this.skills,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      skillsDirectory: skillsDirectory ?? this.skillsDirectory,
    );
  }
}

class SkillNotifier extends StateNotifier<SkillState> {
  SkillNotifier() : super(const SkillState());

  Future<void> loadSkills(String directoryPath, {String? language}) async {
    if (directoryPath.isEmpty) return;
    
    state = state.copyWith(isLoading: true, skillsDirectory: directoryPath);
    
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        state = state.copyWith(isLoading: false, error: 'Directory does not exist');
        return;
      }

      final skills = <Skill>[];
      final entities = dir.listSync();
      
      for (final entity in entities) {
        if (entity is Directory) {
          final skill = await SkillParser.parse(entity, language: language);
          if (skill != null) {
            skills.add(skill);
          }
        }
      }

      // Sort: Locked skills first, then by name
      skills.sort((a, b) {
        if (a.isLocked && !b.isLocked) return -1;
        if (!a.isLocked && b.isLocked) return 1;
        return a.name.compareTo(b.name);
      });

      state = state.copyWith(skills: skills, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh({String? language}) {
    if (state.skillsDirectory != null) {
      loadSkills(state.skillsDirectory!, language: language);
    }
  }

  Future<void> createSkill(String folderName) async {
    if (state.skillsDirectory == null || folderName.isEmpty) return;

    try {
      final skillDir = Directory('${state.skillsDirectory}/$folderName');
      if (await skillDir.exists()) {
        throw Exception('Skill directory already exists');
      }

      await skillDir.create(recursive: true);
      
      final skillFile = File('${skillDir.path}/SKILL.md');
      const boilerplate = '''---
id: {{id}}
name: "{{name}}"
description: "Brief description of the skill."
tools:
  - name: my_tool
    description: "Description of what this tool does."
    type: shell
    command: "echo Hello from {{name}}!"
    input_schema:
      type: object
      properties:
        param1:
          type: string
          description: "A sample parameter"
      required: [param1]
---

# Instruction for Assistant
Describe how and when the assistant should use this skill.
''';

      final content = boilerplate
          .replaceAll('{{id}}', folderName.replaceAll(' ', '_').toLowerCase())
          .replaceAll('{{name}}', folderName);
          
      await skillFile.writeAsString(content);
      refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create skill: $e');
    }
  }

  Future<String> getSkillMarkdown(Skill skill) async {
    try {
      final file = File('${skill.path}/SKILL.md');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> saveSkill(Skill skill, String content) async {
    try {
      final file = File('${skill.path}/SKILL.md');
      await file.writeAsString(content);
      refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to save skill: $e');
    }
  }

  Future<void> deleteSkill(Skill skill) async {
    try {
      final dir = Directory(skill.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete skill: $e');
    }
  }

  Future<void> toggleSkill(Skill skill) async {
    try {
      final file = File('${skill.path}/SKILL.md');
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final newValue = !skill.isEnabled;

      // Update or add the enabled field in frontmatter
      final parts = content.split('---');
      if (parts.length < 3) return;

      var yamlPart = parts[1];
      if (yamlPart.contains('enabled:')) {
        yamlPart = yamlPart.replaceFirst(RegExp(r'enabled:\s*(true|false)'), 'enabled: $newValue');
      } else {
        yamlPart = '$yamlPart\nenabled: $newValue';
      }

      final newContent = '---$yamlPart---${parts.sublist(2).join('---')}';
      await file.writeAsString(newContent);
      refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle skill: $e');
    }
  }
}

final skillProvider = StateNotifierProvider<SkillNotifier, SkillState>((ref) {
  return SkillNotifier();
});
