import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthService with ChangeNotifier {
  final sb.SupabaseClient _supabaseClient = sb.Supabase.instance.client;

  sb.User? _currentUser;
  sb.User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<sb.AuthState>? _authStateSubscription;

  AuthService() {
    // Listen to Supabase auth events
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
    // Set initial user
    _currentUser = _supabaseClient.auth.currentUser;
  }

  bool _isBypassed = false;
  bool get isUserSignedIn => _currentUser != null || _isBypassed;
  String get currentUid => _currentUser?.id ?? (_isBypassed ? 'mock_uid' : '');

  void bypassLogin() {
    _isBypassed = true;
    notifyListeners();
  }

  Future<bool> handleLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _currentUser = response.user;

      // Ensure a profile row exists for this user in public.profiles (safeguard)
      if (_currentUser != null) {
        final uid = _currentUser!.id;
        try {
          final existing = await _supabaseClient
              .from('profiles')
              .select('id')
              .eq('id', uid)
              .maybeSingle();

          if (existing == null) {
            final defaultUsername = email.split('@')[0];
            await _supabaseClient.from('profiles').upsert({
              'id': uid,
              'username': defaultUsername,
              'full_name': defaultUsername,
              'bio': 'আমি ডাক অ্যাপ ব্যবহার করছি।',
              'avatar_url': null,
              'cover_url': null,
              'followers_count': 0,
              'following_count': 0,
            });
            debugPrint("Profile created on-demand for uid: $uid");
          }
        } catch (profileError) {
          debugPrint("Profile ensure error (non-fatal): $profileError");
        }
      }

      _isBypassed = false;
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

    try {
      final defaultUsername = username ?? email.split('@')[0];

      // 1. Sign up with Supabase GoTrue Auth
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': defaultUsername,
          'full_name': fullName,
        },
      );

      final uid = response.user?.id;
      if (uid == null) {
        throw Exception("Signup failed: returned null user.");
      }

      // 2. Initialize/Update profile in profiles table with additional details
      try {
        await _supabaseClient.from('profiles').upsert({
          'id': uid,
          'username': defaultUsername,
          'full_name': fullName,
          'bio': 'আসসালামু আলাইকুম! আমি ডাক অ্যাপ ব্যবহার করছি।',
          'avatar_url': null,
          'cover_url': null,
          'followers_count': 0,
          'following_count': 0,
          'phone': phone,
          'gender': gender,
          'birthdate': birthdate,
          'division': division,
          'city': city,
          'village': village,
          'zip': zip,
        });
      } catch (dbError) {
        debugPrint("Creating DB profile row with extra details failed, falling back: $dbError");
        try {
          await _supabaseClient.from('profiles').upsert({
            'id': uid,
            'username': defaultUsername,
            'full_name': fullName,
            'bio': 'আসসালামু আলাইকুম! আমি ডাক অ্যাপ ব্যবহার করছি।',
            'phone': phone,
          });
        } catch (innerError) {
          debugPrint("Fallback profile creation failed: $innerError");
        }
      }

      // 3. Sign out immediately so they must verify or log in manually
      try {
        await _supabaseClient.auth.signOut();
      } catch (_) {}

      _isBypassed = false;
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
      return ["admin", "test", "dak", "system"].contains(username.trim().toLowerCase());
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
    _isBypassed = false;
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      debugPrint("Supabase signout warning: $e");
    }
    notifyListeners();
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
