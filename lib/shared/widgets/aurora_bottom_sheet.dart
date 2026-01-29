import 'package:flutter/material.dart';

class AuroraBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar

              Flexible(child: builder(context)),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    String? content,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return show<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (content != null) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(cancelText ?? '取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: isDestructive
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          )
                        : null,
                    child: Text(confirmText ?? '确定'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    String? confirmText,
    String? cancelText,
    bool autofocus = true,
  }) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: initialValue);
    return show<String>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: autofocus,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.cardColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(cancelText ?? '取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, controller.text.trim()),
                      child: Text(confirmText ?? '确定'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildTitle(BuildContext context, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (trailing != null)
            Positioned(
              right: 0,
              child: trailing,
            ),
        ],
      ),
    );
  }

  static Widget buildListItem({
    required BuildContext context,
    required Widget title,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: leading,
      title: title,
      trailing: trailing,
      selected: selected,
      selectedColor: theme.primaryColor,
      onTap: onTap,
    );
  }
}
