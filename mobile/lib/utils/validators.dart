class Validators {
  static String? validateEmail(String? value, {String? message}) {
    if (value == null || value.isEmpty) {
      return message ?? 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value, {String? message}) {
    if (value == null || value.isEmpty) {
      return message ?? 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateUsername(String? value, {bool? isAvailable}) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username too short';
    }
    if (isAvailable == false) {
      return 'Username already taken';
    }
    return null;
  }

  static String? validateRequired(String? value,
      {String? fieldName, String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? '${fieldName ?? 'Field'} is required';
    }
    return null;
  }
}
