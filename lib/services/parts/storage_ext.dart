part of '../database_service.dart';

extension StorageExtension on DatabaseService {
  // --- Storage Operations (Avatar/Cover) ---

  Future<String?> _uploadToStorage(String bucket, String path, Uint8List bytes) async {
    try {
      await _supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint("Upload to storage error: $e");
      return null;
    }
  }

  Future<bool> updateProfileImage(Uint8List bytes, bool isAvatar) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    updateState();

    try {
      final res = await sl<UpdateProfileImageUseCase>().call(bytes, isAvatar);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
        return true;
      }
      _isLoading = false;
      updateState();
      return false;
    } catch (e) {
      debugPrint("Update profile image error: $e");
      _isLoading = false;
      updateState();
      return false;
    }
  }

  /// Uploads a photo for a thread post. Uses the 'avatars' bucket with a
  /// 'posts/' subfolder prefix to avoid needing a separate storage bucket.
  Future<String?> uploadPostImage(Uint8List bytes) async {
    if (_currentUid.isEmpty) return null;
    try {
      final path = 'posts/$_currentUid/thread_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await _uploadToStorage('avatars', path, bytes);
    } catch (e) {
      debugPrint("Upload post image error: $e");
      return null;
    }
  }

  /// Uploads a voice post. Uses the 'avatars' bucket with a
  /// 'voice_posts/' subfolder prefix.
  Future<String?> uploadPostAudio(Uint8List bytes, String extension) async {
    if (_currentUid.isEmpty) return null;
    try {
      final path = 'voice_posts/$_currentUid/voice_${DateTime.now().millisecondsSinceEpoch}.$extension';
      return await _uploadToStorage('avatars', path, bytes);
    } catch (e) {
      debugPrint("Upload voice post error: $e");
      return null;
    }
  }

  Future<bool> deleteProfileImage(bool isAvatar) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    updateState();

    try {
      final updateField = isAvatar ? 'avatar_url' : 'cover_url';
      await _supabase.from('profiles').update({updateField: null}).eq('id', _currentUid);
      await fetchMyProfile();
      return true;
    } catch (e) {
      debugPrint("Delete profile image error: $e");
      _isLoading = false;
      updateState();
      return false;
    }
  }

}
