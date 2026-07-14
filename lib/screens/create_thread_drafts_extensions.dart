// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

part of 'create_thread_screen.dart';

extension CreateThreadDraftsExtensions on _CreateThreadScreenState {
  Future<void> _loadDraftCount() async {
    final count = await _draftService.getDraftCount();
    if (mounted) setState(() => _draftCount = count);
  }

  Future<void> _loadDraftImages(List<String> paths) async {
    final List<Uint8List> loadedBytes = [];
    for (var path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          loadedBytes.add(await file.readAsBytes());
        }
      } catch (e) {
        debugPrint("Error loading draft image: $e");
      }
    }
    if (mounted) {
      setState(() {
        _selectedImagesBytesList.addAll(loadedBytes);
        _originalImagesBytesList.addAll(loadedBytes);
      });
    }
  }

  Future<void> _saveCurrentDraft() async {
    final id = widget.draftPost?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final draft = DraftPost(
      id: id,
      content: _contentController.text.trim(),
      audience: _privacy,
      location: _selectedLocation,
      videoUrl: _videoUrlController.text.trim().isNotEmpty ? _videoUrlController.text.trim() : null,
      updatedAt: DateTime.now(),
      musicTrack: _selectedMusic,
    );
    await _draftService.saveDraft(draft, _selectedImagesBytesList);
  }

  Future<void> _handleClose() async {
    final hasContent = _contentController.text.trim().isNotEmpty || _selectedImagesBytesList.isNotEmpty || _videoUrlController.text.isNotEmpty || _selectedMusic != null;
    if (hasContent && widget.editPost == null && widget.quotePost == null) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.cardBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Unsaved Changes", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
          content: Text("Do you want to save this as a draft before closing?", style: GoogleFonts.inter(color: context.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, "delete"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text("Delete Draft", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, "save"),
              child: Text("Save Draft", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C))),
            ),
          ],
        ),
      );

      if (action == "save") {
        await _saveCurrentDraft();
      } else if (action != "delete") {
        return; // user tapped outside
      }
    }
    if (mounted) Navigator.pop(context);
  }

}
