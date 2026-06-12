import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthService with ChangeNotifier {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final sb.SupabaseClient _supabaseClient = sb.Supabase.instance.client;

  fb.User? _currentUser;
  fb.User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((fb.User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  bool _isBypassed = false;
  bool get isUserSignedIn => _currentUser != null || _isBypassed;
  String get currentUid => _currentUser?.uid ?? (_isBypassed ? 'mock_uid' : '');

  void bypassLogin() {
    _isBypassed = true;
    notifyListeners();
  }

  Future<bool> handleLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Login with Firebase Auth
      final fbCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (fbCredential.user == null) {
        throw Exception("Firebase login returned null user.");
      }

      // 2. Synchronize Supabase session
      String? supabaseUid;
      try {
        final sbRes = await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: password,
        );
        supabaseUid = sbRes.user?.id;
        debugPrint("Supabase signin OK, uid: $supabaseUid");
      } catch (supabaseError) {
        // Supabase account may not exist yet — try creating it silently
        debugPrint("Supabase signin failed: $supabaseError — trying signup");
        try {
          final sbSignup = await _supabaseClient.auth.signUp(
            email: email,
            password: password,
          );
          supabaseUid = sbSignup.user?.id;
          debugPrint("Supabase signup OK, uid: $supabaseUid");
        } catch (signUpError) {
          debugPrint("Supabase background signup also failed: $signUpError");
        }
      }

      // 3. If we have a Supabase session, ensure profile row exists
      if (supabaseUid != null && supabaseUid.isNotEmpty) {
        try {
          final existing = await _supabaseClient
              .from('profiles')
              .select('id')
              .eq('id', supabaseUid)
              .maybeSingle();

          if (existing == null) {
            // Profile row missing — create it now with Supabase UID
            final defaultUsername = email.split('@')[0];
            final displayName =
                fbCredential.user?.displayName ?? defaultUsername;
            await _supabaseClient.from('profiles').upsert({
              'id': supabaseUid,
              'username': defaultUsername,
              'full_name': displayName,
              'bio': 'আমি ডাক অ্যাপ ব্যবহার করছি।',
              'avatar_url': null,
              'cover_url': null,
              'followers_count': 0,
              'following_count': 0,
            });
            debugPrint("Profile created for uid: $supabaseUid");
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create account in Firebase
      final fbCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUid = fbCredential.user?.uid;
      if (firebaseUid == null) {
        throw Exception("Firebase sign up returned null user.");
      }

      // Send Firebase Email Verification
      try {
        await fbCredential.user?.sendEmailVerification();
      } catch (verificationError) {
        debugPrint("Sending email verification failed: $verificationError");
      }

      // 2. Create parallel account in Supabase GoTrue Auth
      String supabaseUid = firebaseUid;
      try {
        final sbAuthResponse = await _supabaseClient.auth.signUp(
          email: email,
          password: password,
        );
        supabaseUid = sbAuthResponse.user?.id ?? firebaseUid;
      } catch (supabaseError) {
        debugPrint("Supabase signup failed: $supabaseError");
      }

      // 3. Initialize custom record in Supabase profiles database table
      try {
        final defaultUsername = email.split('@')[0];
        await _supabaseClient.from('profiles').upsert({
          'id': supabaseUid,
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
        });
      } catch (dbError) {
        debugPrint("Creating DB profile row with extra details failed, falling back: $dbError");
        try {
          final defaultUsername = email.split('@')[0];
          await _supabaseClient.from('profiles').upsert({
            'id': supabaseUid,
            'username': defaultUsername,
            'full_name': fullName,
            'bio': 'আসসালামু আলাইকুম! আমি ডাক অ্যাপ ব্যবহার করছি।',
            'avatar_url': null,
            'cover_url': null,
            'followers_count': 0,
            'following_count': 0,
            'phone': phone,
          });
        } catch (innerError) {
          debugPrint("Fallback DB profile row creation failed: $innerError");
        }
      }

      // 4. Sign out immediately so they must verify and log in manually
      await _firebaseAuth.signOut();
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

  Future<void> handleSignout() async {
    _isBypassed = false;
    await _firebaseAuth.signOut();
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
}
