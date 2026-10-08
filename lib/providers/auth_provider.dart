import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  bool _isCheckingStatus = true;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get isCheckingStatus => _isCheckingStatus;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');

      if (userData != null) {
        _user = User.fromJson(jsonDecode(userData));
        _isLoggedIn = true;
        await ApiService.restoreSession();
      }
    } catch (_) {
      // Handled silently
    } finally {
      _isCheckingStatus = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final apiResult = await ApiService.login(
        emailOrUsername: emailOrUsername,
        password: password,
        role: role,
      );
      if (apiResult['success'] == true) {
        final user = apiResult['user'] as User;
        final token = apiResult['token'] as String?;
        _user = user;
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', jsonEncode(_user!.toJson()));
        if (token != null) {
          await prefs.setString('authToken', token);
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'user': _user};
      }

      _error = apiResult['message']?.toString() ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required String className,
    required String section,
    required String specialization,
    required String college,
  }) async {
    if (_user == null) return;

    _user = User(
      id: _user!.id,
      username: _user!.username,
      name: name.trim(),
      email: email.trim(),
      role: _user!.role,
      className: className.trim(),
      section: section.trim(),
      specialization: specialization.trim(),
      college: college.trim(),
      token: _user!.token,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> updateTeacherProfile({
    required String name,
    required String email,
    required String college,
  }) async {
    if (_user == null) return;

    _user = User(
      id: _user!.id,
      username: _user!.username,
      name: name.trim(),
      email: email.trim(),
      role: _user!.role,
      className: _user!.className,
      section: _user!.section,
      specialization: _user!.specialization,
      college: college.trim(),
      token: _user!.token,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userData');

      _user = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (_) {
      // Handled silently
    }
  }
}
