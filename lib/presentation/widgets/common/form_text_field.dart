import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final bool isValid;
  final Widget? prefixIcon;
  final List<Widget>? suffixActions;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  const FormTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.errorText,
    this.isValid = true,
    this.prefixIcon,
    this.suffixActions,
    this.onClear,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: prefixIcon,
        suffixIcon: _buildSuffixIcon(colorScheme),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        errorText: errorText,
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme) {
    final actions = <Widget>[];

    if (onClear != null && controller.text.isNotEmpty) {
      actions.add(
        IconButton(
          onPressed: onClear,
          icon: Icon(Icons.clear_rounded, color: colorScheme.onSurface),
        ),
      );
    }

    if (suffixActions != null) {
      actions.addAll(suffixActions!);
    }

    if (actions.isEmpty) return null;

    if (actions.length == 1) {
      return actions.first;
    }

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

class FormFieldContainer extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool isRequired;
  final Widget? trailing;
  final Widget child;
  final String? helperText;
  final String? additionalInfo;
  final bool isValid;

  const FormFieldContainer({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.isRequired = false,
    this.trailing,
    this.helperText,
    this.additionalInfo,
    this.isValid = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 12),
        child,
        if (helperText != null || additionalInfo != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (helperText != null)
                  Expanded(
                    child: Text(
                      helperText!,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                if (additionalInfo != null)
                  Text(
                    additionalInfo!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isValid
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
