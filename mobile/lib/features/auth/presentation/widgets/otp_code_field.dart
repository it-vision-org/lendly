import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A 6-digit code entry field, rendered as boxes but backed by a single real
/// (invisible) [TextField]. This is the standard robust approach for custom
/// OTP UIs in Flutter: paste-anywhere-in-the-row, [AutofillHints.oneTimeCode]
/// suggestions, and stripping non-digit characters (so a copied code like
/// "482 193" normalizes to "482193") all come for free on one field, instead
/// of juggling focus across 6 separate fields.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.length,
    required this.onCompleted,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _completedFired = false;

  /// The digits entered so far.
  String get code => _controller.text;

  /// Clears the entered code, e.g. after a failed verification attempt.
  void clear() {
    _controller.clear();
    _completedFired = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      if (!_completedFired) {
        _completedFired = true;
        widget.onCompleted(value);
      }
    } else {
      _completedFired = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AutofillGroup(
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                final value = _controller.text;
                final filled = index < value.length;
                final isActive = widget.enabled && index == value.length;

                return Container(
                  width: 46,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? value[index] : '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: true,
                showCursor: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: _handleChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
