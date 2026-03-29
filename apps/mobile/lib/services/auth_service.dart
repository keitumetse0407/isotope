// ISOTOPE — Auth Service
// Handles user authentication and state
// Admin users (founder/elon) get LIFETIME FREE access

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../models/user.dart';
import '../models/admin_user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final ApiService _api = ApiService();

  User? _currentUser;
  AdminUser? _adminUser;
  bool _isLoggedIn = false;
  bool _isAdmin = false;

  User? get currentUser => _currentUser;
  AdminUser? get adminUser => _adminUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  bool get isFounder => _adminUser?.isFounder ?? false;
  bool get isElon => _adminUser?.isElon ?? false;

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    // Listen to auth state changes
    _auth.authStateChanges().listen((firebase.User? user) {
      if (user != null) {
        _loadUser(user.uid);
      } else {
        _currentUser = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    });

    // Check if already logged in
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUser(firebaseUser.uid);
    }
  }

  Future<void> _loadUser(String userId) async {
    try {
      final user = await _api.getUser(userId);
      if (user != null) {
        _currentUser = user;
        
        // Check if this is an admin account
        _checkAdminAccess(user.email);
        
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _checkAdminAccess(String email) {
    // Check against predefined admin accounts
    for (var adminData in AdminAccounts.defaults) {
      if (adminData['email'] == email) {
        _adminUser = AdminUser.fromJson(adminData);
        _isAdmin = true;
        debugPrint('Admin access granted: ${adminData['name']} (${adminData['role']})');
        return;
      }
    }
    
    // Not an admin - regular user
    _adminUser = null;
    _isAdmin = false;
  }

  // ============================================
  // SIGN UP
  // ============================================

  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create Firebase auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user in backend
      final user = await _api.createUser(email, name);

      if (user == null) {
        return Result.failure('Failed to create user account');
      }

      _currentUser = user;
      _isLoggedIn = true;
      notifyListeners();

      return Result.success(user);
    } on firebase.FirebaseAuthException catch (e) {
      return Result.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return Result.failure('Sign up failed: ${e.toString()}');
    }
  }

  // ============================================
  // SIGN IN
  // ============================================

  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user from backend
      await _loadUser(credential.user!.uid);

      if (_currentUser != null) {
        return Result.success(_currentUser!);
      } else {
        return Result.failure('Failed to load user account');
      }
    } on firebase.FirebaseAuthException catch (e) {
      return Result.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return Result.failure('Sign in failed: ${e.toString()}');
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // ============================================
  // PASSWORD RESET
  // ============================================

  Future<Result<void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return Result.success(null);
    } on firebase.FirebaseAuthException catch (e) {
      return Result.failure(_getAuthErrorMessage(e.code));
    } catch (e) {
      return Result.failure('Password reset failed: ${e.toString()}');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

// ============================================
// RESULT WRAPPER
// ============================================

class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.failure(String error) {
    return Result._(error: error, isSuccess: false);
  }
}
