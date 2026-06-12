import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../dashboard_screen.dart';
import '../../utils/routes.dart';

class BoostWizardScreen extends StatefulWidget {
  final String postType;
  final Map<String, dynamic> postData;

  const BoostWizardScreen({
    super.key,
    required this.postType,
    required this.postData,
  });

  @override
  State<BoostWizardScreen> createState() => _BoostWizardScreenState();
}

class _BoostWizardScreenState extends State<BoostWizardScreen> {
  int _currentStep = 0; // Steps 0 to 10
  
  // STEP 2 STATE (Audience Settings)
  String _audienceType = "auto"; // 'auto' or 'custom'
  RangeValues _ageRange = const RangeValues(18, 65);
  String _selectedGender = "সকল"; // সকল, পুরুষ, নারী, অন্যান্য
  
  // STEP 3 STATE (Location)
  final Set<String> _selectedLocations = {"বাংলাদেশ (সারা দেশ)"};
  String _locationSearchQuery = "";
  final List<String> _allLocations = [
    "বাংলাদেশ (সারা দেশ)",
    "ঢাকা বিভাগ",
    "চট্টগ্রাম বিভাগ",
    "রাজশাহী বিভাগ",
    "খুলনা বিভাগ",
    "বরিশাল বিভাগ",
    "সিলেট বিভাগ",
    "রংপুর বিভাগ"
  ];

  // STEP 4 STATE (Budget & Duration)
  String _budgetMode = "budget"; // 'budget' or 'viewer'
  double _targetViewers = 2500; // default 2500 viewers
  int _selectedBudget = 500; // default 500৳
  int _selectedDuration = 3; // default 3 days
  final List<int> _budgetOptions = [100, 200, 500, 1000];
  final List<int> _durationOptions = [1, 3, 7, 14];
  bool _isCustomBudget = false;
  final TextEditingController _customBudgetCtrl = TextEditingController();
  bool _isCustomViewers = false;
  final TextEditingController _customViewersCtrl = TextEditingController();

  // STEP 5 STATE (Placements)
  final Map<String, bool> _placements = {
    "নিউজ ফিড": true,
    "প্রোফাইল ফিড": true,
    "গ্রুপ ফিড": true,
    "মার্কেটপ্লেস": false,
    "স্টোরি": false,
  };

  // STEP 6 STATE (Edit Ad)
  late TextEditingController _primaryTextCtrl;
  late TextEditingController _headlineCtrl;
  String _selectedCallToAction = "আরও জানুন";
  // TODO: LATER BACKEND INTEGRATION - When the boost campaign is started with "লাইক করুন" CTA,
  // target audience likes need to be synced directly to the user's profile.
  final List<String> _ctaOptions = ["আরও জানুন", "মেসেজ পাঠান", "যোগাযোগ করুন", "এখনই কিনুন", "বুক করুন", "লাইক করুন"];
  String _boostMediaType = "photo"; // 'photo' or 'text'
  late String _adImage;

  // STEP 7 STATE (Advanced settings)
  final List<String> _interests = ["কফি", "রেস্তোরাঁ", "ফুড", "ট্রাভেল"];
  final List<String> _behaviors = ["অনলাইন শপিং", "ফুড লাভার"];
  final TextEditingController _interestInputCtrl = TextEditingController();
  final TextEditingController _behaviorInputCtrl = TextEditingController();

  // STEP 8 STATE (Optimization)
  String _optimizationGoal = "পোস্ট এঙ্গেজমেন্ট"; // পোস্ট এঙ্গেজমেন্ট, লিংক ক্লিক, রিচ, মেসেজ

  // STEP 9 STATE (Payment method)
  String _paymentMethod = "wallet"; // 'wallet', 'bkash', 'nagad', 'rocket', 'card'

  @override
  void initState() {
    super.initState();
    _primaryTextCtrl = TextEditingController(text: widget.postData['text'] ?? "");
    _headlineCtrl = TextEditingController(text: widget.postData['title'] ?? "");
    _adImage = widget.postData['image'] ?? "assets/logo_d_icon_v2.jpg";
  }

  @override
  void dispose() {
    _customBudgetCtrl.dispose();
    _customViewersCtrl.dispose();
    _primaryTextCtrl.dispose();
    _headlineCtrl.dispose();
    _interestInputCtrl.dispose();
    _behaviorInputCtrl.dispose();
    super.dispose();
  }

  // Bengali translation of digits
  String _toBengaliNumber(String englishNumber) {
    const Map<String, String> translation = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    return englishNumber.split('').map((char) => translation[char] ?? char).join();
  }

