part of '../database_service.dart';

extension StorageExtension on DatabaseService {
  // --- Storage Operations ---

  Future<String?> _uploadToStorage(String path, Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      final publicUrl = await uploadTask.ref.getDownloadURL();
      return publicUrl;
    } catch (e) {
      debugPrint("Upload to Firebase storage error: $e");
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

  /// Uploads a photo for a thread post to Firebase Storage.
  Future<String?> uploadPostImage(Uint8List bytes) async {
    if (_currentUid.isEmpty) return null;
    try {
      final path = 'posts/$_currentUid/thread_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await _uploadToStorage(path, bytes, contentType: 'image/jpeg');
    } catch (e) {
      debugPrint("Upload post image error: $e");
      return null;
    }
  }

  /// Uploads a voice post to Firebase Storage.
  Future<String?> uploadPostAudio(Uint8List bytes, String extension) async {
    if (_currentUid.isEmpty) return null;
    try {
      final path = 'voice_posts/$_currentUid/voice_${DateTime.now().millisecondsSinceEpoch}.$extension';
      String contentType = 'audio/mpeg';
      if (extension == 'm4a') {
        contentType = 'audio/x-m4a';
      } else if (extension == 'aac') {
        contentType = 'audio/aac';
      } else if (extension == 'wav') {
        contentType = 'audio/wav';
      }
      return await _uploadToStorage(path, bytes, contentType: contentType);
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
