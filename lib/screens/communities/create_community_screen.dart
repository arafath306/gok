import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/community_service.dart';
import '../../utils/app_theme.dart';
import 'community_detail_screen.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Topic
  String? _selectedTopic;
  final List<Map<String, String>> _topics = [
    {"icon": "🍣", "label": "Anime & Cosplay"},
    {"icon": "👨‍🎨", "label": "Art"},
    {"icon": "💵", "label": "Business & Finance"},
    {"icon": "🧩", "label": "Collectibles & Hobbies"},
    {"icon": "👩‍🏫", "label": "Education & Career"},
    {"icon": "🪞", "label": "Fashion & Beauty"},
    {"icon": "🍔", "label": "Food & Drinks"},
    {"icon": "🕹️", "label": "Games"},
    {"icon": "❤️", "label": "Health"},
    {"icon": "🏡", "label": "Home & Garden"},
    {"icon": "📜", "label": "Humanities & Law"},
    {"icon": "🌈", "label": "Identity & Relationships"},
    {"icon": "🤡", "label": "Internet Culture"},
    {"icon": "🎞️", "label": "Movies & TV"},
    {"icon": "🎶", "label": "Music"},
    {"icon": "🌿", "label": "Nature & Outdoors"},
    {"icon": "📰", "label": "News & Politics"},
    {"icon": "🌎", "label": "Places & Travel"},
    {"icon": "✨", "label": "Pop Culture"},
    {"icon": "✏️", "label": "Q&As & Stories"},
  ];

  // Step 2: Privacy
  String _privacy = 'public';

  // Step 3: Details
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isCreating = false;

  bool _isCheckingHandle = false;
  bool _isHandleAvailable = false;
  Timer? _debounce;
  String? _createdCommunityId;

  // Step 4: Setup
  File? _avatarFile;
  final _ruleTitleController = TextEditingController();
  final _guideController = TextEditingController();
  bool _isSettingUp = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _handleController.dispose();
    _descController.dispose();
    _ruleTitleController.dispose();
    _guideController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _onNameChanged(String value) {
    if (_currentStep != 2) return;
    
    // Auto generate handle
    String generated = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    if (generated.isNotEmpty) {
      _handleController.text = generated;
      _checkHandleAvailability(generated);
    } else {
      _handleController.text = '';
      setState(() {
        _isHandleAvailable = false;
        _isCheckingHandle = false;
      });
    }
  }

  void _checkHandleAvailability(String handle) {
    if (handle.isEmpty) return;
    
    setState(() => _isCheckingHandle = true);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final service = Provider.of<CommunityService>(context, listen: false);
      final available = await service.isHandleAvailable(handle);
      if (mounted) {
        setState(() {
          _isHandleAvailable = available;
          _isCheckingHandle = false;
        });
      }
    });
  }

  Future<void> _createCommunity() async {
    final name = _nameController.text.trim();
    final handle = _handleController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty || handle.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    if (!_isHandleAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handle is not available.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final service = Provider.of<CommunityService>(context, listen: false);
    final communityId = await service.createCommunity(
      name: name,
      handle: handle,
      topic: _selectedTopic ?? 'General',
      description: desc,
      privacy: _privacy,
    );

    setState(() => _isCreating = false);

    if (communityId != null) {
      _createdCommunityId = communityId;
      _nextStep();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create community. Try again.')),
        );
      }
    }
  }

  Future<void> _finishSetup() async {
    if (_createdCommunityId == null) return;
    setState(() => _isSettingUp = true);
    
    final service = Provider.of<CommunityService>(context, listen: false);

    // Add Rules / Guide
    final ruleTitle = _ruleTitleController.text.trim();
    final guide = _guideController.text.trim();
    
    if (ruleTitle.isNotEmpty || guide.isNotEmpty) {
      await service.addCommunityRule(
        _createdCommunityId!,
        ruleTitle.isNotEmpty ? ruleTitle : "Community Guide",
        guide,
      );
    }

    // Upload avatar if selected in Step 4
    if (_avatarFile != null) {
      await service.updateCommunityAvatar(_createdCommunityId!, _avatarFile!);
    }

    final community = await service.getCommunityDetails(_createdCommunityId!);
    
    setState(() => _isSettingUp = false);

    if (mounted && community != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(community: community),
        ),
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: _prevStep,
        ),
        title: Text(
          "Step ${_currentStep + 1} of 4",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep < 3)
            TextButton(
              onPressed: () {
                if (_currentStep == 0 && _selectedTopic == null) return;
                if (_currentStep == 2) {
                  _createCommunity();
                } else {
                  _nextStep();
                }
              },
              child: _isCreating 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                  _currentStep == 2 ? "Create" : "Next",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: (_currentStep == 0 && _selectedTopic == null)
                        ? context.textSecondary
                        : const Color(0xFF1E824C),
                  ),
                ),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1Topic(),
          _buildStep2Privacy(),
          _buildStep3Details(),
          _buildStep4Setup(),
        ],
      ),
    );
  }

  // ─── STEP 1: TOPIC ───────────────────────────────────────────────
  Widget _buildStep1Topic() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What is your community about?",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose a topic to help users discover your community.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _topics.map((t) {
                  final isSelected = _selectedTopic == t['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTopic = t['label']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF1E824C).withValues(alpha: 0.1) 
                            : context.scaffoldBg,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1E824C) : context.border,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t['icon']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            t['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1E824C) : context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: PRIVACY ─────────────────────────────────────────────
  Widget _buildStep2Privacy() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Community Type",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Decide who can view and contribute.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildPrivacyOption(
            value: 'public',
            icon: Icons.public,
            title: "Public",
            desc: "Anyone can view, post, and comment to this community.",
          ),
          const SizedBox(height: 16),
          _buildPrivacyOption(
            value: 'restricted',
            icon: Icons.visibility,
            title: "Restricted",
            desc: "Anyone can view this community, but only approved users can post.",
          ),
          const SizedBox(height: 16),
          _buildPrivacyOption(
            value: 'private',
            icon: Icons.lock,
            title: "Private",
            desc: "Only approved users can view and submit to this community.",
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String value,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isSelected = _privacy == value;
    return GestureDetector(
      onTap: () => setState(() => _privacy = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E824C).withValues(alpha: 0.05) : context.cardBg,
          border: Border.all(
            color: isSelected ? const Color(0xFF1E824C) : context.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1E824C) : context.textSecondary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _privacy,
              activeColor: const Color(0xFF1E824C),
              // ignore: deprecated_member_use
              onChanged: (v) {
                if (v != null) setState(() => _privacy = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: DETAILS ─────────────────────────────────────────────
  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About your community",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name Field
          Text("Community Name", style: _labelStyle()),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: _onNameChanged,
            style: GoogleFonts.inter(color: context.textPrimary),
            decoration: _inputDecoration("e.g. Book Club"),
          ),
          const SizedBox(height: 20),

          // Handle Field
          Text("Community Handle (Unique)", style: _labelStyle()),
          const SizedBox(height: 8),
          TextField(
            controller: _handleController,
            onChanged: _checkHandleAvailability,
            style: GoogleFonts.inter(color: context.textPrimary),
            decoration: _inputDecoration("e.g. book_club").copyWith(
              prefixText: "d/",
              prefixStyle: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.bold),
              suffixIcon: _handleController.text.isNotEmpty
                  ? _isCheckingHandle
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : Icon(
                          _isHandleAvailable ? Icons.check_circle : Icons.cancel,
                          color: _isHandleAvailable ? Colors.green : Colors.red,
                        )
                  : null,
            ),
          ),
          if (_handleController.text.isNotEmpty && !_isCheckingHandle)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _isHandleAvailable ? "Handle is available!" : "Handle is already taken.",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _isHandleAvailable ? Colors.green : Colors.red,
                ),
              ),
            ),
          
          const SizedBox(height: 20),

          // Description Field
          Text("Description (Required)", style: _labelStyle()),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: GoogleFonts.inter(color: context.textPrimary),
            decoration: _inputDecoration("What is this community about?"),
          ),
        ],
      ),
    );
  }

  // ─── STEP 4: SETUP ───────────────────────────────────────────────
  Widget _buildStep4Setup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          Text(
            "Congratulations! 🎉",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your community is ready. Let's add some finishing touches.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Avatar
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: context.cardBg,
                  backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? Icon(Icons.groups_rounded, size: 40, color: context.textSecondary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E824C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          Text(
            "d/${_handleController.text}",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF1E824C),
            ),
          ),
          const SizedBox(height: 32),

          // Rules & Guide input side-by-side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rules (Optional)", style: _labelStyle()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ruleTitleController,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: _inputDecoration("e.g. Be respectful"),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Community Guide", style: _labelStyle()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _guideController,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: _inputDecoration("Elaborate the rule..."),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSettingUp ? null : _finishSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E824C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: _isSettingUp 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Go to Community", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UTILS ───────────────────────────────────────────────────────
  TextStyle _labelStyle() {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: context.textPrimary,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: context.textSecondary),
      filled: true,
      fillColor: context.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E824C), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
