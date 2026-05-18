part of 'settings_content.dart';

class _ApiKeyItem extends StatefulWidget {
  final String apiKey;
  final ValueChanged<String> onUpdate;

  const _ApiKeyItem({
    super.key,
    required this.apiKey,
    required this.onUpdate,
  });

  @override
  State<_ApiKeyItem> createState() => _ApiKeyItemState();
}

class _ApiKeyItemState extends State<_ApiKeyItem> {
  late TextEditingController _controller;
  bool _isVisible = false;
  bool _isDirty = false;
  late String _lastCommittedValue;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _lastCommittedValue = widget.apiKey;
    _controller = TextEditingController(text: widget.apiKey);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitDraft();
      }
    });
  }

  @override
  void didUpdateWidget(_ApiKeyItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus && _isDirty) {
      return;
    }
    _lastCommittedValue = widget.apiKey;
    if (widget.apiKey != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.apiKey,
        selection: TextSelection.collapsed(offset: widget.apiKey.length),
        composing: TextRange.empty,
      );
    }
    if (_isDirty) {
      setState(() {
        _isDirty = false;
      });
    }
  }

  void _handleChanged(String value) {
    final nextDirty = value != _lastCommittedValue;
    if (nextDirty == _isDirty) {
      return;
    }
    setState(() {
      _isDirty = nextDirty;
    });
  }

  void _commitDraft() {
    final nextValue = _controller.text;
    if (nextValue == _lastCommittedValue) {
      if (_isDirty) {
        setState(() {
          _isDirty = false;
        });
      }
      return;
    }

    _lastCommittedValue = nextValue;
    widget.onUpdate(nextValue);
    if (!mounted) {
      return;
    }
    setState(() {
      _isDirty = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return fluent.TextBox(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: !_isVisible,
      onChanged: _handleChanged,
      onSubmitted: (_) => _commitDraft(),
      onTapOutside: (_) => _commitDraft(),
      placeholder: l10n.apiKeyPlaceholder,
      suffix: fluent.IconButton(
        icon: fluent.Icon(
          _isVisible ? AuroraIcons.visibilityOff : AuroraIcons.visibility,
          size: 14,
        ),
        onPressed: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
      ),
      decoration: WidgetStateProperty.all(BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.transparent),
      )),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        letterSpacing: _isVisible ? 0 : 2,
      ),
      highlightColor: Colors.transparent,
      unfocusedColor: Colors.transparent,
    );
  }
}
