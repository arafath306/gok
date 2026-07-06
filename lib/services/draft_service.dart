import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draft_post.dart';

class DraftService {
  static const String _draftsKey = 'dak_user_drafts';

  Future<List<DraftPost>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey) ?? [];
    return draftsJson.map((jsonStr) => DraftPost.fromJson(jsonStr)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Newest first
  }

  Future<void> saveDraft(DraftPost draft, List<Uint8List>? newImageBytes) async {
    final prefs = await SharedPreferences.getInstance();
    List<DraftPost> drafts = await getDrafts();

    // Remove existing if updating
    drafts.removeWhere((d) => d.id == draft.id);

    // Save images to local storage
    List<String> finalImagePaths = List.from(draft.imagePaths);
    if (newImageBytes != null && newImageBytes.isNotEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      final draftsDir = Directory('${directory.path}/drafts');
      if (!await draftsDir.exists()) {
        await draftsDir.create(recursive: true);
      }

      for (int i = 0; i < newImageBytes.length; i++) {
        final filePath = '${draftsDir.path}/${draft.id}_$i.png';
        final file = File(filePath);
        await file.writeAsBytes(newImageBytes[i]);
        if (!finalImagePaths.contains(filePath)) {
          finalImagePaths.add(filePath);
        }
      }
    }

    final updatedDraft = DraftPost(
      id: draft.id,
      content: draft.content,
      imagePaths: finalImagePaths,
      videoUrl: draft.videoUrl,
      audience: draft.audience,
      location: draft.location,
      pollOptions: draft.pollOptions,
      pollDurationHours: draft.pollDurationHours,
      updatedAt: draft.updatedAt,
      musicTrack: draft.musicTrack,
    );

    drafts.add(updatedDraft);

    // Save back to prefs
    final updatedJson = drafts.map((d) => d.toJson()).toList();
    await prefs.setStringList(_draftsKey, updatedJson);
  }

  Future<void> deleteDrafts(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    List<DraftPost> drafts = await getDrafts();

    for (var id in ids) {
      final draftIdx = drafts.indexWhere((d) => d.id == id);
      if (draftIdx != -1) {
        final draft = drafts[draftIdx];
        // delete local image files
        for (var path in draft.imagePaths) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        drafts.removeAt(draftIdx);
      }
    }

    final updatedJson = drafts.map((d) => d.toJson()).toList();
    await prefs.setStringList(_draftsKey, updatedJson);
  }

  Future<int> getDraftCount() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getStringList(_draftsKey) ?? [];
    return draftsJson.length;
  }
}
