import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common/animated_dialog.dart';
import 'common/dialog_header.dart';
import 'common/dialog_description.dart';
import 'common/dialog_actions.dart';
import 'common/form_text_field.dart';
import 'common/username_input_list.dart';
import 'common/validation_mixin.dart';

class DirectMessageDialog extends StatefulWidget {
  final String title;
  final String description;
  final Function(List<String> usernames, String message, int numberOfAccounts)
  onConfirm;

  const DirectMessageDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
  });

  @override
  State<DirectMessageDialog> createState() => _DirectMessageDialogState();
}

class _DirectMessageDialogState extends State<DirectMessageDialog>
    with ValidationMixin {
  final List<TextEditingController> _usernameControllers = [
    TextEditingController(),
  ];
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _accountsController = TextEditingController(
    text: '1',
  );

  bool _hasValidUsernames = false;
  bool _isValidMessage = false;
  bool _isValidAccounts = true;

  @override
  void dispose() {
    for (var controller in _usernameControllers) {
      controller.dispose();
    }
    _messageController.dispose();
    _accountsController.dispose();
    super.dispose();
  }

  void _onUsernamesValidationChanged(bool hasValid) {
    setState(() {
      _hasValidUsernames = hasValid;
    });
  }

  void _onMessageChanged(String value) {
    setState(() {
      _isValidMessage = validateMessage(value);
    });
  }

  void _onAccountsChanged(String value) {
    setState(() {
      _isValidAccounts = validateAccounts(value);
    });
  }

  void _addUsernameField() {
    setState(() {
      _usernameControllers.add(TextEditingController());
    });
  }

  void _removeUsernameField(int index) {
    if (_usernameControllers.length > 1) {
      setState(() {
        _usernameControllers[index].dispose();
        _usernameControllers.removeAt(index);
      });
    }
  }

  void _handleConfirm() {
    final usernames = _usernameControllers
        .map((controller) => controller.text.trim())
        .where((username) => username.isNotEmpty)
        .toList();
    final message = _messageController.text.trim();
    final accounts = int.parse(_accountsController.text.trim());

    widget.onConfirm(usernames, message, accounts);
    Navigator.of(context).pop();
  }

  bool get _canSubmit =>
      _hasValidUsernames && _isValidMessage && _isValidAccounts;

  @override
  Widget build(BuildContext context) {
    return AnimatedDialog(
      maxWidth: 600,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogHeader(
            title: widget.title,
            icon: Icons.message_rounded,
            statusText: 'Required',
          ),
          const SizedBox(height: 24),
          DialogDescription(description: widget.description),
          const SizedBox(height: 24),
          UsernameInputList(
            controllers: _usernameControllers,
            onValidationChanged: _onUsernamesValidationChanged,
            onAdd: _addUsernameField,
            onRemove: _removeUsernameField,
          ),
          const SizedBox(height: 24),
          _MessageInput(
            controller: _messageController,
            onChanged: _onMessageChanged,
            isValid: _isValidMessage,
            validationMixin: this,
          ),
          const SizedBox(height: 24),
          _AccountsInput(
            controller: _accountsController,
            onChanged: _onAccountsChanged,
            isValid: _isValidAccounts,
            validationMixin: this,
          ),
          const SizedBox(height: 32),
          DialogActions(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: _handleConfirm,
            confirmText: 'Send Messages',
            confirmIcon: Icons.send_rounded,
            isEnabled: _canSubmit,
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isValid;
  final ValidationMixin validationMixin;

  const _MessageInput({
    required this.controller,
    required this.onChanged,
    required this.isValid,
    required this.validationMixin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormFieldContainer(
      icon: Icon(Icons.edit_rounded, size: 18, color: colorScheme.primary),
      title: 'Message Text',
      isRequired: true,
      helperText: 'Enter the message to be sent',
      additionalInfo: '${controller.text.length} characters',
      isValid: isValid,
      child: FormTextField(
        controller: controller,
        hintText: 'Write your message here...',
        onChanged: onChanged,
        errorText: validationMixin.getMessageErrorText(controller.text),
        isValid: isValid,
        maxLines: 4,
        minLines: 2,
        textInputAction: TextInputAction.newline,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isValid
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: isValid
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            size: 18,
          ),
        ),
        onClear: () {
          controller.clear();
          onChanged('');
        },
      ),
    );
  }
}

class _AccountsInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isValid;
  final ValidationMixin validationMixin;

  const _AccountsInput({
    required this.controller,
    required this.onChanged,
    required this.isValid,
    required this.validationMixin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormFieldContainer(
      icon: Icon(
        Icons.account_circle_rounded,
        size: 18,
        color: colorScheme.primary,
      ),
      title: 'Number of Accounts',
      isRequired: true,
      helperText:
          'Enter the number of accounts to use for sending (maximum: 8)',
      child: FormTextField(
        controller: controller,
        hintText: '1',
        onChanged: onChanged,
        errorText: validationMixin.getAccountsErrorText(controller.text),
        isValid: isValid,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isValid
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.numbers_rounded,
            color: isValid
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            size: 18,
          ),
        ),
        suffixActions: [
          IconButton(
            onPressed: () {
              controller.text = '1';
              onChanged('1');
            },
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
