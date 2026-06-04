import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  String _privacy = "সবাই (Everyone)";

  @override
  void dispose() {
    _contentController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _contentController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final videoUrl = _videoUrlController.text.trim();

    if (text.isEmpty) return;

    final success = await Provider.of<DatabaseService>(context, listen: false)
        .createThread(
          text,
          imageUrls: imageUrl.isNotEmpty ? [imageUrl] : null,
          videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
        );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ডাক পোস্ট করতে ব্যর্থ হয়েছে")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final prof = dbService.myProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "নতুন ডাক",
          style: GoogleFonts.hindSiliguri(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _contentController,
              builder: (context, value, child) {
                final isEnabled = value.text.trim().isNotEmpty;
                return ElevatedButton(
                  onPressed: isEnabled ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "পোস্ট করুন",
                    style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(
                      prof?.avatarUrl ?? "https://i.pravatar.cc/150",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prof?.fullName ?? " ডাক ব্যবহারকারী",
                          style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: "কি ভাবছেন, বলুন...",
                            hintStyle: GoogleFonts.hindSiliguri(color: Colors.black26),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Photo URL Field
                        const SizedBox(height: 16),
                        TextField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            labelText: "ছবির লিঙ্ক (ঐচ্ছিক)",
                            labelStyle: GoogleFonts.hindSiliguri(fontSize: 13),
                            prefixIcon: const Icon(Icons.image_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        // Video URL Field
                        const SizedBox(height: 12),
                        TextField(
                          controller: _videoUrlController,
                          decoration: InputDecoration(
                            labelText: "ভিডিওর লিঙ্ক (ঐচ্ছিক)",
                            labelStyle: GoogleFonts.hindSiliguri(fontSize: 13),
                            prefixIcon: const Icon(Icons.video_collection_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Privacy Setting
              Text(
                "কে উত্তর দিতে পারবে?",
                style: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),

              RadioGroup<String>(
                groupValue: _privacy,
                onChanged: (val) {
                  setState(() {
                    _privacy = val!;
                  });
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text("সবাই (Everyone)", style: GoogleFonts.hindSiliguri()),
                      value: "সবাই (Everyone)",
                      activeColor: const Color(0xFF1E824C),
                    ),
                    RadioListTile<String>(
                      title: Text("আপনার অনুসারীরা", style: GoogleFonts.hindSiliguri()),
                      value: "আপনার অনুসারীরা",
                      activeColor: const Color(0xFF1E824C),
                    ),
                    RadioListTile<String>(
                      title: Text("নির্দিষ্ট ব্যক্তিরা", style: GoogleFonts.hindSiliguri()),
                      value: "নির্দিষ্ট ব্যক্তিরা",
                      activeColor: const Color(0xFF1E824C),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom toolbar icons
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.image_outlined, color: Colors.grey), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.mic_none, color: Colors.grey), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.alternate_email, color: Colors.grey), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
