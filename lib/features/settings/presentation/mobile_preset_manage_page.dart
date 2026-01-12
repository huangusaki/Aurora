import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../../settings/domain/chat_preset.dart';
import '../../settings/presentation/settings_provider.dart';

class MobilePresetManagePage extends ConsumerWidget {
  const MobilePresetManagePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(settingsProvider).presets;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePresets),
      ),
      body: presets.isEmpty
          ? Center(
              child: Text(
                l10n.noPresets,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                return ListTile(
                  title: Text(preset.name),
                  subtitle: preset.description.isNotEmpty
                      ? Text(preset.description,
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MobilePresetEditPage(preset: preset),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.deletePreset),
                          content:
                              Text(l10n.deletePresetConfirmation(preset.name)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .deletePreset(preset.id);
                                Navigator.pop(context);
                              },
                              child: Text(l10n.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MobilePresetEditPage(preset: null),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MobilePresetEditPage extends ConsumerStatefulWidget {
  final ChatPreset? preset;
  const MobilePresetEditPage({super.key, required this.preset});
  @override
  ConsumerState<MobilePresetEditPage> createState() =>
      _MobilePresetEditPageState();
}

class _MobilePresetEditPageState extends ConsumerState<MobilePresetEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _nameController.text = widget.preset!.name;
      _descController.text = widget.preset!.description;
      _promptController.text = widget.preset!.systemPrompt;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isEmpty || _promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.fillRequiredFields)),
      );
      return;
    }
    final name = _nameController.text;
    final desc = _descController.text;
    final prompt = _promptController.text;
    if (widget.preset != null) {
      final updated = widget.preset!.copyWith(
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
    Navigator.pop(context);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? l10n.newPreset : l10n.editPreset),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.presetName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.presetDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.systemPrompt,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _VariableChip(
                      label: '{time}', onTap: () => _insertVariable('{time}')),
                  _VariableChip(
                      label: '{user_name}',
                      onTap: () => _insertVariable('{user_name}')),
                  _VariableChip(
                      label: '{system}',
                      onTap: () => _insertVariable('{system}')),
                  _VariableChip(
                      label: '{device}',
                      onTap: () => _insertVariable('{device}')),
                  _VariableChip(
                      label: '{language}',
                      onTap: () => _insertVariable('{language}')),
                  _VariableChip(
                      label: '{clipboard}',
                      onTap: () => _insertVariable('{clipboard}')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              textAlignVertical: TextAlignVertical.top,
            ),
          ],
        ),
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _VariableChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
