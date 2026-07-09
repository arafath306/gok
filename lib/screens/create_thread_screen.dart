import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../models/thread_post.dart';
import '../models/draft_post.dart';
import '../services/draft_service.dart';
import '../utils/routes.dart';
import 'drafts_screen.dart';
import 'photo_editor_screen.dart';
import '../models/music_track.dart';
import '../widgets/music_search_sheet.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/general_settings_provider.dart';

class CreateThreadScreen extends StatefulWidget {
  final ThreadPost? quotePost;
  /// When non-null the screen is in "edit" mode: pre-fills text and saves via editPostContent.
  final ThreadPost? editPost;
  final DraftPost? draftPost;
  final String? communityId;
  const CreateThreadScreen({super.key, this.quotePost, this.editPost, this.draftPost, this.communityId});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  String _privacy = "Public";
  bool _privacyOpen = false;
  int _charCount = 0;
  bool _showImageInput = false;
  final bool _showVideoInput = false;
  final bool _isAnonymous = false;
  bool _isSubscriberOnly = false;

  final List<Uint8List> _selectedImagesBytesList = [];
  final List<Uint8List> _originalImagesBytesList = [];
  // ignore: unused_field
  String? _selectedImageName;
  bool _isUploadingImage = false;

  // Additional Interactive UI States
  bool _showPollInput = false;
  final List<TextEditingController> _pollControllers = [
    TextEditingController(),
    TextEditingController()
  ];
  Duration _pollDuration = const Duration(hours: 24);
  final List<Map<String, dynamic>> _durations = [
    {"label": "1 Hour", "duration": const Duration(hours: 1)},
    {"label": "6 Hours", "duration": const Duration(hours: 6)},
    {"label": "1 Day", "duration": const Duration(hours: 24)},
    {"label": "3 Days", "duration": const Duration(days: 3)},
    {"label": "7 Days", "duration": const Duration(days: 7)},
  ];
  
  String? _selectedLocation;
  
  bool _showVoiceRecorder = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _recordedAudioPath;
  bool _isPlayingAudio = false;

  bool _isLoadingExistingMedia = false;
  
  int _draftCount = 0;
  final DraftService _draftService = DraftService();
  MusicTrack? _selectedMusic;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
    _loadDraftCount();
    
