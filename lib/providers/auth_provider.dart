import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';

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

      // 1. Try API login first (real JWT token for server calls)
      try {
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
        // API failed - fall through to local fallback
      } catch (_) {
        // API unreachable (server spinning up) - fall through to local fallback
      }

      // 2. Local fallback (offline/first-load mode)
      final username = emailOrUsername.trim().toLowerCase();
      final pass = password.trim();

      if (AppConstants.credentials.containsKey(username)) {
        final info = AppConstants.credentials[username]!;
        if (info['password'] == pass && info['role'] == role) {
          final mappedUser = User(
            id: info['id'] ?? info['division'] ?? username,
            username: username,
            name: info['name'] ?? username,
            email: info['role'] == 'teacher' ? '$username@college.edu' : '$username@student.edu',
            role: info['role']!,
            className: info['division'] ?? '',
            section: 'A',
            specialization: info['division'] != null ? 'Core' : '',
            college: 'CSE (Data Science) Department',
            token: 'local-token-$username',
          );

          _user = mappedUser;
          _isLoggedIn = true;
          ApiService.setToken('local-token-$username');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userData', jsonEncode(_user!.toJson()));
          await prefs.setString('authToken', _user!.token!);

          _isLoading = false;
          notifyListeners();
          return {'success': true, 'user': _user};
        }
      }

      _error = 'Invalid credentials or role mismatch';
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