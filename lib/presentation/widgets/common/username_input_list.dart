import 'package:flutter/material.dart';
import 'form_text_field.dart';
import 'validation_mixin.dart';

class UsernameInputList extends StatefulWidget {
  final List<TextEditingController> controllers;
  final Function(bool hasValid) onValidationChanged;
  final Function(int index) onRemove;
  final VoidCallback onAdd;

  const UsernameInputList({
    super.key,
    required this.controllers,
    required this.onValidationChanged,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  State<UsernameInputList> createState() => _UsernameInputListState();
}

class _UsernameInputListState extends State<UsernameInputList>
    with ValidationMixin {
  void _onUsernamesChanged() {
    final hasValid = widget.controllers.any(
      (controller) => validateUsername(controller.text),
    );
    widget.onValidationChanged(hasValid);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormFieldContainer(
      icon: Icon(Icons.person_rounded, size: 18, color: colorScheme.primary),
      title: 'Usernames',
      isRequired: true,
      trailing: TextButton.icon(
        onPressed: widget.onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add User'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      helperText: 'Enter usernames of users to send messages to',
      additionalInfo: '${widget.controllers.length} users',
      isValid: widget.controllers.any((c) => validateUsername(c.text)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.controllers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final controller = widget.controllers[index];
          final isValid = validateUsername(controller.text);

          return _UsernameInputField(
            controller: controller,
            index: index,
            isValid: isValid,
            onChanged: (_) => _onUsernamesChanged(),
            onRemove: widget.controllers.length > 1
                ? () => widget.onRemove(index)
                : null,
            validationMixin: this,
          );
        },
      ),
    );
  }
}

class _UsernameInputField extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool isValid;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;
  final ValidationMixin validationMixin;

  const _UsernameInputField({
    required this.controller,
    required this.index,
    required this.isValid,
    required this.onChanged,
    required this.onRemove,
    required this.validationMixin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormTextField(
      controller: controller,
      hintText: 'Username ${index + 1}',
      onChanged: onChanged,
      errorText: validationMixin.getUsernameErrorText(controller.text),
      isValid: isValid,
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isValid
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '@',
          style: TextStyle(
            color: isValid
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      onClear: () {
        controller.clear();
        onChanged('');
      },
      suffixActions: onRemove != null
          ? [
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
              ),
            ]
          : null,
    );
  }
}
