import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../../settings/domain/chat_preset.dart';
import '../../settings/presentation/settings_provider.dart';

class PresetSettingsPage extends ConsumerStatefulWidget {
  const PresetSettingsPage({super.key});

  @override
  ConsumerState<PresetSettingsPage> createState() => _PresetSettingsPageState();
}

class _PresetSettingsPageState extends ConsumerState<PresetSettingsPage> {
  ChatPreset? _editingPreset;
  // Use a flag to track if we are in "create mode" (editing a new unsaved preset)
  bool _isCreating = false; 

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  void _startEdit(ChatPreset? preset) {
    setState(() {
      if (preset != null) {
        _editingPreset = preset;
        _isCreating = false;
        _nameController.text = preset.name;
        _descController.text = preset.description;
        _promptController.text = preset.systemPrompt;
      } else {
        // Create mode: Create a dummy preset object or just use the flag + empty controllers
        _isCreating = true;
        _editingPreset = null; // No existing ID to track
        _nameController.text = '';
        _descController.text = '';
        _promptController.text = '';
      }
    });
  }

  void _save() {
    if (_nameController.text.isEmpty || _promptController.text.isEmpty) return;

    final name = _nameController.text;
    final desc = _descController.text;
    final prompt = _promptController.text;

    if (_editingPreset != null && !_isCreating) {
      // Update
      final updated = _editingPreset!.copyWith(
        name: name,
        description: desc,
        systemPrompt: prompt,
      );
      ref.read(settingsProvider.notifier).updatePreset(updated);
       setState(() {
         _editingPreset = updated;
       });
    } else {
      // Create
      final newPreset = ChatPreset.create(
        name: name,
        description: desc,
        systemPrompt: prompt,
      );
      ref.read(settingsProvider.notifier).addPreset(newPreset);
      setState(() {
        _isCreating = false;
        _editingPreset = newPreset; // Select the newly created one
      });
    }
  }

  void _delete(String id) {
    ref.read(settingsProvider.notifier).deletePreset(id);
    if (_editingPreset?.id == id) {
      setState(() {
        _editingPreset = null;
        _isCreating = false;
        _nameController.text = '';
        _descController.text = '';
        _promptController.text = '';
      });
    }
  }
  
  void _deleteCurrent() {
    if (_editingPreset != null) {
      _delete(_editingPreset!.id);
    }
    // If creating, just clear
    if (_isCreating) {
         setState(() {
        _isCreating = false;
        _nameController.text = '';
        _descController.text = '';
        _promptController.text = '';
      });
    }
  }

  void _insertVariable(String variable) {
    final text = _promptController.text;
    final selection = _promptController.selection;
    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, variable);
      _promptController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + variable.length),
      );
    } else {
      _promptController.text += variable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final presets = ref.watch(settingsProvider).presets;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar List
        Container(
          width: 220,
           decoration: BoxDecoration(
            border: Border(right: BorderSide(color: theme.resources.dividerStrokeColorDefault)),
          ),
          child: Column(
            children: [
               Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                   width: double.infinity,
                   child: Button(
                    child: Text(l10n.newPreset),
                    onPressed: () => _startEdit(null),
                   ),
                ),
               ),
               Expanded(
                 child: ListView.builder(
                   padding: const EdgeInsets.symmetric(horizontal: 4),
                   itemCount: presets.length,
                   itemBuilder: (context, index) {
                     final preset = presets[index];
                     final isSelected = _editingPreset?.id == preset.id;
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 2),
                       child: ListTile(
                         title: Text(preset.name, overflow: TextOverflow.ellipsis),
                         onPressed: () => _startEdit(preset),
                         trailing: IconButton(
                           icon: const Icon(FluentIcons.delete),
                           onPressed: () => _delete(preset.id),
                         ),
                         tileColor: isSelected 
                            ? ButtonState.all(theme.accentColor.withOpacity(0.1))
                            : ButtonState.all(Colors.transparent),
                       ),
                     );
                   },
                 ),
               ),
            ],
          ),
        ),
        // Main Edit Area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Show editor if editing existing preset OR if explicitly creating new one
                 if (_editingPreset != null || _isCreating) ...[
                     Text(_isCreating ? l10n.newPreset : l10n.editPreset, style: theme.typography.subtitle),
                     const SizedBox(height: 16),
                     InfoLabel(
                       label: l10n.presetName,
                       child: TextBox(
                         controller: _nameController,
                         placeholder: l10n.presetNamePlaceholder,
                       ),
                     ),
                     const SizedBox(height: 16),
                     InfoLabel(
                       label: l10n.presetDescription,
                       child: TextBox(
                         controller: _descController,
                         placeholder: l10n.presetDescriptionPlaceholder,
                       ),
                     ),
                     const SizedBox(height: 16),
                     Expanded(
                       child: InfoLabel(
                         label: l10n.systemPrompt,
                         child: TextBox(
                           controller: _promptController,
                           maxLines: null,
                           expands: true,
                           textAlignVertical: TextAlignVertical.top,
                           placeholder: l10n.systemPromptPlaceholder,
                         ),
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
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         if (!_isCreating && _editingPreset != null)
                           Padding(
                             padding: const EdgeInsets.only(right: 8.0),
                             child: Button(
                               onPressed: _deleteCurrent,
                               child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
                             ),
                           ),
                         FilledButton(
                           onPressed: _save,
                           child: Text(l10n.savePreset),
                         ),
                       ],
                     ),
                 ] else ...[
                   Center(
                     child: Text(
                       l10n.selectPresetHint,
                       style: TextStyle(color: theme.resources.textFillColorSecondary),
                     ),
                   ),
                 ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
