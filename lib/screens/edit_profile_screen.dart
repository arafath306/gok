import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prof = Provider.of<DatabaseService>(context, listen: false).myProfile;
    if (prof != null) {
      _fullNameController.text = prof.fullName;
      _usernameController.text = prof.username;
      _bioController.text = prof.bio ?? '';
      _phoneController.text = prof.phone ?? '';
      _countryController.text = prof.country ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();
    final phone = _phoneController.text.trim();
    final country = _countryController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("নাম এবং ব্যবহারকারীর নাম আবশ্যক")),
      );
      return;
    }

    final success = await Provider.of<DatabaseService>(context, listen: false)
        .updateProfile(
          fullName: name,
          username: username,
          bio: bio,
          phone: phone,
          country: country,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("প্রোফাইল সফলভাবে আপডেট হয়েছে")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("প্রোফাইল আপডেট ব্যর্থ হয়েছে")),
      );
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Text(
            " *",
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "প্রোফাইল এডিট",
          style: GoogleFonts.hindSiliguri(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: dbService.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E824C)),
                  )
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "সংরক্ষণ",
                      style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                    ),
                  ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar edit section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: NetworkImage(
                            prof?.avatarUrl ?? "https://i.pravatar.cc/150",
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF1E824C),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "ছবি পরিবর্তন করুন",
                      style: GoogleFonts.hindSiliguri(
                        color: const Color(0xFF1E824C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Full Name Field
              _buildLabel("পুরো নাম"),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: "আপনার নাম লিখুন",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Username Field
              _buildLabel("ব্যবহারকারীর নাম (Username)"),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "username",
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bio Field
              _buildLabel("বায়ো (Bio)"),
              TextField(
                controller: _bioController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "আপনার বায়ো লিখুন",
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Phone Number Field
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "মোবাইল নম্বর",
                  style: GoogleFonts.hindSiliguri(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "যেমন: +8801XXXXXXXXX",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Country Field
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "দেশ (Country)",
                  style: GoogleFonts.hindSiliguri(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextField(
                controller: _countryController,
                decoration: InputDecoration(
                  hintText: "যেমন: বাংলাদেশ",
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Cover photo section
              _buildLabel("কভার ফটো"),
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      prof?.coverUrl ?? "https://images.unsplash.com/photo-1596404886561-12cdce3fbe25",
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "পরিবর্তন",
                          style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
              const Divider(color: Colors.black12),
              const SizedBox(height: 24),

              // Delete Account
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.red[50],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      "অ্যাকাউন্ট মুছুন",
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
