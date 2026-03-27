class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    if (!value.contains(RegExp(r'[!@#\$&*~%^()_\-+=]'))) {
      return 'Password must contain a symbol';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (value.length < 9) return 'Enter a valid phone number';
    return null;
  }
}