  // Helper to get selected locations formatted
  String _getLocationsText() {
    if (_selectedLocations.isEmpty) return "লোকেশন সিলেক্ট করুন";
    if (_selectedLocations.contains("বাংলাদেশ (সারা দেশ)")) return "বাংলাদেশ (সারা দেশ)";
    return _selectedLocations.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    // Determine title of screen based on current step
    String title = "পোস্ট বুস্ট করুন";
    if (_currentStep == 2) title = "লোকেশন নির্ধারণ করুন";
    if (_currentStep == 4) title = "অ্যাড প্লেসমেন্ট";
    if (_currentStep == 5) title = "অ্যাড এডিট করুন";
    if (_currentStep == 6) title = "অ্যাড সেটিংস (উন্নত)";
    if (_currentStep == 7) title = "বাজেট অপ্টিমাইজেশন";
    if (_currentStep == 8) title = "অর্ডার পর্যালোচনা";
    if (_currentStep == 9) title = "পেমেন্ট";
    if (_currentStep == 10) title = "বুস্ট চালু";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: _currentStep == 10
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    if (_currentStep == 2) {
                      _currentStep = 1; // Go back to Audience Settings
                    } else if (_currentStep == 3) {
                      _currentStep = 1; // Go back to Audience Settings from Budget
                    } else if (_currentStep > 0) {
                      _currentStep--;
                    } else {
                      Navigator.pop(context);
                    }
                  });
                },
              ),
        title: Text(
          title,
          style: GoogleFonts.hindSiliguri(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step progress indicator header (only for specific steps)
          if (_currentStep != 2 && _currentStep < 8) _buildWizardHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: _buildStepContent(),
            ),
          ),
          
          // Navigation controls footer
          if (_currentStep < 10) _buildWizardFooter(),
        ],
      ),
    );
  }

  // Wizard Header displaying Steps (Step 1 -> Step 2 -> Step 3 indicator)
  Widget _buildWizardHeader() {
    int activeSection = 0; // 0 for post selection, 1 for audience, 2 for budget/time
    if (_currentStep == 1) activeSection = 1;
    if (_currentStep >= 3) activeSection = 2;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _buildStepIndicator(0, "পোস্ট নির্বাচন", activeSection == 0),
          _buildStepLine(),
          _buildStepIndicator(1, "অডিয়েন্স", activeSection == 1),
          _buildStepLine(),
          _buildStepIndicator(2, "বাজেট ও সময়", activeSection == 2),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int idx, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF1E824C) : Colors.grey[200],
          ),
          child: Center(
            child: Text(
              _toBengaliNumber((idx + 1).toString()),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 9.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF1E824C) : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.grey[300],
      ),
    );
  }

  // Step Content Router
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepPostSelectionOverview();
      case 1:
        return _buildStepAudienceSelection();
      case 2:
        return _buildStepLocationSelection();
      case 3:
        return _buildStepBudgetAndDuration();
      case 4:
        return _buildStepAdPlacement();
      case 5:
        return _buildStepAdEditing();
      case 6:
        return _buildStepAdvancedSettings();
      case 7:
        return _buildStepOptimizationGoal();
      case 8:
        return _buildStepOrderReview();
      case 9:
        return _buildStepPaymentSelection();
      case 10:
        return _buildStepSuccessCompleted();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: Selected Post Preview & Benefits List
  Widget _buildStepPostSelectionOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বুস্ট করার জন্য পোস্ট নির্ধারণ করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),

        // Selected post card preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: const AssetImage('assets/logo_d_icon_v2.jpg'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dak Official",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.postType == 'marketplace' ? "মার্কেটপ্লেস প্রডাক্ট" : "স্পন্সরড রিচ",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.postData['text'] ?? "",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12.5,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAdImageWidget(
                  _adImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Select other post
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, color: Color(0xFF1E824C), size: 18),
                const SizedBox(width: 6),
                Text(
                  "অন্য পোস্ট নির্বাচন করুন",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: const Color(0xFF1E824C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Benefits Checklist
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "বুস্ট করলে আপনি পাবেন:",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildBenefitRow(Icons.people_outline_rounded, "বেশি মানুষের দেখা", "আপনার পোস্ট ও ব্র্যান্ডটি আরও হাজারো সম্ভাব্য কাস্টমারের কাছে পৌঁছে যাবে।"),
              const SizedBox(height: 10),
              _buildBenefitRow(Icons.thumb_up_alt_outlined, "বেশি এঙ্গেজমেন্ট", "পোস্টে লাইক, কমেন্ট, শেয়ার ও মেসেজ প্রদানের সম্ভাবনা উল্লেখযোগ্য হারে বাড়বে।"),
              const SizedBox(height: 10),
              _buildBenefitRow(Icons.insights_rounded, "আপনার ব্র্যান্ড পরিচিতি বৃদ্ধি", "নতুন ফলোয়ার তৈরি হবে এবং দীর্ঘস্থায়ী ক্রেতা সাধারণের সমাগম হবে।"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1E824C), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 10.5,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 1: Audience Selection Options
  Widget _buildStepAudienceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "অডিয়েন্স সেট করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        // Automatic Audience (Recommended)
        _buildAudienceTypeCard(
          type: "auto",
          title: "স্বয়ংক্রিয় অডিয়েন্স (সুপারিশকৃত)",
          subtitle: "Dak এর AI আপনার জন্য সর্বোত্তম অডিয়েন্স খুঁজে নেবে এবং সাশ্রয়ী বাজেটে বুস্ট সম্পন্ন করবে।",
          icon: Icons.psychology_outlined,
        ),

        const SizedBox(height: 10),

        // Custom Audience
        _buildAudienceTypeCard(
          type: "custom",
          title: "কাস্টম অডিয়েন্স",
          subtitle: "আপনার পণ্য বা সেবার সঠিক গ্রাহক বাছাই করতে নিজেই বয়স, লিঙ্গ ও এলাকা নির্বাচন করুন।",
          icon: Icons.person_search_outlined,
        ),

        const SizedBox(height: 20),

        // Custom Targeting panel (only visible when 'custom' is selected)
        if (_audienceType == "custom") ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "টার্গেটিং ফিল্টার",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Location selector trigger
                Text(
                  "লোকেশন:",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getLocationsText(),
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = 2; // Jump to Step 2: Location selector
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "লোকেশন পরিবর্তন করুন",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11.5,
                            color: const Color(0xFF1E824C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Age range slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "বয়স সীমা:",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      "${_toBengaliNumber(_ageRange.start.toInt().toString())} - ${_toBengaliNumber(_ageRange.end.toInt().toString())}+",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E824C),
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 13,
                  max: 65,
                  divisions: 52,
                  activeColor: const Color(0xFF1E824C),
                  inactiveColor: Colors.grey[200],
                  onChanged: (values) {
                    setState(() {
                      _ageRange = values;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Gender checklist
                Text(
                  "লিঙ্গ:",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: ["সকল", "পুরুষ", "নারী", "অন্যান্য"].map((gender) {
                    final isSel = _selectedGender == gender;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          gender,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E824C),
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedGender = gender;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          )
        ],
      ],
    );
  }

  // Audience selector cards
  Widget _buildAudienceTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _audienceType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _audienceType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, left: 2, right: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E824C) : Colors.black38,
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: isSelected ? const Color(0xFF1E824C) : Colors.black54, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: Location Selection Screen
  Widget _buildStepLocationSelection() {
    final filteredLocations = _allLocations
        .where((loc) => loc.toLowerCase().contains(_locationSearchQuery.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (v) {
            setState(() {
              _locationSearchQuery = v;
            });
          },
          decoration: InputDecoration(
            hintText: "অঞ্চল বা শহর সার্চ করুন",
            hintStyle: GoogleFonts.hindSiliguri(color: Colors.black38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.black45),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E824C), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          style: GoogleFonts.hindSiliguri(fontSize: 13),
        ),

        const SizedBox(height: 16),

        // List of divisions
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            children: filteredLocations.map((loc) {
              final isChecked = _selectedLocations.contains(loc);
              return Column(
                children: [
                  CheckboxListTile(
                    activeColor: const Color(0xFF1E824C),
                    value: isChecked,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          if (loc == "বাংলাদেশ (সারা দেশ)") {
                            _selectedLocations.clear();
                            _selectedLocations.add("বাংলাদেশ (সারা দেশ)");
                          } else {
                            _selectedLocations.remove("বাংলাদেশ (সারা দেশ)");
                            _selectedLocations.add(loc);
                          }
                        } else {
                          _selectedLocations.remove(loc);
                        }
                      });
                    },
                    title: Text(
                      loc,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (loc != filteredLocations.last)
                    const Divider(height: 1, color: Color(0xFFF1F1F1)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // STEP 3: Budget & Duration
  Widget _buildStepBudgetAndDuration() {
    final totalBudget = _selectedBudget * _selectedDuration;
    final minReach = (totalBudget * 12.5).round();
    final maxReach = (totalBudget * 18.0).round();
    final minConv = (totalBudget * 0.1).round();
    final maxConv = (totalBudget * 0.25).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector Tab Row
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _budgetMode = "budget";
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _budgetMode == "budget" ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _budgetMode == "budget"
                          ? [BoxShadow(color: Colors.black.withAlpha(0x0A), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "বাজেট ভিত্তিক",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _budgetMode == "budget" ? const Color(0xFF1E824C) : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _budgetMode = "viewer";
                      // Sync target viewers with selected budget (1 view = 0.20৳)
                      _targetViewers = (_selectedBudget / 0.2).clamp(500.0, 50000.0);
                      _customViewersCtrl.text = _targetViewers.round().toString();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _budgetMode == "viewer" ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _budgetMode == "viewer"
                          ? [BoxShadow(color: Colors.black.withAlpha(0x0A), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "ভিউয়ার সংখ্যা ভিত্তিক",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _budgetMode == "viewer" ? const Color(0xFF1E824C) : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_budgetMode == "budget") ...[
          // Daily Budget Selection
          Text(
            "দৈনিক বাজেট নির্ধারণ করুন",
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "বাজেট:",
                style: GoogleFonts.hindSiliguri(fontSize: 12.5, color: Colors.black54),
              ),
              InkWell(
                onTap: () => _showEstimationDetailsDialog(totalBudget),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_toBengaliNumber(_selectedBudget.toString())} ৳ / দৈনিক",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E824C),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1E824C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._budgetOptions.map((budget) {
                final isSel = !_isCustomBudget && _selectedBudget == budget;
                return ChoiceChip(
                  label: Text(
                    "৳ ${_toBengaliNumber(budget.toString())}",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12.5,
                      color: isSel ? Colors.white : Colors.black87,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF1E824C),
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustomBudget = false;
                        _selectedBudget = budget;
                      });
                    }
                  },
                );
              }),
              ChoiceChip(
                label: Text(
                  "অন্যান্য",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5,
                    color: _isCustomBudget ? Colors.white : Colors.black87,
                    fontWeight: _isCustomBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: _isCustomBudget,
                selectedColor: const Color(0xFF1E824C),
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    _isCustomBudget = true;
                    _customBudgetCtrl.text = _selectedBudget.toString();
                  });
                },
              ),
            ],
          ),

          if (_isCustomBudget) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customBudgetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "বাজেট লিখুন (৳)",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: GoogleFonts.outfit(fontSize: 13),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed >= 50) {
                  setState(() {
                    _selectedBudget = parsed;
                  });
                }
              },
            ),
          ],
        ] else ...[
          // Viewer Target Selection
          Text(
            "কাঙ্ক্ষিত ভিউয়ার সংখ্যা নির্ধারণ করুন",
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "টার্গেট ভিউয়ার:",
                style: GoogleFonts.hindSiliguri(fontSize: 12.5, color: Colors.black54),
              ),
              InkWell(
                onTap: () => _showEstimationDetailsDialog(totalBudget),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_toBengaliNumber(_targetViewers.round().toString())} জন / দৈনিক",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E824C),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1E824C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _targetViewers.clamp(500.0, 50000.0),
            min: 500,
            max: 50000,
            divisions: 99,
            activeColor: const Color(0xFF1E824C),
            inactiveColor: Colors.grey[200],
            onChanged: (val) {
              setState(() {
                _targetViewers = val;
                // Recalculate daily budget: 1 view = 0.20৳
                _selectedBudget = (_targetViewers * 0.2).round();
                if (_isCustomViewers) {
                  _customViewersCtrl.text = _targetViewers.round().toString();
                }
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "৫০০ ভিউয়ার (৳১০০)",
                style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black38),
              ),
              InkWell(
                onTap: () => _showEstimationDetailsDialog(totalBudget),
                child: Text(
                  "আনুমানিক দৈনিক খরচ: ৳${_toBengaliNumber(_selectedBudget.toString())}",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10.5,
                    color: const Color(0xFF1E824C),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                "৫০,০০০ ভিউয়ার (৳১০,০০০)",
                style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Viewer chips selection
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...[1000, 2500, 5000, 10000].map((viewerCount) {
                final isSel = !_isCustomViewers && _targetViewers.round() == viewerCount;
                return ChoiceChip(
                  label: Text(
                    "${_toBengaliNumber(viewerCount.toString())} জন",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12.5,
                      color: isSel ? Colors.white : Colors.black87,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: const Color(0xFF1E824C),
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustomViewers = false;
                        _targetViewers = viewerCount.toDouble();
                        _selectedBudget = (_targetViewers * 0.2).round();
                      });
                    }
                  },
                );
              }),
              ChoiceChip(
                label: Text(
                  "অন্যান্য",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5,
                    color: _isCustomViewers ? Colors.white : Colors.black87,
                    fontWeight: _isCustomViewers ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: _isCustomViewers,
                selectedColor: const Color(0xFF1E824C),
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    _isCustomViewers = true;
                    _customViewersCtrl.text = _targetViewers.round().toString();
                  });
                },
              ),
            ],
          ),

          if (_isCustomViewers) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customViewersCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "ভিউয়ার সংখ্যা লিখুন",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: "জন / দৈনিক",
                suffixStyle: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black45),
              ),
              style: GoogleFonts.outfit(fontSize: 13),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed >= 100) {
                  setState(() {
                    _targetViewers = parsed.toDouble();
                    // Recalculate daily budget: 1 view = 0.20৳
                    _selectedBudget = (_targetViewers * 0.2).round();
                  });
                }
              },
            ),
          ],
        ],

        const SizedBox(height: 24),

        // Duration Selection
        Text(
          "মেয়াদ ও সময়কাল",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "সময়কাল:",
              style: GoogleFonts.hindSiliguri(fontSize: 12.5, color: Colors.black54),
            ),
            Text(
              "${_toBengaliNumber(_selectedDuration.toString())} দিন",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E824C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: _durationOptions.map((days) {
            final isSel = _selectedDuration == days;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  "${_toBengaliNumber(days.toString())} দিন",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5,
                    color: isSel ? Colors.white : Colors.black87,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSel,
                selectedColor: const Color(0xFF1E824C),
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDuration = days;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Clickable Estimated Insights Panel
        InkWell(
          onTap: () => _showEstimationDetailsDialog(totalBudget),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "মোট বাজেট (আনুমানিক):",
                      style: GoogleFonts.hindSiliguri(fontSize: 12.5, color: Colors.black87),
                    ),
                    Row(
                      children: [
                        Text(
                          "৳ ${_toBengaliNumber(totalBudget.toString())}",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E824C),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1E824C)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${_toBengaliNumber(_selectedDuration.toString())} দিন × ${_toBengaliNumber(_selectedBudget.toString())} ৳ প্রতি দিন",
                  style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black45),
                ),
                const Divider(height: 16, color: Color(0xFFF1F1F1)),
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      "আনুমানিক পৌঁছাবে (Reach): ",
                      style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      "${_toBengaliNumber(minReach.toString())} - ${_toBengaliNumber(maxReach.toString())} জন",
                      style: GoogleFonts.hindSiliguri(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      "আনুমানিক কনভার্সন (Conversions): ",
                      style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      "${_toBengaliNumber(minConv.toString())} - ${_toBengaliNumber(maxConv.toString())} টি সেলস",
                      style: GoogleFonts.hindSiliguri(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "এখানে ট্যাপ করে বিস্তারিত ফলাফল ও এনালাইটিক্স প্রাক্কলন দেখুন।",
                    style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: const Color(0xFF1E824C), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Wallet display container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.black54, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Dak Wallet (৳ ২,৪৫০ উপলব্ধ)",
                    style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              Text(
                "পরিবর্তন",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  color: const Color(0xFF1E824C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show detailed reach & conversion estimations modal sheet/dialog
  void _showEstimationDetailsDialog(int totalBudget) {
    final minReach = (totalBudget * 12.5).round();
    final maxReach = (totalBudget * 18.0).round();
    final minEng = (totalBudget * 1.5).round();
    final maxEng = (totalBudget * 2.8).round();
    final minConv = (totalBudget * 0.1).round();
    final maxConv = (totalBudget * 0.25).round();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF1E824C), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "বিজ্ঞাপন প্রাক্কলন বিশ্লেষণ",
                          style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "আনুমানিক ফলাফল ও কার্যকারিতা প্রক্ষেপণ",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "মোট বাজেট ও মেয়াদ:",
                          style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          "৳ ${_toBengaliNumber(totalBudget.toString())} (${_toBengaliNumber(_selectedDuration.toString())} দিন)",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E824C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "আপনার নির্বাচিত বাজেট ৳${_toBengaliNumber(totalBudget.toString())} এবং মেয়াদকাল ${_toBengaliNumber(_selectedDuration.toString())} দিনের ভিত্তিতে আনুমানিক ফলাফল বিশ্লেষণ করা হলো:",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics list
              _buildEstimationDetailItem(
                Icons.people_outline_rounded,
                "মোট পৌঁছাবে (Total Reach)",
                "${_toBengaliNumber(minReach.toString())} - ${_toBengaliNumber(maxReach.toString())} জন",
                "আপনার বাজেট দিয়ে সম্ভাব্য কতজন মানুষের স্ক্রিনে এই বিজ্ঞাপনটি পৌঁছাতে পারে তার প্রাক্কলন।",
              ),
              const SizedBox(height: 16),
              _buildEstimationDetailItem(
                Icons.touch_app_outlined,
                "এঙ্গেজমেন্ট (Engagement)",
                "${_toBengaliNumber(minEng.toString())} - ${_toBengaliNumber(maxEng.toString())} টি",
                "লাইক, কমেন্ট, রিয়্যাকশন এবং শেয়ারের আনুমানিক সংখ্যা।",
              ),
              const SizedBox(height: 16),
              _buildEstimationDetailItem(
                Icons.shopping_bag_outlined,
                "কনভার্সন (Expected Sales)",
                "${_toBengaliNumber(minConv.toString())} - ${_toBengaliNumber(maxConv.toString())} টি সেলস",
                "মেসেজ রেসপন্স বা কাস্টমারের প্রডাক্ট অর্ডারের আনুমানিক রূপান্তর হার।",
              ),
              const SizedBox(height: 24),

              // CTA close button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "ঠিক আছে",
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstimationDetailItem(IconData icon, String title, String value, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E824C), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black45, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdImageWidget(String imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      if (imagePath.startsWith('http') || imagePath.startsWith('blob:')) {
        return Image.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
        );
      } else {
        return Image.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/logo_d_icon_v2.jpg',
              width: width,
              height: height,
              fit: fit,
            );
          },
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _adImage = image.path;
        });
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPhotoEditDialog() {
    final List<String> libraryImages = [
      "assets/logo_d_icon_v2.jpg",
      "assets/logo.jpg",
      "assets/d_logo.jpg",
      "assets/onboarding_illus_1.png",
      "assets/onboarding_illus_2.png",
      "assets/onboarding_illus_3.png",
      "assets/onboarding_illus_4.png",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "বিজ্ঞাপনের ছবি পরিবর্তন করুন",
                style: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickImageFromGallery,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1E824C), width: 1),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFE8F5E9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, color: Color(0xFF1E824C), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "গ্যালারি থেকে ছবি আপলোড করুন",
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E824C),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "অথবা লাইব্রেরি থেকে সিলেক্ট করুন:",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: libraryImages.length,
                  itemBuilder: (context, index) {
                    final imgPath = libraryImages[index];
                    final isSelected = _adImage == imgPath;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _adImage = imgPath;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E824C) : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(0x0F),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(imgPath, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInterestsBehaviorsGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.contact_support_outlined, color: Color(0xFF1E824C), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "টার্গেটিং গাইডলাইন",
                          style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "গ্রাহকের আগ্রহ ও আচরণ নির্ধারণের সঠিক নিয়ম",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_border_rounded, color: Color(0xFF1E824C), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "গ্রাহকের আগ্রহ (Interests)",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E824C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "• গ্রাহকরা কোন কোন বিষয় পছন্দ করেন, কোন পেজ ফলো করেন বা কোন কোন শখের সাথে জড়িত তা বোঝায়।\n• উদাহরণ: কফি, অনলাইন শপিং, গেমিং, ট্রাভেলিং, ফ্যাশন ইত্যাদি।\n• ব্যবহার: আপনার পণ্যটি যে বিষয়ের সাথে সম্পর্কিত, গ্রাহকদের সেই আগ্রহের ট্যাগগুলো এখানে লিখুন।",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11.5,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, color: Color(0xFF1E824C), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "গ্রাহকের আচরণ (Behaviors)",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E824C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "• গ্রাহকরা সাধারণত কোন কোন ডিভাইসে ফেসবুক/অ্যাপ ব্যবহার করেন, তাদের ক্রয়ের অভ্যাস কেমন বা কর্মক্ষেত্র ও পদবি কেমন তা নির্দেশ করে।\n• উদাহরণ: নিয়মিত অনলাইন শপিংকারী, আইফোন ব্যবহারকারী, ঘন ঘন ভ্রমণকারী ইত্যাদি।\n• ব্যবহার: আপনার ক্রেতাদের বিশেষ ডিজিটাল বা বাস্তব অভ্যাস ও আচরণগত ট্যাগগুলো এখানে লিখুন।",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11.5,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "বুঝতে পেরেছি",
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // STEP 4: Ad Placement Checkboxes
  Widget _buildStepAdPlacement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "আপনার পোস্ট কোথায় দেখানো হবে",
          style: GoogleFonts.hindSiliguri(
            fontSize: 13.5,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            children: _placements.keys.map((key) {
              final isChecked = _placements[key] ?? false;
              IconData placementIcon = Icons.dashboard_outlined;
              if (key == "নিউজ ফিড") placementIcon = Icons.newspaper_rounded;
              if (key == "প্রোফাইল ফিড") placementIcon = Icons.account_circle_outlined;
              if (key == "গ্রুপ ফিড") placementIcon = Icons.groups_outlined;
              if (key == "মার্কেটপ্লেস") placementIcon = Icons.storefront_outlined;
              if (key == "স্টোরি") placementIcon = Icons.amp_stories_outlined;

              return Column(
                children: [
                  CheckboxListTile(
                    activeColor: const Color(0xFF1E824C),
                    value: isChecked,
                    onChanged: (checked) {
                      setState(() {
                        _placements[key] = checked ?? false;
                      });
                    },
                    secondary: Icon(placementIcon, color: isChecked ? const Color(0xFF1E824C) : Colors.black45, size: 20),
                    title: Text(
                      key,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (key != _placements.keys.last)
                    const Divider(height: 1, color: Color(0xFFF1F1F1)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // STEP 5: Edit Ad Copy & CTA
  Widget _buildStepAdEditing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বিজ্ঞাপনের বিষয়বস্তু সংশোধন করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        // Photo vs Text boost tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _boostMediaType = "photo";
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _boostMediaType == "photo" ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _boostMediaType == "photo"
                          ? [BoxShadow(color: Colors.black.withAlpha(0x05), blurRadius: 4)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "ফটো বুস্ট",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _boostMediaType == "photo" ? Colors.black87 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _boostMediaType = "text";
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _boostMediaType == "text" ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _boostMediaType == "text"
                          ? [BoxShadow(color: Colors.black.withAlpha(0x05), blurRadius: 4)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "টেক্সট বুস্ট",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _boostMediaType == "text" ? Colors.black87 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_boostMediaType == "photo") ...[
          // Media box
          Text(
            "মিডিয়া:",
            style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildAdImageWidget(_adImage, width: 44, height: 44),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.postData['title']!,
                    style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _showPhotoEditDialog,
                  child: Text(
                    "এডিট করুন",
                    style: GoogleFonts.hindSiliguri(color: const Color(0xFF1E824C), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Primary text
        Text(
          "প্রাথমিক টেক্সট:",
          style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _primaryTextCtrl,
          maxLines: 3,
          maxLength: 250,
          decoration: InputDecoration(
            hintText: "পোস্টের টেক্সট লিখুন...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            contentPadding: const EdgeInsets.all(10),
          ),
          style: GoogleFonts.hindSiliguri(fontSize: 12.5),
        ),

        const SizedBox(height: 12),

        // Headline
        Text(
          "শিরোনাম (ঐচ্ছিক):",
          style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _headlineCtrl,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: "যেমন: বিশেষ ছাড় চলছে!",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
            contentPadding: const EdgeInsets.all(10),
          ),
          style: GoogleFonts.hindSiliguri(fontSize: 12.5),
        ),

        const SizedBox(height: 12),

        // Button option
        Text(
          "অ্যাকশন বাটন:",
          style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedCallToAction,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
          ),
          items: _ctaOptions.map((opt) => DropdownMenuItem(
            value: opt,
            child: Text(opt, style: GoogleFonts.hindSiliguri(fontSize: 12.5)),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCallToAction = val;
              });
            }
          },
        ),
      ],
    );
  }

  // STEP 6: Advanced Settings (Interests & Behaviors)
  Widget _buildStepAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "উন্নত টার্গেটিং সেটিংস",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        // Targeting Overview card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "টার্গেটিং সংক্ষেপ",
                style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 16),
              _buildTargetRow("লোকেশন", _getLocationsText()),
              const SizedBox(height: 8),
              _buildTargetRow("বয়সসীমা", "${_toBengaliNumber(_ageRange.start.toInt().toString())} - ${_toBengaliNumber(_ageRange.end.toInt().toString())} বছর"),
              const SizedBox(height: 8),
              _buildTargetRow("লিঙ্গ", _selectedGender),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interests & Behaviors
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "গ্রাহকের আগ্রহ ও আচরণ (Interests & Behaviors)",
                      style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _showInterestsBehaviorsGuide,
                    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF1E824C), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: "গাইডলাইন দেখুন",
                  ),
                ],
              ),
              const Divider(height: 16),
              
              Text(
                "আগ্রহ (Interests):",
                style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_interests.isEmpty)
                Text(
                  "কোনো আগ্রহ বা ট্যাগ সেট করা নেই।",
                  style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black38),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _interests.map((tag) => Chip(
                    label: Text(tag, style: GoogleFonts.hindSiliguri(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () {
                      setState(() {
                        _interests.remove(tag);
                      });
                    },
                    deleteIconColor: Colors.red[400],
                  )).toList(),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _interestInputCtrl,
                      decoration: InputDecoration(
                        hintText: "নতুন আগ্রহ লিখুন (যেমন: ফ্যাশন)...",
                        hintStyle: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black38),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF1E824C), width: 1),
                        ),
                      ),
                      style: GoogleFonts.hindSiliguri(fontSize: 12),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _interests.add(val.trim());
                            _interestInputCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final val = _interestInputCtrl.text;
                      if (val.trim().isNotEmpty) {
                        setState(() {
                          _interests.add(val.trim());
                          _interestInputCtrl.clear();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E824C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                "আচরণ (Behaviors):",
                style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_behaviors.isEmpty)
                Text(
                  "কোনো আচরণ বা ট্যাগ সেট করা নেই।",
                  style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black38),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _behaviors.map((tag) => Chip(
                    label: Text(tag, style: GoogleFonts.hindSiliguri(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () {
                      setState(() {
                        _behaviors.remove(tag);
                      });
                    },
                    deleteIconColor: Colors.red[400],
                  )).toList(),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _behaviorInputCtrl,
                      decoration: InputDecoration(
                        hintText: "নতুন আচরণ লিখুন (যেমন: অনলাইন শপিং)...",
                        hintStyle: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black38),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF1E824C), width: 1),
                        ),
                      ),
                      style: GoogleFonts.hindSiliguri(fontSize: 12),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _behaviors.add(val.trim());
                            _behaviorInputCtrl.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final val = _behaviorInputCtrl.text;
                      if (val.trim().isNotEmpty) {
                        setState(() {
                          _behaviors.add(val.trim());
                          _behaviorInputCtrl.clear();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E824C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // STEP 7: Optimization Goal Selection
  Widget _buildStepOptimizationGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বিজ্ঞাপন অপ্টিমাইজেশন লক্ষ্য নির্বাচন করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        _buildOptimizationRadioTile(
          goal: "পোস্ট এঙ্গেজমেন্ট",
          title: "পোস্ট এঙ্গেজমেন্ট (সুপারিশকৃত)",
          desc: "লাইক, কমেন্ট ও শেয়ার বৃদ্ধির মাধ্যমে পরিচিতি লাভ করতে সাহায্য করে।",
        ),
        const SizedBox(height: 10),
        _buildOptimizationRadioTile(
          goal: "লিংক ক্লিক",
          title: "লিংক ক্লিক ও ট্রাফিক",
          desc: "মেসেজ লিংক, মার্কেটপ্লেস বা এক্সটার্নাল লিংকের ক্লিক বাড়াতে সহায়ক।",
        ),
        const SizedBox(height: 10),
        _buildOptimizationRadioTile(
          goal: "রিচ",
          title: "রিচ (Reach)",
          desc: "সর্বাধিক সংখক পৃথক মানুষের স্ক্রিনে বিজ্ঞাপন প্রদর্শন করবে।",
        ),
        const SizedBox(height: 10),
        _buildOptimizationRadioTile(
          goal: "মেসেজ",
          title: "মেসেজ অপ্টিমাইজেশন",
          desc: "সরাসরি ইনবক্স বা চ্যাট সেশনে পণ্য সংক্রান্ত মেসেজ পাঠানোর ঝোঁক বৃদ্ধি।",
        ),
      ],
    );
  }

  Widget _buildOptimizationRadioTile({
    required String goal,
    required String title,
    required String desc,
  }) {
    final isSelected = _optimizationGoal == goal;
    return InkWell(
      onTap: () {
        setState(() {
          _optimizationGoal = goal;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, left: 2, right: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E824C) : Colors.black38,
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 8: Order Review Screen
  Widget _buildStepOrderReview() {
    final totalBudget = _selectedBudget * _selectedDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "অর্ডার পর্যালোচনা (Order Review)",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page info row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildAdImageWidget(_adImage, width: 40, height: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dak Official",
                          style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "প্রচারণামূলক বুস্ট",
                          style: GoogleFonts.hindSiliguri(fontSize: 10, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F1F1)),

              // Targeting Overview section
              Text(
                "অডিয়েন্স ও টার্গেটিং:",
                style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              _buildTargetRow("লোকেশন", _getLocationsText()),
              const SizedBox(height: 4),
              _buildTargetRow("বয়সসীমা", "${_toBengaliNumber(_ageRange.start.toInt().toString())} - ${_toBengaliNumber(_ageRange.end.toInt().toString())} বছর"),
              const SizedBox(height: 4),
              _buildTargetRow("লিঙ্গ", _selectedGender),
              
              const Divider(height: 24, color: Color(0xFFF1F1F1)),

              // Budget info section
              Text(
                "বাজেট ও সময়কাল:",
                style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              _buildTargetRow("দৈনিক বাজেট", "৳ ${_toBengaliNumber(_selectedBudget.toString())}"),
              const SizedBox(height: 4),
              _buildTargetRow("মেয়াদ কাল", "${_toBengaliNumber(_selectedDuration.toString())} দিন"),
              const SizedBox(height: 4),
              _buildTargetRow("মোট বাজেট", "৳ ${_toBengaliNumber(totalBudget.toString())}"),
              
              const Divider(height: 24, color: Color(0xFFF1F1F1)),

              // Payment source section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "পেমেন্ট মাধ্যম:",
                    style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  Text(
                    "Dak Wallet (৳ ২,৪৫০ উপলব্ধ)",
                    style: GoogleFonts.hindSiliguri(fontSize: 12.5, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 9: Payment Selection Screen
  Widget _buildStepPaymentSelection() {
    final totalBudget = _selectedBudget * _selectedDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "পেমেন্ট মাধ্যম নির্বাচন করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),

        // Payments options
        _buildPaymentOptionTile(
          key: "wallet",
          label: "Dak Wallet (উপলব্ধ: ৳ ২,৪৫০)",
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          key: "bkash",
          label: "বিকাশ (bKash)",
          icon: Icons.phone_android_rounded,
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          key: "nagad",
          label: "নগদ (Nagad)",
          icon: Icons.mobile_screen_share_rounded,
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          key: "rocket",
          label: "রকেট (Rocket)",
          icon: Icons.phone_iphone_rounded,
        ),
        const SizedBox(height: 8),
        _buildPaymentOptionTile(
          key: "card",
          label: "কার্ড (Visa / Mastercard)",
          icon: Icons.credit_card_rounded,
        ),

        const SizedBox(height: 20),

        // Summary details card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            children: [
              _buildTargetRow("মোট বাজেট", "৳ ${_toBengaliNumber(totalBudget.toString())}"),
              const SizedBox(height: 6),
              _buildTargetRow("সার্ভিস চার্জ", "৳ ০.০০"),
              const Divider(height: 16, color: Color(0xFFF1F1F1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "সর্বমোট:",
                    style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "৳ ${_toBengaliNumber(totalBudget.toString())}",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E824C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, size: 12, color: Colors.black38),
              const SizedBox(width: 4),
              Text(
                "আপনার পেমেন্ট নিরাপদ ও সুরক্ষিত",
                style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black38),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPaymentOptionTile({
    required String key,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == key;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = key;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1E824C) : Colors.black54, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E824C) : Colors.black38,
                  width: isSelected ? 5.0 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 10: Completion Dashboard
  Widget _buildStepSuccessCompleted() {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: _selectedDuration));
    
    // Bengali months lookup helper
    String getBengaliMonth(int month) {
      const List<String> bMonths = [
        "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
        "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"
      ];
      return bMonths[month - 1];
    }

    final startString = "${_toBengaliNumber(today.day.toString())} ${getBengaliMonth(today.month)} ${today.year}, ১০:৩০ AM";
    final endString = "${_toBengaliNumber(endDate.day.toString())} ${getBengaliMonth(endDate.month)} ${endDate.year}, ১০:৩০ AM";

    // Dynamic mock estimations based on budget
    final estReach = (_selectedBudget * _selectedDuration * 12.5).round();
    final estEng = (_selectedBudget * _selectedDuration * 1.8).round();
    final estFollowers = (_selectedBudget * _selectedDuration * 0.45).round();
    final estShares = (_selectedBudget * _selectedDuration * 0.12).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        // Big green success badge
        const CircleAvatar(
          backgroundColor: Color(0xFF1E824C),
          radius: 28,
          child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 14),
        Text(
          "আপনার বুস্ট সফলভাবে শুরু হয়েছে!",
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "আপনার সিলেক্ট করা পোস্টটি এখন অ্যাড হিসেবে টার্গেটেড মানুষের কাছে পৌঁছাতে শুরু করবে।",
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: Colors.black54,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        // Order details box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTargetRow("অর্ডার আইডি", "BOOST-2026-${_toBengaliNumber(today.millisecondsSinceEpoch.toString().substring(8))}"),
              const SizedBox(height: 6),
              _buildTargetRow("স্থিতি", "চলমান"),
              const SizedBox(height: 6),
              _buildTargetRow("শুরুর সময়", startString),
              const SizedBox(height: 6),
              _buildTargetRow("শেষ সময়", endString),
              
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E824C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    "বিস্তারিত দেখুন",
                    style: GoogleFonts.hindSiliguri(color: const Color(0xFF1E824C), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Estimated Results Preview (রেজাল্ট প্রাক্কলন)
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "রেজাল্ট প্রাক্কলন ও ট্র্যাকিং",
            style: GoogleFonts.hindSiliguri(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildEstimationCard("রিচ (Reach)", _toBengaliNumber(estReach.toString()), "+১২.৫%"),
                  const SizedBox(width: 10),
                  _buildEstimationCard("এঙ্গেজমেন্ট", _toBengaliNumber(estEng.toString()), "+৮.২%"),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildEstimationCard("নতুন অনুসারী", _toBengaliNumber(estFollowers.toString()), "+১৫.৩%"),
                  const SizedBox(width: 10),
                  _buildEstimationCard("পোস্ট শেয়ার", _toBengaliNumber(estShares.toString()), "+১০.১%"),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Back to dashboard
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                NoTransitionPageRoute(child: const DashboardScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: Text(
              "ড্যাশবোর্ডে যান",
              style: GoogleFonts.hindSiliguri(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEstimationCard(String title, String val, String percent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFF1E824C)),
                const SizedBox(width: 2),
                Text(
                  percent,
                  style: GoogleFonts.outfit(fontSize: 9.5, color: const Color(0xFF1E824C), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Navigation controller wizard footer
  Widget _buildWizardFooter() {
    String buttonText = "পরবর্তী";
    if (_currentStep == 2) buttonText = "নিশ্চিত করুন";
    if (_currentStep == 8) buttonText = "এগিয়ে যান";
    if (_currentStep == 9) buttonText = "এখনই পেমেন্ট করুন";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              if (_currentStep == 2) {
                // Confirm locations and return to Audience Settings (Step 1)
                _currentStep = 1;
              } else if (_currentStep == 1) {
                // Done with audience settings, go to budget and duration (Step 3)
                _currentStep = 3;
              } else {
                _currentStep++;
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E824C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: Text(
            buttonText,
            style: GoogleFonts.hindSiliguri(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
