import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';

/// Soft-Neumorphic Recessed Input Field
/// Simulates a softly sunken cavity on mint/off-white background with clear focus & error states.
class NeumorphicInput extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final String? helperText;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;

  const NeumorphicInput({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.helperText,
    this.isDense = false,
    this.contentPadding,
  });

  @override
  State<NeumorphicInput> createState() => _NeumorphicInputState();
}

class _NeumorphicInputState extends State<NeumorphicInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorText != null && _errorText!.isNotEmpty;

    final Color fillColor = hasError
        ? ClinovaColors.errorLight
        : (_isFocused
            ? ClinovaColors.inputRecessedFillFocused
            : ClinovaColors.inputRecessedFill);

    final List<BoxShadow> recessedShadows = hasError
        ? [
            BoxShadow(
              color: ClinovaColors.error.withValues(alpha: 0.08),
              offset: const Offset(2, 2.5),
              blurRadius: 5,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              offset: const Offset(-2, -2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ]
        : (_isFocused
            ? ClinovaColors.focusedRecessedShadow
            : ClinovaColors.recessedShadow);

    Border border;
    if (hasError) {
      border = Border.all(color: ClinovaColors.error, width: 1.2);
    } else if (_isFocused) {
      border = Border.all(
        color: ClinovaColors.primaryAccent.withValues(alpha: 0.65),
        width: 1.2,
      );
    } else {
      border = Border.all(
        color: ClinovaColors.secondaryBackground.withValues(alpha: 0.45),
        width: 0.8,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: widget.isDense ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: ClinovaColors.primaryText,
          ),
        ),
        SizedBox(height: widget.isDense ? 5 : 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(widget.isDense ? 13 : 16),
            border: border,
            boxShadow: recessedShadows,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onChanged: (val) {
              if (hasError) {
                setState(() {
                  _errorText = null;
                });
              }
              widget.onChanged?.call(val);
            },
            validator: (value) {
              final result = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _errorText != result) {
                  setState(() {
                    _errorText = result;
                  });
                }
              });
              return result;
            },
            style: TextStyle(
              fontSize: widget.isDense ? 14 : 15,
              fontWeight: FontWeight.w500,
              color: ClinovaColors.primaryText,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: ClinovaColors.tertiaryText,
                fontSize: widget.isDense ? 13 : 14,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: widget.contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: widget.isDense ? 11 : 15,
                  ),
              errorStyle: const TextStyle(
                color: ClinovaColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? ClinovaColors.primaryAccent
                          : ClinovaColors.secondaryAccent,
                      size: widget.isDense ? 19 : 21,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              widget.helperText!,
              style: TextStyle(
                color: ClinovaColors.secondaryText,
                fontSize: widget.isDense ? 11 : 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
