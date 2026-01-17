import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;
  bool _isOwner = false;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAdmin => _isAdmin;
  bool get isOwner => _isOwner;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Initialize Auth State (Check current user on startup)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = _authService.getCurrentUser();
      if (_user != null) {
        await _fetchUserRolesAndData();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserRolesAndData() async {
    try {
      _isAdmin = await _authService.isAdmin();
      _isOwner = await _authService.isOwner();
      _userData = await _authService.getUserData();
    } catch (e) {
      debugPrint('Error fetching user roles: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      _user = _authService.getCurrentUser();
      await _fetchUserRolesAndData();
    } catch (e) {
      if (e is FirebaseAuthException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isOwner,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        isOwner: isOwner,
      );
      _user = _authService.getCurrentUser();
      await _fetchUserRolesAndData();
    } catch (e) {
      if (e is FirebaseAuthException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
      _userData = null;
      _isAdmin = false;
      _isOwner = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
