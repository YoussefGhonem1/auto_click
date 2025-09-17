mixin ValidationMixin {
  bool validateUsername(String username) {
    return username.trim().isNotEmpty && username.trim().length >= 2;
  }

  bool validateMessage(String message) {
    return message.trim().isNotEmpty && message.trim().length >= 2;
  }

  bool validateAccounts(String accounts) {
    if (accounts.isEmpty) return false;
    final parsed = int.tryParse(accounts);
    return parsed != null && parsed > 0 && parsed <= 8;
  }

  String? getUsernameErrorText(String username) {
    if (username.isNotEmpty && !validateUsername(username)) {
      return 'Please enter a valid username (minimum 2 characters)';
    }
    return null;
  }

  String? getMessageErrorText(String message) {
    if (message.isNotEmpty && !validateMessage(message)) {
      return 'Please enter a valid message (minimum 2 characters)';
    }
    return null;
  }

  String? getAccountsErrorText(String accounts) {
    if (accounts.isNotEmpty && !validateAccounts(accounts)) {
      return 'Please enter a valid number (1-8)';
    }
    return null;
  }
}
