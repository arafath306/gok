import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  String _privacy = "Friends";
  int _charCount = 0;
  bool _showImageInput = false;
  bool _showVideoInput = false;
  bool _isAnonymous = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploadingImage = false;

  // Additional Interactive UI States
  bool _showPollInput = false;
  final List<TextEditingController> _pollControllers = [
    TextEditingController(),
    TextEditingController()
  ];
  
  String? _selectedLocation;
  
  bool _showVoiceRecorder = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  bool _isGeneratingAI = false;
  String _selectedStyle = "Professional";

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    setState(() {
      _charCount = _contentController.text.length;
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _recordingTimer?.cancel();
    for (var controller in _pollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _showImageInput = false; // Turn off generic URL input
      });
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _submit() async {
    final text = _contentController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final videoUrl = _videoUrlController.text.trim();

    if (text.isEmpty) return;

    setState(() => _isUploadingImage = true);
    final db = Provider.of<DatabaseService>(context, listen: false);

    // Format post content with location & polls if selected
    String finalContent = text;
    if (_selectedLocation != null) {
      finalContent += "\n\n📍 ${_selectedLocation}";
    }
    if (_showPollInput) {
      final filledOptions = _pollControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (filledOptions.isNotEmpty) {
        finalContent += "\n\n📊 ভোট দিন:\n" + filledOptions.map((opt) => "◽ $opt").join("\n");
      }
    }

    List<String>? uploadedUrls;
    if (_selectedImageBytes != null) {
      try {
        final supabase = Supabase.instance.client;
        final path = '${supabase.auth.currentUser?.id ?? 'anon'}/thread_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await supabase.storage.from('avatars').uploadBinary(
          path,
          _selectedImageBytes!,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
        uploadedUrls = [publicUrl];
      } catch (uploadError) {
        debugPrint("Supabase storage upload failed: $uploadError");
      }
    } else if (imageUrl.isNotEmpty) {
      uploadedUrls = [imageUrl];
    }

    final success = await db.createThread(
      finalContent,
      imageUrls: uploadedUrls,
      videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
    );

    if (mounted) {
      setState(() => _isUploadingImage = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "ডাক পোস্ট করতে ব্যর্থ হয়েছে",
              style: GoogleFonts.hindSiliguri(),
            ),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: context.cardBg,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              "ছবি যুক্ত করুন (Add Image)",
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1E824C)),
              title: Text("গ্যালারি থেকে আপলোড করুন", style: GoogleFonts.hindSiliguri(fontSize: 14.5)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: Color(0xFF1E824C)),
              title: Text("ছবির লিঙ্ক পেস্ট করুন (Paste URL)", style: GoogleFonts.hindSiliguri(fontSize: 14.5)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _showImageInput = !_showImageInput;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              "কে ডাক দেখতে পাবে?",
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            Divider(color: context.border),
            ListTile(
              leading: const Icon(Icons.public, color: Color(0xFF1E824C)),
              title: Text("সবাই (Public)", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
              subtitle: Text("যে কেউ এই ডাকটি দেখতে পারবে", style: GoogleFonts.hindSiliguri(fontSize: 12, color: context.textSecondary)),
              trailing: _privacy == "Public" ? const Icon(Icons.check, color: Color(0xFF1E824C)) : null,
              onTap: () {
                setState(() => _privacy = "Public");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Color(0xFF1E824C)),
              title: Text("বন্ধুরা (Friends)", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
              subtitle: Text("শুধুমাত্র আপনার বন্ধুরা দেখতে পারবে", style: GoogleFonts.hindSiliguri(fontSize: 12, color: context.textSecondary)),
              trailing: _privacy == "Friends" ? const Icon(Icons.check, color: Color(0xFF1E824C)) : null,
              onTap: () {
                setState(() => _privacy = "Friends");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFF1E824C)),
              title: Text("শুধুমাত্র আমি (Only Me)", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
              subtitle: Text("কেউ দেখতে পারবে না", style: GoogleFonts.hindSiliguri(fontSize: 12, color: context.textSecondary)),
              trailing: _privacy == "Only Me" ? const Icon(Icons.check, color: Color(0xFF1E824C)) : null,
              onTap: () {
                setState(() => _privacy = "Only Me");
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    final locations = [
      "ঢাকা (Dhaka)",
      "চট্টগ্রাম (Chattogram)",
      "সিলেট (Sylhet)",
      "রাজশাহী (Rajshahi)",
      "খুলনা (Khulna)",
      "বরিশাল (Barishal)",
      "রংপুর (Rangpur)",
      "ময়মনসিংহ (Mymensingh)",
      "কক্সবাজার (Cox's Bazar)"
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: context.cardBg,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              "অবস্থান যোগ করুন (Add Location)",
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            Divider(color: context.border),
            Expanded(
              child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, i) => ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: Color(0xFF1E824C)),
                  title: Text(locations[i], style: GoogleFonts.hindSiliguri(color: context.textPrimary)),
                  onTap: () {
                    setState(() {
                      _selectedLocation = locations[i];
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateAIContent(String prompt, String style) {
    setState(() => _isGeneratingAI = true);
    Future.delayed(const Duration(seconds: 1200 ~/ 1000), () {
      String generated = "";
      final p = prompt.trim();
      final topic = p.isNotEmpty ? p : "জীবন";
      if (style == "Poetic") {
        generated = "নীল আকাশের মেঘে মেঘে,\nভাসে আমার মন যে জেগে।\n$topic নিয়ে ভাবছি বসে,\nস্বপ্নগুলো যাচ্ছে ভেসে।\n#ডাক #কবিতা";
      } else if (style == "Funny") {
        generated = "আরে ভাই! $topic নিয়ে কি বলবো আর? সকাল থেকে ভাবতে ভাবতে মাথার সব চুল উড়ে যাওয়ার উপক্রম! 🤣 কার কার এমন অবস্থা কমেন্টে জানান। #হাস্যকর #ডাক";
      } else {
        generated = "আসসালামু আলাইকুম। আজকে $topic নিয়ে কিছু গুরুত্বপূর্ণ আলোচনা করতে চাই। আমাদের সমাজে এর প্রভাব এবং কিভাবে আমরা এটি উন্নত করতে পারি, তা নিয়ে বিস্তারিত মতামত শেয়ার করুন। #মতামত #আলোচনা";
      }
      setState(() {
        _contentController.text = generated;
        _charCount = generated.length;
        _isGeneratingAI = false;
      });
      Navigator.pop(context);
    });
  }

  void _showAIAssistant() {
    final promptController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: context.cardBg,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "এআই রাইটার অ্যাসিস্ট্যান্ট (AI Writer)",
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1E824C),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textPrimary),
                      onPressed: () => Navigator.pop(sheetContext),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "আপনি কি বিষয় নিয়ে ডাক তৈরি করতে চান? নিচে লিখুন বা স্টাইল নির্বাচন করুন:",
                  style: GoogleFonts.hindSiliguri(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
                  decoration: InputDecoration(
                    hintText: "যেমন: প্রাকৃতিক সৌন্দর্য, পরীক্ষার অনুপ্রেরণা...",
                    hintStyle: GoogleFonts.hindSiliguri(fontSize: 13, color: context.textMuted),
                    filled: true,
                    fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.border),
                    ),
                  ),
                  style: GoogleFonts.hindSiliguri(fontSize: 14, color: context.textPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  "রাইটিং স্টাইল নির্বাচন করুন (Style):",
                  style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStyleChip("কবিতা (Poetic)", "Poetic", setSheetState),
                    const SizedBox(width: 8),
                    _buildStyleChip("হাস্যকর (Funny)", "Funny", setSheetState),
                    const SizedBox(width: 8),
                    _buildStyleChip("পেশাদারী (Professional)", "Professional", setSheetState),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isGeneratingAI
                        ? null
                        : () {
                            setSheetState(() {
                              _isGeneratingAI = true;
                            });
                            _generateAIContent(promptController.text, _selectedStyle);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isGeneratingAI
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            "লেখা তৈরি করুন (Generate)",
                            style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleChip(String label, String styleValue, StateSetter setSheetState) {
    final isSel = _selectedStyle == styleValue;
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _selectedStyle = styleValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1E824C).withOpacity(0.1) : (context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? const Color(0xFF1E824C) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: isSel ? const Color(0xFF1E824C) : context.textPrimary,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final prof = dbService.myProfile;
    final isEnabled = _contentController.text.trim().isNotEmpty && _charCount <= 500 && !_isUploadingImage;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    // Body content tree
    Widget bodyContent = Column(
      children: [
        // Custom Header Bar (Clean & Identical across views)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border(
              bottom: BorderSide(color: context.border, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Text(
                "নতুন ডাক তৈরি করুন",
                style: GoogleFonts.hindSiliguri(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isEnabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E824C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[400],
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
                        "পোস্ট",
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, fontSize: 13.5),
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
                          : (prof?.avatarUrl ?? "https://i.pravatar.cc/150"),
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
                            _isAnonymous ? "বেনামী ব্যবহারকারী" : (prof?.fullName ?? "ডাক ব্যবহারকারী"),
                            style: GoogleFonts.hindSiliguri(
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
                      
                      // Meta Row: Privacy and Location indicators
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          GestureDetector(
                            onTap: _showPrivacyPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
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
                                            : Icons.lock,
                                    size: 11,
                                    color: context.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _privacy == "Public" 
                                        ? "সবাই" 
                                        : _privacy == "Friends" 
                                            ? "বন্ধুরা" 
                                            : "শুধুমাত্র আমি",
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: context.textSecondary),
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
                                border: Border.all(color: Colors.blue.withOpacity(0.2), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 11, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedLocation!,
                                    style: GoogleFonts.hindSiliguri(
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
                      const SizedBox(height: 12),
                      
                      // Main TextField input
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 4,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15.5,
                          color: context.textPrimary,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText: "আজকে কী ভাবছেন?",
                          hintStyle: GoogleFonts.hindSiliguri(color: context.textMuted, fontSize: 14.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      // Image Selection preview box
                      if (_selectedImageBytes != null) ...[
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 220),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImageBytes = null;
                                    _selectedImageName = null;
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Custom Image URL Input
                      if (_showImageInput) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: "ছবির লিঙ্ক (Image URL)",
                            labelStyle: GoogleFonts.hindSiliguri(fontSize: 13, color: context.textSecondary),
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
                          style: GoogleFonts.hindSiliguri(fontSize: 14, color: context.textPrimary),
                        ),
                      ],

                      // Custom Video URL Input
                      if (_showVideoInput) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _videoUrlController,
                          decoration: InputDecoration(
                            labelText: "ভিডিও লিঙ্ক (Video URL)",
                            labelStyle: GoogleFonts.hindSiliguri(fontSize: 13, color: context.textSecondary),
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
                          style: GoogleFonts.hindSiliguri(fontSize: 14, color: context.textPrimary),
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
                color: Colors.black.withOpacity(0.06),
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
                    tooltip: "ছবি যোগ করুন",
                    color: const Color(0xFF1E824C),
                    isActive: _selectedImageBytes != null || _imageUrlController.text.isNotEmpty || _showImageInput,
                    onTap: _showImageSourceDialog,
                  ),
                  _buildToolbarIcon(
                    icon: Icons.camera_alt_outlined,
                    tooltip: "ক্যামেরা ছবি",
                    color: Colors.deepOrange,
                    isActive: false,
                    onTap: () async {
                      try {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image == null) return;
                        
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _selectedImageBytes = bytes;
                          _selectedImageName = image.name;
                          _showImageInput = false;
                        });
                      } catch (e) {
                        debugPrint("Camera capture error: $e");
                      }
                    },
                  ),
                  _buildToolbarIcon(
                    icon: Icons.play_circle_outline,
                    tooltip: "ভিডিও লিঙ্ক",
                    color: Colors.purple,
                    isActive: _showVideoInput || _videoUrlController.text.isNotEmpty,
                    onTap: () => setState(() => _showVideoInput = !_showVideoInput),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.bar_chart_outlined,
                    tooltip: "পোল তৈরি করুন",
                    color: Colors.orange,
                    isActive: _showPollInput,
                    onTap: () => setState(() => _showPollInput = !_showPollInput),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.mic_outlined,
                    tooltip: "ভয়েস মেসেজ",
                    color: Colors.teal,
                    isActive: _showVoiceRecorder,
                    onTap: () => setState(() => _showVoiceRecorder = !_showVoiceRecorder),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.location_on_outlined,
                    tooltip: "অবস্থান যোগ করুন",
                    color: Colors.blue,
                    isActive: _selectedLocation != null,
                    onTap: _showLocationPicker,
                  ),
                  _buildToolbarIcon(
                    icon: Icons.security_outlined,
                    tooltip: "বেনামী পোস্ট",
                    color: Colors.indigo,
                    isActive: _isAnonymous,
                    onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                  ),
                  _buildToolbarIcon(
                    icon: Icons.auto_awesome_outlined,
                    tooltip: "এআই রাইটার",
                    color: Colors.pink,
                    isActive: false,
                    onTap: _showAIAssistant,
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
                style: GoogleFonts.outfit(
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
                          : const Color(0xFF1E824C),
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
      textStyle: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 11),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color.withOpacity(0.3) : Colors.transparent,
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "পোল তৈরি করুন (Create Poll)",
                    style: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      fontSize: 13,
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
                child: Icon(Icons.close, size: 18, color: context.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_pollControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _pollControllers[index],
                decoration: InputDecoration(
                  hintText: "অপশন ${index + 1}",
                  hintStyle: GoogleFonts.hindSiliguri(fontSize: 13, color: context.textMuted),
                  filled: true,
                  fillColor: context.isDarkMode ? const Color(0xFF1E2030) : Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                style: GoogleFonts.hindSiliguri(fontSize: 13.5, color: context.textPrimary),
              ),
            );
          }),
          if (_pollControllers.length < 4)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _pollControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, size: 14, color: Colors.orange),
              label: Text(
                "অপশন যোগ করুন",
                style: GoogleFonts.hindSiliguri(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
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
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
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
            _isRecording ? "রেকর্ড হচ্ছে... ($minutes:$seconds)" : "ভয়েস রেকর্ড প্রস্তুত",
            style: GoogleFonts.hindSiliguri(
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
                _isRecording ? "থামান" : "শুরু করুন",
                style: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
