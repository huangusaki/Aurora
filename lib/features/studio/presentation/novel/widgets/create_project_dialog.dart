import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../novel_provider.dart';
import '../novel_state.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  ConsumerState<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _nameController = TextEditingController();
  
  // World Context Flags
  bool _includeRules = true;
  bool _includeCharacters = true;
  bool _includeRelationships = true;
  bool _includeLocations = true;
  bool _includeForeshadowing = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final initialContext = WorldContext(
        // Always enable all flags in the context object as per design preference:
        // "勾选的分类会在写作时自动携带" means these flags control prompt injection.
        // We set initial state based on user selection.
        includeRules: _includeRules,
        includeCharacters: _includeCharacters,
        includeRelationships: _includeRelationships,
        includeLocations: _includeLocations,
        includeForeshadowing: _includeForeshadowing,
      );

      ref.read(novelProvider.notifier).createProject(name, worldContext: initialContext);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
      title: Text(l10n.createProject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: World Settings
          Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.resources.layerFillColorAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AuroraIcons.database, size: 16),
                    const SizedBox(width: 8),
                    Text(l10n.worldSettings, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCheckbox(l10n.worldRules, _includeRules, (v) => setState(() => _includeRules = v!)),
                const SizedBox(height: 8),
                _buildCheckbox(l10n.characterSettings, _includeCharacters, (v) => setState(() => _includeCharacters = v!)),
                const SizedBox(height: 8),
                _buildCheckbox(l10n.relationships, _includeRelationships, (v) => setState(() => _includeRelationships = v!)),
                const SizedBox(height: 8),
                _buildCheckbox(l10n.locations, _includeLocations, (v) => setState(() => _includeLocations = v!)),
                const SizedBox(height: 8),
                _buildCheckbox(l10n.foreshadowing, _includeForeshadowing, (v) => setState(() => _includeForeshadowing = v!)),
                
                constSpacer(),
                Text(
                  l10n.autoIncludeHint, // "勾选的分类会在写作时自动携带"
                  style: theme.typography.caption?.copyWith(fontSize: 10, color: theme.inactiveColor),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Right Side: Project Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48), // Spacer to align visually with the center area
                Text(l10n.novelName, style: theme.typography.body), // Optional label
                const SizedBox(height: 8),
                TextBox(
                  controller: _nameController,
                  placeholder: l10n.novelName,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  padding: const EdgeInsets.all(12),
                  onSubmitted: (_) => _submit(context),
                ),
                // Can add more fields here later if needed
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: Text(l10n.close),
          onPressed: () => Navigator.pop(context),
        ),
        FilledButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(theme.accentColor),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 8)),
          ),
          child: Text(l10n.add),
          onPressed: () => _submit(context),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Checkbox(
      checked: value,
      onChanged: onChanged,
      content: Text(label),
    );
  }
  
  Widget constSpacer() => const Spacer();
}
