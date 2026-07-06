import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/foundation.dart';

abstract class AuthRemoteDataSource {
  Future<sb.User> login(String email, String password);
  
  Future<bool> signup({
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
  });

  Future<void> signOut();

  sb.User? get currentUser;
  Stream<sb.AuthState> get onAuthStateChanged;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sb.SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  sb.User? get currentUser => supabaseClient.auth.currentUser;

  @override
  Stream<sb.AuthState> get onAuthStateChanged => supabaseClient.auth.onAuthStateChange;

  @override
  Future<sb.User> login(String email, String password) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    
    final user = response.user;
    if (user == null) {
      throw Exception("Login response returned null user.");
    }
    
    // Ensure profile row exists in public.profiles (safeguard)
    final uid = user.id;
    try {
      final existing = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('id', uid)
          .maybeSingle();

      if (existing == null) {
        final defaultUsername = email.split('@')[0];
        await supabaseClient.from('profiles').upsert({
          'id': uid,
          'username': defaultUsername,
          'full_name': defaultUsername,
          'bio': 'I am using the Pigeon app.',
          'followers_count': 0,
          'following_count': 0,
        });
        debugPrint("Profile created on-demand during remote data source login for uid: $uid");
      }
    } catch (profileError) {
      debugPrint("Profile safeguard error (non-fatal): $profileError");
    }

    return user;
  }

  @override
  Future<bool> signup({
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
    final defaultUsername = username ?? email.split('@')[0];

    // 1. Sign up with Supabase GoTrue Auth
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': defaultUsername,
        'full_name': fullName,
        'phone': phone,
        'gender': gender,
        'birthdate': birthdate,
        'division': division,
        'city': city,
        'village': village,
        'zip': zip,
      },
    );

    final uid = response.user?.id;
    if (uid == null) {
      throw Exception("Signup response returned null user.");
    }

    // 2. Initialize/Update profile in profiles table with additional details
    try {
      await supabaseClient.from('profiles').upsert({
        'id': uid,
        'username': defaultUsername,
        'full_name': fullName,
        'bio': 'Hello! I am using the Pigeon app.',
        'followers_count': 0,
        'following_count': 0,
        'phone': phone,
        'email': email.trim(),
        'gender': gender,
        'birthdate': birthdate,
        'division': division,
        'city': city,
        'village': village,
        'zip': zip,
      });
    } catch (dbError) {
      debugPrint("Creating DB profile row failed, falling back: $dbError");
      try {
        await supabaseClient.from('profiles').upsert({
          'id': uid,
          'username': defaultUsername,
          'full_name': fullName,
          'bio': 'Hello! I am using the Pigeon app.',
          'phone': phone,
          'email': email.trim(),
        });
      } catch (innerError) {
        debugPrint("Fallback profile creation failed: $innerError");
      }
    }

    // 3. Sign out immediately so they must verify or log in manually
    try {
      await supabaseClient.auth.signOut();
    } catch (_) {}

    return true;
  }

  @override
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }
}
