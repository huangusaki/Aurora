import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../settings/domain/chat_preset.dart';
import '../../settings/presentation/settings_provider.dart';

class PresetManageDialog extends ConsumerStatefulWidget {
  const PresetManageDialog({super.key});
  @override
  ConsumerState<PresetManageDialog> createState() => _PresetManageDialogState();
}

class _PresetManageDialogState extends ConsumerState<PresetManageDialog> {
  ChatPreset? _editingPreset;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  void _startEdit(ChatPreset? preset) {
    setState(() {
      _editingPreset = preset;
      if (preset != null) {
        _nameController.text = preset.name;
        _descController.text = preset.description;
        _promptController.text = preset.systemPrompt;
      } else {
        _nameController.clear();
        _descController.clear();
        _promptController.clear();
      }
    });
  }

  void _save() {
    if (_nameController.text.isEmpty || _promptController.text.isEmpty) return;
    final name = _nameController.text;
    final desc = _descController.text;
    final prompt = _promptController.text;
    if (_editingPreset != null) {
      final updated = _editingPreset!.copyWith(
        name: name,
        description: desc,
        systemPrompt: prompt,
      );
      ref.read(settingsProvider.notifier).updatePreset(updated);
    } else {
      final newPreset = ChatPreset.create(
        name: name,
        description: desc,
        systemPrompt: prompt,
      );
      ref.read(settingsProvider.notifier).addPreset(newPreset);
    }
    setState(() {
      _editingPreset = null;
    });
  }

  void _delete(String id) {
    ref.read(settingsProvider.notifier).deletePreset(id);
    if (_editingPreset?.id == id) {
      setState(() {
        _editingPreset = null;
      });
    }
  }

  void _insertVariable(String variable) {
    final text = _promptController.text;
    final selection = _promptController.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText =
          text.replaceRange(selection.start, selection.end, variable);
      _promptController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + variable.length),
      );
    } else {
      _promptController.text += variable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(settingsProvider).presets;
    return ContentDialog(
      title: const Text('Manage Presets'),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Column(
              children: [
                Button(
                  child: const Text('+ New Preset'),
                  onPressed: () => _startEdit(null),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final isSelected = _editingPreset?.id == preset.id;
                      return ListTile(
                        title:
                            Text(preset.name, overflow: TextOverflow.ellipsis),
                        onPressed: () => _startEdit(preset),
                        trailing: IconButton(
                          icon: const Icon(AuroraIcons.delete),
                          onPressed: () => _delete(preset.id),
                        ),
                        tileColor: isSelected
                            ? ButtonState.all(FluentTheme.of(context)
                                .accentColor
                                .withOpacity(0.1))
                            : ButtonState.all(Colors.transparent),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                TextBox(
                  controller: _nameController,
                  placeholder: 'Name',
                ),
                const SizedBox(height: 8),
                TextBox(
                  controller: _descController,
                  placeholder: 'Description (optional)',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextBox(
                    controller: _promptController,
                    placeholder: 'System Prompt',
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Button(
                      child: const Text('{time}'),
                      onPressed: () => _insertVariable('{time}'),
                    ),
                    Button(
                      child: const Text('{user_name}'),
                      onPressed: () => _insertVariable('{user_name}'),
                    ),
                    Button(
                      child: const Text('{system}'),
                      onPressed: () => _insertVariable('{system}'),
                    ),
                    Button(
                      child: const Text('{device}'),
                      onPressed: () => _insertVariable('{device}'),
                    ),
                    Button(
                      child: const Text('{language}'),
                      onPressed: () => _insertVariable('{language}'),
                    ),
                    Button(
                      child: const Text('{clipboard}'),
                      onPressed: () => _insertVariable('{clipboard}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _save,
                  child: Text(_editingPreset == null ? 'Create' : 'Save'),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
