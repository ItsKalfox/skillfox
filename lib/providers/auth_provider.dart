import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get userData => _userData;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? val) {
    _error = val;
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    _userData = await _userService.getCurrentUserData();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    final result = await _authService.signIn(email, password);

    _setLoading(false);

    if (result != null) {
      _userData = result;
      notifyListeners();
      return true;
    }

    _setError('Invalid email or password');
    return false;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userData = null;
    notifyListeners();
  }
}
