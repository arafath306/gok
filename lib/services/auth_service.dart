import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/injection.dart';
import '../core/security/e2ee_service.dart';
import '../features/auth/domain/usecases/login_use_case.dart';
import '../features/auth/domain/usecases/signup_use_case.dart';
import '../features/auth/domain/usecases/sign_out_use_case.dart';

class AuthService with ChangeNotifier {
  final sb.SupabaseClient _supabaseClient = sb.Supabase.instance.client;

  sb.User? _currentUser;
  sb.User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<sb.AuthState>? _authStateSubscription;

  final LoginUseCase _loginUseCase = sl<LoginUseCase>();
  final SignupUseCase _signupUseCase = sl<SignupUseCase>();
  final SignOutUseCase _signOutUseCase = sl<SignOutUseCase>();

  AuthService() {
    // Set initial user
    _currentUser = _supabaseClient.auth.currentUser;
    if (_currentUser != null) {
      sl<E2EEService>().initializeKeys();
    }

    // Listen to Supabase auth events
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      final wasSignedOut = _currentUser == null;
      _currentUser = data.session?.user;
      
      if (_currentUser != null && wasSignedOut) {
        sl<E2EEService>().initializeKeys();
      }
      
      notifyListeners();
    });
  }

  bool get isUserSignedIn => _currentUser != null;
  String get currentUid => _currentUser?.id ?? '';

  Future<bool> handleLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _loginUseCase(email, password);
    
    return result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (userEntity) {
        _currentUser = _supabaseClient.auth.currentUser;
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> handleSignup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String birthdate,
    String? username,
    String? division,
    String? city,
    String? village,
    String? zip,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _signupUseCase(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      gender: gender,
      birthdate: birthdate,
      username: username,
      division: division,
      city: city,
      village: village,
      zip: zip,
    );

    return result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> isUsernameTaken(String username) async {
    if (username.trim().isEmpty) return false;
    try {
      final res = await _supabaseClient
          .from('profiles')
          .select('username')
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();
      return res != null;
    } catch (e) {
      debugPrint("isUsernameTaken error: $e");
      // Fallback/Mock behavior if database fails
      await Future.delayed(const Duration(milliseconds: 300));
      return ["admin", "test", "pigeon", "system"].contains(username.trim().toLowerCase());
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyResetOTP(String email, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _supabaseClient.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: sb.OtpType.recovery,
      );
      _currentUser = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseClient.auth.updateUser(
        sb.UserAttributes(password: newPassword.trim()),
      );
      await _supabaseClient.auth.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignout() async {
    final result = await _signOutUseCase();
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        sl<E2EEService>().clearKeys();
        _currentUser = null;
        notifyListeners();
      },
    );
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