    if (widget.draftPost != null) {
      _contentController.text = widget.draftPost!.content;
      _privacy = widget.draftPost!.audience;
      _selectedLocation = widget.draftPost!.location;
      if (widget.draftPost!.videoUrl != null) {
        _videoUrlController.text = widget.draftPost!.videoUrl!;
      }
      if (widget.draftPost!.imagePaths.isNotEmpty) {
        _loadDraftImages(widget.draftPost!.imagePaths);
      }
      if (widget.draftPost!.musicTrack != null) {
        _selectedMusic = widget.draftPost!.musicTrack;
      }
    } else if (widget.editPost != null) {
      _contentController.text = widget.editPost!.content;
      _loadExistingMedia();
    }
  }

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

  Future<void> _loadExistingMedia() async {
    final urls = widget.editPost!.imageUrls;
    if (urls == null || urls.isEmpty) return;

    setState(() {
      _isLoadingExistingMedia = true;
    });

    try {
      final List<Uint8List> downloadedBytes = [];
      final HttpClient client = HttpClient();

      for (final url in urls) {
        try {
          final Uri uri = Uri.parse(url);
          final HttpClientRequest request = await client.getUrl(uri);
          final HttpClientResponse response = await request.close();
          if (response.statusCode == 200) {
            final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
            downloadedBytes.add(bytes);
          }
        } catch (e) {
          debugPrint("Failed to download image $url: $e");
        }
      }

      if (mounted && downloadedBytes.isNotEmpty) {
        setState(() {
          _selectedImagesBytesList.addAll(downloadedBytes);
          _originalImagesBytesList.addAll(downloadedBytes);
        });
      }
    } catch (e) {
      debugPrint("Error loading existing media: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingMedia = false;
        });
      }
    }
  }

  void _onContentChanged() {
    setState(() {
      _charCount = _contentController.text.length;
    });
  }

  // --- Voice Recorder Methods ---
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_post_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordedAudioPath = path;
      });
    } catch (e) {
      debugPrint("Error stopping record: $e");
    }
  }

  void _deleteRecording() {
    setState(() {
      _recordedAudioPath = null;
      _recordingSeconds = 0;
      _showVoiceRecorder = false;
    });
  }

  Future<void> _toggleAudioPreview() async {
    if (_recordedAudioPath == null) return;
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedAudioPath!));
      setState(() => _isPlayingAudio = true);
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    for (var controller in _pollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );
      if (images.isEmpty) return;

      final List<Uint8List> bytesList = [];
      for (var img in images) {
        final bytes = await img.readAsBytes();
        bytesList.add(bytes);
      }

      setState(() {
        _selectedImagesBytesList.addAll(bytesList);
        _originalImagesBytesList.addAll(bytesList);
        _showImageInput = false; // Turn off generic URL input
      });
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> _pickCameraImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImagesBytesList.add(bytes);
        _originalImagesBytesList.add(bytes);
        _showImageInput = false;
      });
    } catch (e) {
      debugPrint("Error picking camera image: $e");
    }
  }

  Future<void> _openPhotoEditorAtIndex(int index) async {
    if (index < 0 || index >= _originalImagesBytesList.length) return;
    final originalBytes = _originalImagesBytesList[index];
    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoEditorScreen(imageBytes: originalBytes),
      ),
    );
    if (croppedBytes != null) {
      setState(() {
        _selectedImagesBytesList[index] = croppedBytes;
      });
    }
  }

  void _submit() async {
    final text = _contentController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final videoUrl = _videoUrlController.text.trim();

    if (text.isEmpty) return;

    setState(() => _isUploadingImage = true);
    final db = Provider.of<DatabaseService>(context, listen: false);

    // â”€â”€ Edit mode: just update the existing post content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (widget.editPost != null) {
      List<String>? uploadedUrls;
      if (_selectedImagesBytesList.isNotEmpty) {
        uploadedUrls = [];
        try {
          for (final bytes in _selectedImagesBytesList) {
            final imagePublicUrl = await db.uploadPostImage(bytes);
            if (imagePublicUrl != null) {
              uploadedUrls.add(imagePublicUrl);
            }
          }
          if (uploadedUrls.isEmpty) {
            uploadedUrls = null;
          }
        } catch (uploadError) {
          debugPrint("Edit post images upload failed: $uploadError");
        }
      }

      final success = await db.editPostContent(
        widget.editPost!.id,
        text,
        imageUrls: uploadedUrls ?? [],
      );

      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Post updated successfully', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ]),
            backgroundColor: const Color(0xFF1E824C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // return true = edited
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post', style: GoogleFonts.inter())),
        );
      }
      return;
    }

    // â”€â”€ Create / Quote mode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    String finalContent = text;
    if (_selectedLocation != null) {
      finalContent += "\n\nðŸ“ $_selectedLocation";
    }
    if (_selectedMusic != null) {
      finalContent += " ðŸŽµDakMusicðŸŽµ${_selectedMusic!.toJson()}";
    }

    List<String>? pollOptions;
    Duration? pollDuration;
    if (_showPollInput) {
      final filledOptions = _pollControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (filledOptions.length >= 2) {
        pollOptions = filledOptions;
        pollDuration = _pollDuration;
      } else {
        // Block submission and show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Poll must have at least 2 options', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ]),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() => _isUploadingImage = false);
        }
        return;
      }
    }

    List<String>? uploadedUrls;
    if (_selectedImagesBytesList.isNotEmpty) {
      uploadedUrls = [];
      try {
        for (final bytes in _selectedImagesBytesList) {
          final imagePublicUrl = await db.uploadPostImage(bytes);
          if (imagePublicUrl != null) {
            uploadedUrls.add(imagePublicUrl);
          }
        }
        if (uploadedUrls.isEmpty) {
          uploadedUrls = null;
        }
      } catch (uploadError) {
        debugPrint("Post images upload failed: $uploadError");
      }
    } else if (imageUrl.isNotEmpty) {
      uploadedUrls = [imageUrl];
    }

    String? audioPublicUrl;
    if (_recordedAudioPath != null) {
      try {
        final bytes = await File(_recordedAudioPath!).readAsBytes();
        audioPublicUrl = await db.uploadPostAudio(bytes, 'm4a');
      } catch (e) {
        debugPrint("Voice post upload failed: $e");
      }
    }

    final bool success;
    if (widget.quotePost != null) {
      success = await db.repostThread(
        widget.quotePost!.id,
        quoteText: finalContent,
      );
    } else {
      success = await db.createThread(
        finalContent,
        imageUrls: uploadedUrls,
        videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
        audioUrl: audioPublicUrl,
        audience: _privacy,
        pollOptions: pollOptions,
        pollDuration: pollDuration,
        communityId: widget.communityId,
        isSubscriberOnly: _isSubscriberOnly,
      );
    }

    if (mounted) {
      setState(() => _isUploadingImage = false);
      if (success) {
        if (widget.draftPost != null) {
          await _draftService.deleteDrafts([widget.draftPost!.id]);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to publish post", style: GoogleFonts.inter()),
            ),
          );
        }
      }
    }
  }






  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1E824C)),
            const SizedBox(width: 8),
            Text(
              "Coming Soon!",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ],
        ),
        content: Text(
          "$featureName feature is under development. Stay tuned for updates!",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Dismiss",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          ),
        ],
      ),
    );
  }



  void _toggleRecording() {
    if (_isRecording) {
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
    } else {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final prof = dbService.myProfile;
    final isEnabled = (_contentController.text.trim().isNotEmpty || _recordedAudioPath != null) && _charCount <= 500 && !_isUploadingImage;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    // Body content tree
    Widget bodyContent = Column(
      children: [
        // Custom Header Bar (Clean & Identical across views)
        Container(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
          color: context.cardBg,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: context.textPrimary),
                onPressed: _handleClose,
              ),
              if (_draftCount > 0 && widget.editPost == null && widget.quotePost == null)
                TextButton(
                  onPressed: () {
                    Navigator.push(context, NoTransitionPageRoute(child: const DraftsScreen())).then((_) => _loadDraftCount());
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: const Color(0xFF1E824C),
                  ),
                  child: Text("Drafts ($_draftCount)", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              if ((_contentController.text.trim().isNotEmpty || _selectedImagesBytesList.isNotEmpty || _selectedMusic != null) && widget.editPost == null && widget.quotePost == null)
                TextButton(
                  onPressed: () async {
                    await _saveCurrentDraft();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: context.textPrimary,
                  ),
                  child: Text("Draft", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ElevatedButton(
                onPressed: isEnabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E824C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                  disabledForegroundColor: Colors.grey.withValues(alpha: 0.5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isUploadingImage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.editPost != null ? "Save" : "Release",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
              )
            ],
          ),
        ),

        // Scrollable composer fields
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Profile photo and thread connection line (Threads style)
                Column(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                      backgroundImage: NetworkImage(
                        _isAnonymous 
                          ? "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150" // Cool anonymous avatar placeholder
                          : (prof?.avatarUrl ?? ""),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 2,
                      height: 160,
                      decoration: BoxDecoration(
                        color: context.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Right Side: Display name, privacy picker, location picker & textarea
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isAnonymous ? "Anonymous User" : (prof?.fullName ?? "User"),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimary,
                            ),
                          ),
                          if (_isAnonymous) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.security, color: Colors.indigo, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Meta Row: Privacy chip + inline dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: chip + location
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _privacyOpen = !_privacyOpen),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _privacy == "Public"
                                            ? Icons.public
                                            : _privacy == "Friends"
                                                ? Icons.people_alt
                                                : Icons.lock_outline,
                                        size: 11,
                                        color: context.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _privacy,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      AnimatedRotation(
                                        turns: _privacyOpen ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 150),
                                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: context.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedLocation != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF1A2333) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, size: 11, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedLocation!,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedLocation = null),
                                        child: const Icon(Icons.close, size: 11, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          // Inline animated dropdown
                          AnimatedSize(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            child: _privacyOpen
                                ? Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: context.cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: context.border, width: 0.8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        {"label": "Public", "icon": Icons.public},
                                        {"label": "Friends", "icon": Icons.people_alt},
                                        {"label": "Only Me", "icon": Icons.lock_outline},
                                      ].map((opt) {
                                        final label = opt["label"] as String;
                                        final icon = opt["icon"] as IconData;
                                        final isSel = _privacy == label;
                                        return InkWell(
                                          onTap: () => setState(() {
                                            _privacy = label;
                                            _privacyOpen = false;
                                          }),
                                          borderRadius: BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                            child: Row(
                                              children: [
                                                Icon(icon, size: 14, color: isSel ? Theme.of(context).primaryColor : context.textSecondary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  label,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.5,
                                                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                                    color: isSel ? Theme.of(context).primaryColor : context.textPrimary,
                                                  ),
                                                ),
                                                if (isSel) ...[
                                                  const Spacer(),
                                                  Icon(Icons.check_rounded, size: 13, color: Theme.of(context).primaryColor),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Main TextField input
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 4,
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          color: context.textPrimary,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText: "Send your thoughts...",
                          hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      // If it's a quote post, show the quoted post
                      if (widget.quotePost != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: context.border, width: 0.8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: widget.quotePost!.author.avatarUrl != null && widget.quotePost!.author.avatarUrl!.isNotEmpty
                                        ? NetworkImage(widget.quotePost!.author.avatarUrl!)
                                        : null,
                                    child: widget.quotePost!.author.avatarUrl == null || widget.quotePost!.author.avatarUrl!.isEmpty
                                        ? const Icon(Icons.person, size: 12)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.quotePost!.author.fullName,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "@${widget.quotePost!.author.username}",
                                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.quotePost!.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                              ),
                              if (widget.quotePost!.imageUrls != null && widget.quotePost!.imageUrls!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.network(
                                    widget.quotePost!.imageUrls!.first,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Multiple Images Selection preview horizontal scroll list
                      if (_isLoadingExistingMedia) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.border, width: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C4DFF)),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Loading attached media...",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_selectedImagesBytesList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            SizedBox(
                              height: 160,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _selectedImagesBytesList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _selectedImagesBytesList.length) {
                                    // Add more card
                                    return GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                                        decoration: BoxDecoration(
                                          color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: context.border, width: 0.8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, color: context.primaryAccent, size: 28),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Add More",
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: context.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final bytes = _selectedImagesBytesList[index];
                                  return Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(
                                            bytes,
                                            width: 140,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImagesBytesList.removeAt(index);
                                                _originalImagesBytesList.removeAt(index);
                                                if (_selectedImagesBytesList.isEmpty) {
                                                  _selectedMusic = null;
                                                }
                                              });
                                            },
                                            child: const CircleAvatar(
                                              radius: 11,
                                              backgroundColor: Colors.black54,
                                              child: Icon(Icons.close, color: Colors.white, size: 12),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          child: GestureDetector(
                                            onTap: () => _openPhotoEditorAtIndex(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white24, width: 0.8),
                                              ),
                                              child: const Icon(
                                                Icons.edit_rounded,
                                                color: Colors.white,
                                                size: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_selectedMusic != null)
                              Positioned(
                                left: 8,
                                right: 20,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white30, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.music_note, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "${_selectedMusic!.trackName} - ${_selectedMusic!.artistName}",
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedMusic = null;
                                          });
                                        },
                                        child: const Icon(Icons.close, color: Colors.white70, size: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      
                      // Voice Recorder UI
                      if (_showVoiceRecorder) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _recordedAudioPath != null
                                    ? _toggleAudioPreview
                                    : (_isRecording ? _stopRecording : _startRecording),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFF1E824C),
                                  child: Icon(
                                    _recordedAudioPath != null
                                        ? (_isPlayingAudio ? Icons.pause : Icons.play_arrow)
                                        : (_isRecording ? Icons.stop : Icons.mic),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _recordedAudioPath != null
                                      ? "Voice message recorded"
                                      : (_isRecording
                                          ? "Recording... ${_recordingSeconds}s"
                                          : "Tap microphone to record"),
                                  style: GoogleFonts.inter(
                                    color: context.textPrimary,
                                    fontWeight: _isRecording || _recordedAudioPath != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_recordedAudioPath != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: _deleteRecording,
                                ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Custom Image URL Input
                      if (_showImageInput) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: "Image URL",
                            labelStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                            prefixIcon: Icon(Icons.image_outlined, size: 18, color: context.textSecondary),
                            isDense: true,
                            filled: true,
                            fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: context.border),
                            ),
                          ),
                          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                        ),
                      ],

                      // Custom Video URL Input
                      if (_showVideoInput) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _videoUrlController,
                          decoration: InputDecoration(
                            labelText: "Video URL",
                            labelStyle: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                            prefixIcon: Icon(Icons.video_collection_outlined, size: 18, color: context.textSecondary),
                            isDense: true,
                            filled: true,
                            fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: context.border),
                            ),
                          ),
                          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                        ),
                      ],

                      // Poll Creator Interface
                      if (_showPollInput) _buildPollCreator(),

                      // Voice Recording Interface
                      if (_showVoiceRecorder) _buildVoiceRecorder(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Unified Horizontal Bottom Toolbar
        SafeArea(
          child: _buildUnifiedToolbar(),
        ),
      ],
    );

    // Responsive wrap centered container on wide screens
    if (isWide) {
      bodyContent = Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: context.border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              backgroundColor: context.cardBg,
              body: bodyContent,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isWide ? context.scaffoldBg : context.cardBg,
      body: bodyContent,
    );
  }

  Widget _buildUnifiedToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.border, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Attachment Tool Icons (Horizontal List)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildToolbarIcon(
                    icon: Icons.image_outlined,
                    tooltip: "Add Image",
                    color: Theme.of(context).primaryColor,
                    isActive: _selectedImagesBytesList.isNotEmpty || _imageUrlController.text.isNotEmpty || _showImageInput,
                    onTap: _pickImages,
                  ),
                  _buildToolbarIcon(
                    icon: Icons.camera_alt_outlined,
                    tooltip: "Camera Capture",
                    color: Colors.deepOrange,
                    isActive: false,
                    onTap: _pickCameraImage,
                  ),
                  _buildToolbarIcon(
                    icon: Icons.music_note_rounded,
                    tooltip: "Add Music",
                    color: Colors.redAccent,
                    isActive: _selectedMusic != null,
                    onTap: () async {
                      if (_selectedImagesBytesList.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Please add a photo first to attach music.",
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }
                      
                      final selected = await showModalBottomSheet<MusicTrack>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const MusicSearchSheet(),
                      );
                      if (selected != null) {
                        setState(() {
                          _selectedMusic = selected;
                        });
                      }
                    },
                  ),
                  _buildToolbarIcon(
                    icon: Icons.play_circle_outline,
                    tooltip: "Video URL",
                    color: Colors.purple,
                    isActive: false,
                    onTap: () => _showComingSoonDialog("Video upload/embed"),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.bar_chart_outlined,
                    tooltip: "Create Poll",
                    color: Colors.orange,
                    isActive: _showPollInput,
                    onTap: () => setState(() => _showPollInput = !_showPollInput),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.mic_outlined,
                    tooltip: "Voice Message",
                    color: Colors.teal,
                    isActive: _showVoiceRecorder,
                    onTap: () {
                      final settings = context.read<GeneralSettingsProvider>();
                      if (settings.isVoicePostEnabled) {
                        setState(() => _showVoiceRecorder = !_showVoiceRecorder);
                      } else {
                        _showComingSoonDialog("Voice messaging (Pending Admin Approval)");
                      }
                    },
                  ),
                  _buildToolbarIcon(
                    icon: Icons.location_on_outlined,
                    tooltip: "Add Location",
                    color: Colors.blue,
                    isActive: false,
                    onTap: () => _showComingSoonDialog("Location pinning"),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.security_outlined,
                    tooltip: "Anonymous Post",
                    color: Colors.indigo,
                    isActive: false,
                    onTap: () => _showComingSoonDialog("Anonymous posting"),
                  ),
                  if (Provider.of<DatabaseService>(context).myProfile?.canMonetize == true)
                    _buildToolbarIcon(
                      icon: Icons.monetization_on_outlined,
                      tooltip: "Subscribers Only",
                      color: Colors.amber,
                      isActive: _isSubscriberOnly,
                      onTap: () => setState(() => _isSubscriberOnly = !_isSubscriberOnly),
                    ),
                  _buildToolbarIcon(
                    icon: Icons.auto_awesome_outlined,
                    tooltip: "AI Writer",
                    color: Colors.pink,
                    isActive: false,
                    onTap: () => _showComingSoonDialog("AI writer assistant"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Character limit progress bar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$_charCount/500",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _charCount > 500 ? Colors.red : context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: (_charCount / 500).clamp(0.0, 1.0),
                  backgroundColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                  color: _charCount > 500 
                      ? Colors.red 
                      : _charCount > 400 
                          ? Colors.orange 
                          : Theme.of(context).primaryColor,
                  strokeWidth: 2.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? color : context.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPollCreator() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF201608) : const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: context.isDarkMode ? 0.05 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Create Interactive Poll",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPollInput = false;
                    for (var controller in _pollControllers) {
                      controller.clear();
                    }
                  });
                },
                child: Icon(Icons.close_rounded, size: 20, color: context.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_pollControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pollControllers[index],
                      maxLength: 25,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: InputDecoration(
                        hintText: "Option ${index + 1}",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
                        filled: true,
                        fillColor: context.isDarkMode ? const Color(0xFF1E2030) : Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                        ),
                        counterText: "",
                      ),
                      style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                    ),
                  ),
                  if (_pollControllers.length > 2) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final controller = _pollControllers.removeAt(index);
                          controller.dispose();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      ),
                    ),
                  ]
                ],
              ),
            );
          }),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 12,
            children: [
              if (_pollControllers.length < 4)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _pollControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.orange),
                  label: Text(
                    "Add Option",
                    style: GoogleFonts.inter(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Duration: ",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1E2030) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Duration>(
                        value: _pollDuration,
                        dropdownColor: context.cardBg,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.orange),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (Duration? val) {
                          if (val != null) {
                            setState(() {
                              _pollDuration = val;
                            });
                          }
                        },
                        items: _durations.map((d) {
                          return DropdownMenuItem<Duration>(
                            value: d["duration"] as Duration,
                            child: Text(d["label"] as String),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecorder() {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF062D1C) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            color: Colors.teal,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isRecording ? "Recording... ($minutes:$seconds)" : "Voice recorder ready",
            style: GoogleFonts.inter(
              color: Colors.teal,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isRecording ? "Stop" : "Start",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _recordingTimer?.cancel();
              setState(() {
                _showVoiceRecorder = false;
                _isRecording = false;
                _recordingSeconds = 0;
              });
            },
            child: Icon(Icons.close, size: 18, color: context.textSecondary),
          )
        ],
      ),
    );
  }
}
