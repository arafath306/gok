import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class CampaignWizardScreen extends StatefulWidget {
  const CampaignWizardScreen({super.key});

  @override
  State<CampaignWizardScreen> createState() => _CampaignWizardScreenState();
}

class _CampaignWizardScreenState extends State<CampaignWizardScreen> {
  // Current active step (0 to 7)
  int _currentStep = 0;

  // Bengali translation of digits
  String _toBengaliNumber(String englishNumber) {
    const Map<String, String> translation = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    return englishNumber.split('').map((char) => translation[char] ?? char).join();
  }

  Widget _buildAdImageWidget(String path, {required BoxFit fit, required Alignment alignment, required double scale}) {
    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        alignment: alignment,
        scale: scale,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    } else {
      return Image.file(
        File(path),
        fit: fit,
        alignment: alignment,
        scale: scale,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.black38, size: 40),
      ),
    );
  }

  // STEP 1 STATE: Campaign Objective
  String _selectedObjective = "engagement"; // awareness, engagement, follower_growth, website_visits, app_promotion, product_promotion
  final List<Map<String, dynamic>> _objectives = [
    {
      "id": "awareness",
      "title": "অ্যাওয়ারনেস (Awareness)",
      "desc": "আপনার ব্র্যান্ড বা বিজ্ঞাপনটি অধিক মানুষের কাছে পৌঁছে দিন",
      "icon": Icons.campaign_rounded,
      "color": Color(0xFF2980B9),
    },
    {
      "id": "engagement",
      "title": "এঙ্গেজমেন্ট (Engagement)",
      "desc": "পোস্টে লাইক, কমেন্ট, শেয়ার ও মেসেজ বৃদ্ধি করুন",
      "icon": Icons.favorite_rounded,
      "color": Color(0xFFE74C3C),
    },
    {
      "id": "follower_growth",
      "title": "ফলোয়ার বৃদ্ধি (Follower Growth)",
      "desc": "আপনার প্রোফাইল বা পেজের ফলোয়ার সংখ্যা বাড়ান",
      "icon": Icons.people_alt_rounded,
      "color": Color(0xFF1E824C),
    },
    {
      "id": "website_visits",
      "title": "ওয়েবসাইট ভিজিট (Website Visits)",
      "desc": "ওয়েবসাইটে বেশি ভিজিটর ও ট্রাফিক নিয়ে আসুন",
      "icon": Icons.language_rounded,
      "color": Color(0xFF8E44AD),
    },
    {
      "id": "app_promotion",
      "title": "অ্যাপ প্রমোশন (App Promotion)",
      "desc": "মোবাইল অ্যাপ ইনস্টল ও ব্যবহারকারী বাড়ান",
      "icon": Icons.phone_android_rounded,
      "color": Color(0xFFD35400),
    },
    {
      "id": "product_promotion",
      "title": "প্রোডাক্ট প্রমোশন (Product Promotion)",
      "desc": "আপনার ক্যাটালগের পণ্যের বিক্রি ও সেলস বৃদ্ধি করুন",
      "icon": Icons.shopping_bag_rounded,
      "color": Color(0xFF2C3E50),
    },
  ];

  // STEP 2 STATE: Audience Selection
  String _selectedCountry = "বাংলাদেশ";
  String _selectedDivision = "ঢাকা";
  String _selectedDistrict = "ঢাকা";
  RangeValues _ageRange = const RangeValues(18, 55);
  String _selectedGender = "All"; // All, Male, Female
  
  // Interests (Tag selection)
  final Set<String> _selectedInterests = {"অনলাইন শপিং", "প্রযুক্তি", "ভ্রমণ"};
  final List<String> _commonInterests = [
    "অনলাইন শপিং", "প্রযুক্তি", "ভ্রমণ", "খাবার ও রেস্তোরাঁ", 
    "ফ্যাশন", "শিক্ষা", "খেলাধুলা", "বিনোদন", "ব্যবসা", "স্বাস্থ্য"
  ];
  final TextEditingController _customInterestCtrl = TextEditingController();

  // Device
  String _selectedDevice = "All Devices"; // Android, iPhone, All Devices

  // Dynamic dropdown list mapping
  final List<String> _countries = ["বাংলাদেশ", "ভারত", "অন্যান্য"];
  final List<String> _divisions = ["ঢাকা", "চট্টগ্রাম", "সিলেট", "খুলনা", "রাজশাহী", "বরিশাল", "রংপুর", "ময়মনসিংহ"];
  final Map<String, List<String>> _divisionDistricts = {
    "ঢাকা": ["ঢাকা", "গাজীপুর", "নারায়ণগঞ্জ", "টাঙ্গাইল", "ফরিদপুর"],
    "চট্টগ্রাম": ["চট্টগ্রাম", "কক্সবাজার", "কুমিল্লা", "ফেনী", "নোয়াখালী"],
    "সিলেট": ["সিলেট", "মৌলভীবাজার", "হবিগঞ্জ", "সুনামগঞ্জ"],
    "খুলনা": ["খুলনা", "যশোর", "বাগেরহাট", "সাতক্ষীরা", "কুষ্টিয়া"],
    "রাজশাহী": ["রাজশাহী", "বগুড়া", "পাবনা", "নাটোর", "সিরাজগঞ্জ"],
    "বরিশাল": ["বরিশাল", "পটুয়াখালী", "ভোলা", "পিরোজপুর"],
    "রংপুর": ["রংপুর", "দিনাজপুর", "গাইবান্ধা", "কুড়িগ্রাম"],
    "ময়মনসিংহ": ["ময়মনসিংহ", "জামালপুর", "নেত্রকোনা", "শেরপুর"]
  };

  // STEP 3 STATE: Ad Creative Format
  String _selectedCreativeType = "image"; // image, video, carousel, existing

  // STEP 4 STATE: Upload Creative & Crop/Trim
  XFile? _selectedMediaFile;
  final ImagePicker _picker = ImagePicker();
  
  // Image Crop Simulator State
  double _cropX = 0.0;
  double _cropY = 0.0;
  double _cropZoom = 1.0;

  // Video Trim Simulator State
  double _trimStart = 0.0;
  double _trimEnd = 15.0; // max 15 seconds

  // STEP 5 STATE: Ad Copy Editor
  final TextEditingController _headlineCtrl = TextEditingController(text: "বিশেষ মূল্যছাড় অফার!");
  final TextEditingController _descriptionCtrl = TextEditingController(text: "আমাদের নতুন কালেকশন থেকে যেকোনো প্রোডাক্ট কিনুন আকর্ষণীয় অফারে। সীমিত সময়ের জন্য ডেলিভারি চার্জ একদম ফ্রি!");
  String _selectedCTA = "আরও জানুন"; // আরও জানুন, ওয়েবসাইট ভিজিট করুন, ডাউনলোড করুন, ফলো করুন, মেসেজ পাঠান
  final List<String> _ctaOptions = ["আরও জানুন", "ওয়েবসাইট ভিজিট করুন", "ডাউনলোড করুন", "ফলো করুন", "মেসেজ পাঠান"];

  // STEP 6 STATE: Placements Selection
  final Map<String, bool> _placements = {
    "Home Feed": true,
    "Reels Feed": true,
    "Story Feed": true,
    "Search Feed": false,
    "Group Feed": false,
  };
  final Map<String, String> _placementsBengali = {
    "Home Feed": "🏠 হোম ফিড",
    "Reels Feed": "🎬 রিলস ফিড",
    "Story Feed": "📖 স্টোরি ফিড",
    "Search Feed": "🔍 সার্চ ফিড",
    "Group Feed": "👥 গ্রুপ ফিড",
  };

  // STEP 7 STATE: Budget & Duration
  String _budgetType = "daily"; // daily, lifetime
  double _budgetAmount = 500; // default 500৳
  int _durationDays = 7; // default 7 days

  @override
  void dispose() {
    _customInterestCtrl.dispose();
    _headlineCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // Handle objective text
  String _getObjectiveTitleBengali(String id) {
    switch (id) {
      case "awareness": return "অ্যাওয়ারনেস";
      case "engagement": return "এঙ্গেজমেন্ট";
      case "follower_growth": return "ফলোয়ার বৃদ্ধি";
      case "website_visits": return "ওয়েবসাইট ভিজিট";
      case "app_promotion": return "অ্যাপ প্রমোশন";
      case "product_promotion": return "প্রোডাক্ট প্রমোশন";
      default: return "";
    }
  }

  // Handle budget estimations based on current parameters
  int _getEstimatedReachMin() {
    final scale = _budgetType == "daily" ? _durationDays : 1;
    final totalBudget = _budgetAmount * scale;
    return (totalBudget * 14.5).round();
  }

  int _getEstimatedReachMax() {
    final scale = _budgetType == "daily" ? _durationDays : 1;
    final totalBudget = _budgetAmount * scale;
    return (totalBudget * 24.0).round();
  }

  int _getEstimatedConversionsMin() {
    final scale = _budgetType == "daily" ? _durationDays : 1;
    final totalBudget = _budgetAmount * scale;
    return (totalBudget * 0.12).round();
  }

  int _getEstimatedConversionsMax() {
    final scale = _budgetType == "daily" ? _durationDays : 1;
    final totalBudget = _budgetAmount * scale;
    return (totalBudget * 0.28).round();
  }

  @override
  Widget build(BuildContext context) {
    // Current milestone indicator step mapping (Objective, Audience, Creative, Budget, Review)
    // Steps:
    // 0: Campaign Objective (Objective)
    // 1: Audience Selection (Audience)
    // 2: Ad Creative Selection (Creative)
    // 3: Upload Creative (Creative)
    // 4: Ad Copy Editor (Creative)
    // 5: Placement Selection (Creative)
    // 6: Budget & Duration (Budget)
    // 7: Review & Publish (Review)

    int activeMilestone = 0;
    if (_currentStep == 1) activeMilestone = 1;
    if (_currentStep >= 2 && _currentStep <= 5) activeMilestone = 2;
    if (_currentStep == 6) activeMilestone = 3;
    if (_currentStep == 7) activeMilestone = 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => _confirmExitWizard(),
        ),
        title: Text(
          "নতুন ক্যাম্পেইন উইজার্ড",
          style: GoogleFonts.hindSiliguri(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Progress Indicator
          _buildMilestoneProgressBar(activeMilestone),
          
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              physics: const BouncingScrollPhysics(),
              child: _buildStepView(),
            ),
          ),
          
          // Footer Navigation
          _buildWizardFooter(),
        ],
      ),
    );
  }

  // Milestone Progress bar indicator
  Widget _buildMilestoneProgressBar(int activeMilestone) {
    final List<String> milestones = ["উদ্দেশ্য", "অডিয়েন্স", "ক্রিয়েটিভ", "বাজেট", "পর্যালোচনা"];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(milestones.length * 2 - 1, (index) {
          if (index % 2 == 1) {
            // Line connector
            final lineIdx = index ~/ 2;
            final isLinePassed = lineIdx < activeMilestone;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: isLinePassed ? const Color(0xFF1E824C) : Colors.grey[200],
              ),
            );
          } else {
            // Milestone item
            final milestoneIdx = index ~/ 2;
            final isActive = milestoneIdx == activeMilestone;
            final isPassed = milestoneIdx < activeMilestone;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPassed
                        ? const Color(0xFF1E824C)
                        : isActive
                            ? const Color(0xFF1E824C)
                            : Colors.white,
                    border: Border.all(
                      color: isPassed || isActive
                          ? const Color(0xFF1E824C)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isPassed
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            _toBengaliNumber((milestoneIdx + 1).toString()),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.black54,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestones[milestoneIdx],
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10,
                    fontWeight: isActive || isPassed ? FontWeight.bold : FontWeight.w500,
                    color: isActive || isPassed
                        ? const Color(0xFF1E824C)
                        : Colors.black45,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  // Render correct step view widget
  Widget _buildStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Objective();
      case 1:
        return _buildStep2Audience();
      case 2:
        return _buildStep3CreativeFormat();
      case 3:
        return _buildStep4UploadAndCrop();
      case 4:
        return _buildStep5CopyEditor();
      case 5:
        return _buildStep6Placement();
      case 6:
        return _buildStep7BudgetAndDuration();
      case 7:
        return _buildStep8ReviewAndPublish();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Campaign Objective
  Widget _buildStep1Objective() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ক্যাম্পেইনের লক্ষ্য নির্বাচন করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "আপনার বিজ্ঞাপনের মূল উদ্দেশ্য কী? তার ভিত্তিতে বিজ্ঞাপন অপ্টিমাইজ হবে।",
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 10,
            childAspectRatio: 4.8,
          ),
          itemCount: _objectives.length,
          itemBuilder: (context, index) {
            final obj = _objectives[index];
            final isSelected = _selectedObjective == obj["id"];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedObjective = obj["id"];
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
                    width: isSelected ? 1.8 : 0.6,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E824C).withAlpha(0x1F),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSelected ? const Color(0xFF1E824C).withAlpha(0x2B) : obj["color"].withAlpha(0x1A),
                      child: Icon(
                        obj["icon"] as IconData,
                        color: isSelected ? const Color(0xFF1E824C) : obj["color"] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            obj["title"] as String,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E824C) : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            obj["desc"] as String,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 10.5,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF1E824C), size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 2: Audience Selection
  Widget _buildStep2Audience() {
    final divisionsList = _divisions;
    final districtsList = _divisionDistricts[_selectedDivision] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "টার্গেট অডিয়েন্স ও ডেমোগ্রাফিক",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        // Geographic Location Selection Card
        _buildSectionCard(
          title: "ভৌগোলিক অবস্থান (Location Target)",
          icon: Icons.my_location_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "দেশ (Country)",
                style: GoogleFonts.hindSiliguri(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                isDense: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                ),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.hindSiliguri(fontSize: 12.5)))).toList(),
                onChanged: (v) => setState(() => _selectedCountry = v!),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "বিভাগ (Division)",
                          style: GoogleFonts.hindSiliguri(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDivision,
                          isDense: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                          ),
                          items: divisionsList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.hindSiliguri(fontSize: 12.5)))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedDivision = v!;
                            _selectedDistrict = _divisionDistricts[v]!.first;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "জেলা (District)",
                          style: GoogleFonts.hindSiliguri(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDistrict,
                          isDense: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                          ),
                          items: districtsList.map((dt) => DropdownMenuItem(value: dt, child: Text(dt, style: GoogleFonts.hindSiliguri(fontSize: 12.5)))).toList(),
                          onChanged: (v) => setState(() => _selectedDistrict = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Age Selection Card
        _buildSectionCard(
          title: "বয়সসীমা (Age Range)",
          icon: Icons.calendar_today_rounded,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "টার্গেটেড বয়স:",
                    style: GoogleFonts.hindSiliguri(fontSize: 12.5, color: Colors.black54),
                  ),
                  Text(
                    "${_toBengaliNumber(_ageRange.start.round().toString())} - ${_toBengaliNumber(_ageRange.end.round().toString())} বছর",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14.5,
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
                labels: RangeLabels(
                  _toBengaliNumber(_ageRange.start.round().toString()),
                  _toBengaliNumber(_ageRange.end.round().toString()),
                ),
                onChanged: (values) => setState(() => _ageRange = values),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Gender Selection Card
        _buildSectionCard(
          title: "লিঙ্গ (Gender Selection)",
          icon: Icons.people_outline_rounded,
          child: Row(
            children: [
              Expanded(
                child: _buildGenderChip("All", "সবাই (All)"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGenderChip("Male", "পুরুষ (Male)"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGenderChip("Female", "নারী (Female)"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Interest Tag Selection Card
        _buildSectionCard(
          title: "আগ্রহ ও আচরণ (Interests & Behavior)",
          icon: Icons.stars_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "বিজ্ঞাপন সম্পর্কিত আগ্রহ বা ট্যাগ নির্বাচন করুন (যা টার্গেটিং সঠিক করবে)",
                style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              
              // Selected interest tags wrap
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedInterests.map((interest) {
                  return Chip(
                    label: Text(interest, style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.white)),
                    backgroundColor: const Color(0xFF1E824C),
                    deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _selectedInterests.remove(interest);
                      });
                    },
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  );
                }).toList(),
              ),
              
              if (_selectedInterests.isNotEmpty) const SizedBox(height: 8),
              const Divider(height: 16, color: Color(0xFFF1F1F1)),

              // Common Interest Chips
              Text(
                "জনপ্রিয় ট্যাগসমূহ:",
                style: GoogleFonts.hindSiliguri(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _commonInterests.map((tag) {
                  final isAdded = _selectedInterests.contains(tag);
                  return ActionChip(
                    label: Text(tag, style: GoogleFonts.hindSiliguri(fontSize: 11, color: isAdded ? Colors.white : Colors.black87)),
                    backgroundColor: isAdded ? const Color(0xFF1E824C) : Colors.grey[100],
                    onPressed: () {
                      setState(() {
                        if (isAdded) {
                          _selectedInterests.remove(tag);
                        } else {
                          _selectedInterests.add(tag);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide.none),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // Custom interest input field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customInterestCtrl,
                      decoration: InputDecoration(
                        hintText: "কাস্টম আগ্রহ বা ট্যাগ লিখুন...",
                        hintStyle: GoogleFonts.hindSiliguri(fontSize: 11.5),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      style: GoogleFonts.hindSiliguri(fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _customInterestCtrl.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _selectedInterests.add(text);
                          _customInterestCtrl.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text("যোগ করুন", style: GoogleFonts.hindSiliguri(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Device targeting card
        _buildSectionCard(
          title: "ডিভাইস টার্গেটিং (Device Target)",
          icon: Icons.devices_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceRadioTile("All Devices", "সব ধরনের ডিভাইস (All Devices)", Icons.phone_android_rounded),
              _buildDeviceRadioTile("Android", "শুধুমাত্র অ্যান্ড্রয়েড ইউজার (Android)", Icons.android_rounded),
              _buildDeviceRadioTile("iPhone", "শুধুমাত্র আইফোন ইউজার (iPhone / iOS)", Icons.phone_iphone_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String val, String text) {
    final isSelected = _selectedGender == val;
    return ChoiceChip(
      label: Center(
        child: Text(
          text,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1E824C),
      backgroundColor: Colors.grey[100],
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedGender = val;
          });
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
      showCheckmark: false,
    );
  }

  Widget _buildDeviceRadioTile(String val, String text, IconData icon) {
    final isSelected = _selectedDevice == val;
    return InkWell(
      onTap: () => setState(() => _selectedDevice = val),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1E824C) : Colors.black45, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1E824C) : Colors.black87,
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E824C) : Colors.black38,
                  width: isSelected ? 4.5 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Ad Creative Format
  Widget _buildStep3CreativeFormat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বিজ্ঞাপনের মাধ্যম নির্বাচন করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "আপনার ক্রিয়েটিভ ম্যাটেরিয়ালস এর ফরম্যাট কেমন হবে?",
          style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        
        _buildCreativeFormatTile("image", "ছবি বিজ্ঞাপন (Image Ad)", "একক ছবি দিয়ে বিজ্ঞাপন তৈরি করুন", Icons.image_rounded),
        _buildCreativeFormatTile("video", "ভিডিও বিজ্ঞাপন (Video Ad)", "যেকোনো ভিডিও প্রমোট করে বেশি মানুষের মনোযোগ কাড়ুন", Icons.video_collection_rounded),
        _buildCreativeFormatTile("carousel", "ক্যারোসেল বিজ্ঞাপন (Carousel Ad)", "একাধিক স্লাইড ছবি দিয়ে ক্যাটালগ আকারে দেখান", Icons.view_carousel_rounded),
        _buildCreativeFormatTile("existing", "বিদ্যমান পোস্ট নির্বাচন (Existing Post)", "আপনার পেজের পূর্ববর্তী কোনো পোস্ট ব্যবহার করুন", Icons.art_track_rounded),
      ],
    );
  }

  Widget _buildCreativeFormatTile(String val, String title, String desc, IconData icon) {
    final isSelected = _selectedCreativeType == val;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
          width: isSelected ? 1.8 : 0.6,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF1E824C).withAlpha(0x1F),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCreativeType = val),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected ? const Color(0xFF1E824C).withAlpha(0x2B) : Colors.grey[100],
                  child: Icon(icon, color: isSelected ? const Color(0xFF1E824C) : Colors.black54, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF1E824C) : Colors.black87,
                        ),
                      ),
                      Text(
                        desc,
                        style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF1E824C), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // STEP 4: Upload Creative + Simulated Image Crop / Video Trim controls
  Widget _buildStep4UploadAndCrop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "মিডিয়া ও ক্রিয়েটিভ আপলোড করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        // Upload Zone Container
        InkWell(
          onTap: () => _pickMediaFile(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E824C),
                style: BorderStyle.solid,
                width: 1.2,
              ),
            ),
            child: _selectedMediaFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: Color(0xFF1E824C), size: 44),
                      const SizedBox(height: 10),
                      Text(
                        _selectedCreativeType == "video"
                            ? "ভিডিও আপলোড করতে এখানে ক্লিক করুন"
                            : "ছবি আপলোড করতে এখানে ক্লিক করুন",
                        style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCreativeType == "video"
                            ? "রিল বা ফিড সাইজ ভিডিও সাপোর্ট করে (সর্বোচ্চ ৫০MB)"
                            : "JPG, PNG ফরম্যাট সাপোর্ট করে (১৬:৯ বা ১:১ রেশিও)",
                        style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black38),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedCreativeType == "video"
                              ? Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 50),
                                  ),
                                )
                              : _buildAdImageWidget(
                                  _selectedMediaFile!.path,
                                  fit: BoxFit.cover,
                                  alignment: Alignment(_cropX, _cropY),
                                  scale: _cropZoom,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 14),
                            onPressed: () {
                              setState(() {
                                _selectedMediaFile = null;
                              });
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1E824C), size: 12),
                              const SizedBox(width: 4),
                              Text("সফলভাবে লোড হয়েছে", style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Simulated Crop/Trim Editor Panel (Only if media is selected)
        if (_selectedMediaFile != null) ...[
          _selectedCreativeType == "video"
              ? _buildVideoTrimPanel()
              : _buildImageCropPanel(),
        ] else ...[
          // Mock preview box instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "বিজ্ঞাপনটিকে লাইভ করতে ছবি বা ভিডিও ফাইল আপলোড করা আবশ্যক।",
                    style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Image Cropper Control Panel
  Widget _buildImageCropPanel() {
    return _buildSectionCard(
      title: "ইমেজ ক্রপ ও পজিশন সমন্বয় (Image Crop Simulation)",
      icon: Icons.crop_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "নিচের স্লাইডারগুলো ব্যবহার করে ইমেজ জুম ও ক্রপ পজিশন অ্যাডজাস্ট করুন:",
            style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          
          // Zoom slider
          Row(
            children: [
              const Icon(Icons.zoom_in_rounded, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _cropZoom,
                  min: 1.0,
                  max: 3.0,
                  activeColor: const Color(0xFF1E824C),
                  onChanged: (v) => setState(() => _cropZoom = v),
                ),
              ),
              Text(
                "${_toBengaliNumber(_cropZoom.toStringAsFixed(1))}x জুম",
                style: GoogleFonts.hindSiliguri(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Horizontal alignment slider (X-Axis Crop)
          Row(
            children: [
              const Icon(Icons.unfold_more_rounded, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _cropX,
                  min: -1.0,
                  max: 1.0,
                  activeColor: const Color(0xFF1E824C),
                  onChanged: (v) => setState(() => _cropX = v),
                ),
              ),
              Text(
                "X-অফসেট",
                style: GoogleFonts.hindSiliguri(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Video Trimmer Control Panel
  Widget _buildVideoTrimPanel() {
    return _buildSectionCard(
      title: "ভিডিও ট্রিম ও সময়কাল (Video Trim Simulation)",
      icon: Icons.cut_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "আপনার আপলোড করা বড় ভিডিও থেকে সর্বোচ্চ ১৫ সেকেন্ড ট্রিম করে নিন:",
            style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          
          RangeSlider(
            values: RangeValues(_trimStart, _trimEnd),
            min: 0.0,
            max: 30.0,
            divisions: 30,
            activeColor: const Color(0xFF1E824C),
            inactiveColor: Colors.grey[200],
            labels: RangeLabels(
              "${_trimStart.round()} সে.",
              "${_trimEnd.round()} সে.",
            ),
            onChanged: (values) {
              // Ensure we enforce max 15 seconds duration
              if (values.end - values.start <= 15.0) {
                setState(() {
                  _trimStart = values.start;
                  _trimEnd = values.end;
                });
              }
            },
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "শুরুর সময়: ${_toBengaliNumber(_trimStart.round().toString())} সেকেন্ড",
                style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black54),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.withAlpha(0x24), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  "মোট সময়কাল: ${_toBengaliNumber((_trimEnd - _trimStart).round().toString())} সেকেন্ড (সর্বোচ্চ ১৫ সে.)",
                  style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.orange[800], fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                "শেষের সময়: ${_toBengaliNumber(_trimEnd.round().toString())} সেকেন্ড",
                style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Trigger file picker
  Future<void> _pickMediaFile() async {
    final type = _selectedCreativeType == "video" ? ImageSource.gallery : ImageSource.gallery;
    try {
      XFile? file;
      if (_selectedCreativeType == "video") {
        file = await _picker.pickVideo(source: type);
      } else {
        file = await _picker.pickImage(source: type);
      }
      if (file != null) {
        setState(() {
          _selectedMediaFile = file;
          // reset crop/trim offset defaults
          _cropX = 0.0;
          _cropY = 0.0;
          _cropZoom = 1.0;
          _trimStart = 0.0;
          _trimEnd = 15.0;
        });
      }
    } catch (e) {
      debugPrint("File picking cancelled or error: $e");
    }
  }

  // STEP 5: Ad Copy Editor
  Widget _buildStep5CopyEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বিজ্ঞাপন কপি ও টেক্সট এডিটর",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        // Headline
        Text(
          "বিজ্ঞাপনের প্রধান শিরোনাম (Headline):",
          style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _headlineCtrl,
          decoration: InputDecoration(
            hintText: "যেমন: বিশেষ মূল্যছাড় অফার!",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5)),
          ),
          style: GoogleFonts.hindSiliguri(fontSize: 13),
          onChanged: (v) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          "বিস্তারিত বিবরণ (Description):",
          style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "বিজ্ঞাপনের বিবরণ এখানে লিখুন যা ছবির ওপরে দেখাবে...",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5)),
          ),
          style: GoogleFonts.hindSiliguri(fontSize: 13, height: 1.4),
          onChanged: (v) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // CTA Button selection card
        _buildSectionCard(
          title: "কল টু অ্যাকশন বোতাম (Call to Action - CTA)",
          icon: Icons.touch_app_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "দর্শকরা কোন বোতামে ক্লিক করবে তা নির্বাচন করুন:",
                style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedCTA,
                isDense: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5)),
                ),
                items: _ctaOptions.map((cta) => DropdownMenuItem(value: cta, child: Text(cta, style: GoogleFonts.hindSiliguri(fontSize: 12.5)))).toList(),
                onChanged: (v) => setState(() => _selectedCTA = v!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 6: Placement Selection
  Widget _buildStep6Placement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বিজ্ঞাপন প্লেসমেন্ট নির্বাচন করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "বিজ্ঞাপনটি ডকের কোন কোন ফিড বা জায়গায় প্রদর্শিত হবে তা সিলেক্ট করুন।",
          style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),

        ..._placements.keys.map((key) {
          final isChecked = _placements[key] ?? false;
          final isRecommended = key == "Home Feed" || key == "Story Feed";
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isChecked ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
                width: isChecked ? 1.5 : 0.5,
              ),
            ),
            child: CheckboxListTile(
              value: isChecked,
              activeColor: const Color(0xFF1E824C),
              title: Row(
                children: [
                  Text(
                    _placementsBengali[key] ?? key,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                      color: isChecked ? const Color(0xFF1E824C) : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E824C).withAlpha(0x1F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "প্রস্তাবিত (Recommended)",
                        style: GoogleFonts.hindSiliguri(fontSize: 9, color: const Color(0xFF1E824C), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              onChanged: (val) {
                setState(() {
                  _placements[key] = val!;
                });
              },
              controlAffinity: ListTileControlAffinity.trailing,
            ),
          );
        }),
      ],
    );
  }

  // STEP 7: Budget & Duration Selector
  Widget _buildStep7BudgetAndDuration() {
    final scale = _budgetType == "daily" ? _durationDays : 1;
    final totalBudget = _budgetAmount * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বিজ্ঞাপন বাজেট ও সময়কাল নির্ধারণ",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),

        // Daily / Lifetime Budget Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _budgetType = "daily"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _budgetType == "daily" ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: _budgetType == "daily"
                          ? [BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "দৈনিক বাজেট (Daily Budget)",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11.5,
                          fontWeight: _budgetType == "daily" ? FontWeight.bold : FontWeight.normal,
                          color: _budgetType == "daily" ? const Color(0xFF1E824C) : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _budgetType = "lifetime"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _budgetType == "lifetime" ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: _budgetType == "lifetime"
                          ? [BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        "লাইফটাইম বাজেট (Lifetime)",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11.5,
                          fontWeight: _budgetType == "lifetime" ? FontWeight.bold : FontWeight.normal,
                          color: _budgetType == "lifetime" ? const Color(0xFF1E824C) : Colors.black54,
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

        // Budget amount slider
        _buildSectionCard(
          title: _budgetType == "daily" ? "দৈনিক বাজেটের পরিমাণ (৳)" : "মোট লাইফটাইম বাজেটের পরিমাণ (৳)",
          icon: Icons.payments_rounded,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("বাজেট সীমা:", style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54)),
                  Text(
                    "৳ ${_toBengaliNumber(_budgetAmount.toInt().toString())}",
                    style: GoogleFonts.outfit(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E824C),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _budgetAmount.clamp(100.0, 5000.0),
                min: 100,
                max: 5000,
                divisions: 49,
                activeColor: const Color(0xFF1E824C),
                inactiveColor: Colors.grey[200],
                onChanged: (v) => setState(() => _budgetAmount = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("১০০ ৳", style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: Colors.black38)),
                  Text("৫,০০০ ৳", style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: Colors.black38)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Duration Slider
        _buildSectionCard(
          title: "বিজ্ঞাপনের সময়কাল ও মেয়াদ (Duration Days)",
          icon: Icons.timelapse_rounded,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("বিজ্ঞাপন চলমান থাকবে:", style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54)),
                  Text(
                    "${_toBengaliNumber(_durationDays.toString())} দিন",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E824C),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _durationDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: const Color(0xFF1E824C),
                inactiveColor: Colors.grey[200],
                onChanged: (v) => setState(() => _durationDays = v.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("১ দিন", style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: Colors.black38)),
                  Text("৩০ দিন", style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: Colors.black38)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Estimated Reach/Conversion Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(0x05), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("মোট বাজেট প্রাক্কলন (Estimated Budget):", style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black87)),
                  Text(
                    "৳ ${_toBengaliNumber(totalBudget.toInt().toString())}",
                    style: GoogleFonts.outfit(fontSize: 16.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _budgetType == "daily"
                    ? "${_toBengaliNumber(_durationDays.toString())} দিন × ${_toBengaliNumber(_budgetAmount.toInt().toString())} ৳ প্রতিদিন"
                    : "সর্বমোট লাইফটাইম বাজেট: ৳${_toBengaliNumber(totalBudget.toInt().toString())} (${_toBengaliNumber(_durationDays.toString())} দিনব্যাপী)",
                style: GoogleFonts.hindSiliguri(fontSize: 10.5, color: Colors.black45),
              ),
              const Divider(height: 18, color: Color(0xFFF1F1F1)),
              
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text("আনুমানিক মোট রিচ (Reach): ", style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54)),
                  const Spacer(),
                  Text(
                    "${_toBengaliNumber(_getEstimatedReachMin().toString())} - ${_toBengaliNumber(_getEstimatedReachMax().toString())} জন",
                    style: GoogleFonts.hindSiliguri(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text("আনুমানিক কনভার্সন (Sales / Actions): ", style: GoogleFonts.hindSiliguri(fontSize: 11.5, color: Colors.black54)),
                  const Spacer(),
                  Text(
                    "${_toBengaliNumber(_getEstimatedConversionsMin().toString())} - ${_toBengaliNumber(_getEstimatedConversionsMax().toString())} টি অ্যাকশন",
                    style: GoogleFonts.hindSiliguri(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 8: Review & Publish with live interactive Home Feed ad preview
  Widget _buildStep8ReviewAndPublish() {
    final scale = _budgetType == "daily" ? _durationDays : 1;
    final totalBudget = _budgetAmount * scale;
    final formattedInterests = _selectedInterests.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ক্যাম্পেইন পর্যালোচনা ও পাবলিশ",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "পাবলিশ করার পূর্বে সকল সেটিংস ঠিক রয়েছে কি না মিলিয়ে নিন।",
          style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 14),

        // Split Summary Card
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
              _buildSummaryRow("ক্যাম্পেইন উদ্দেশ্য:", _getObjectiveTitleBengali(_selectedObjective)),
              _buildSummaryRow("টার্গেটেড লোকেশন:", "$_selectedDivision, $_selectedDistrict, $_selectedCountry"),
              _buildSummaryRow("বয়স ও লিঙ্গ:", "${_toBengaliNumber(_ageRange.start.round().toString())}-${_toBengaliNumber(_ageRange.end.round().toString())} বছর, ${_selectedGender == 'All' ? 'সবাই' : _selectedGender == 'Male' ? 'পুরুষ' : 'নারী'}"),
              _buildSummaryRow("ডিভাইস টার্গেট:", _selectedDevice == "All Devices" ? "সকল ডিভাইস" : _selectedDevice),
              if (_selectedInterests.isNotEmpty)
                _buildSummaryRow("আগ্রহ/ট্যাগসমূহ:", formattedInterests),
              _buildSummaryRow("টোটাল বাজেট:", "৳ ${_toBengaliNumber(totalBudget.toInt().toString())} (${_toBengaliNumber(_durationDays.toString())} দিনের জন্য)"),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Live Feed Preview Panel
        Text(
          "লাইভ ফিড বিজ্ঞাপন প্রাকদর্শন (Ad Feed Preview):",
          style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),

        // Visual Feed Item Simulation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(0x03), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header post metadata
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const AssetImage('assets/logo_d_icon_v2.jpg'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Dak Official",
                              style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 13),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "স্পন্সরড (Sponsored)",
                              style: GoogleFonts.hindSiliguri(fontSize: 9.5, color: Colors.black45, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.public_rounded, size: 10, color: Colors.black38),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Colors.black54),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description Text (Copy Editor Description)
              Text(
                _descriptionCtrl.text,
                style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 8),

              // Media display box
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedMediaFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _selectedCreativeType == "video"
                            ? Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 48),
                                ),
                              )
                            : _buildAdImageWidget(
                                _selectedMediaFile!.path,
                                fit: BoxFit.cover,
                                alignment: Alignment(_cropX, _cropY),
                                scale: _cropZoom,
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_outlined, color: Colors.black38, size: 38),
                          const SizedBox(height: 4),
                          Text("মিডিয়া আপলোড করা হয়নি", style: GoogleFonts.hindSiliguri(fontSize: 11, color: Colors.black38)),
                        ],
                      ),
              ),
              const SizedBox(height: 10),

              // Headline & CTA button container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DAK.COM.BD",
                            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black45),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _headlineCtrl.text,
                            style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey[300]!, width: 0.8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        _selectedCTA,
                        style: GoogleFonts.hindSiliguri(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Summary Row Helper widget
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Section card wrap helper widget
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
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
              Icon(icon, color: const Color(0xFF1E824C), size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.hindSiliguri(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Confirm dialog before exiting
  void _confirmExitWizard() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "উইজার্ড বন্ধ করুন?",
            style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, fontSize: 15.5),
          ),
          content: Text(
            "আপনি কি নিশ্চিত যে উইজার্ডটি বন্ধ করতে চান? আপনার অসম্পূর্ণ ক্যাম্পেইন তথ্য হারিয়ে যাবে।",
            style: GoogleFonts.hindSiliguri(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("না, ব্যাক যান", style: GoogleFonts.hindSiliguri(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // exit wizard screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("হ্যাঁ, বাতিল করুন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Footer navigation actions
  Widget _buildWizardFooter() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 7;

    // Check validation of step media before allowing next
    final isMediaStep = _currentStep == 3;
    final isMediaMissing = isMediaStep && _selectedMediaFile == null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E824C), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "পূর্ববর্তী",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E824C),
                  ),
                ),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isMediaMissing
                  ? null
                  : () {
                      if (isLastStep) {
                        _showPublishSuccessScreen();
                      } else {
                        setState(() {
                          _currentStep++;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isMediaMissing ? Colors.grey[300] : const Color(0xFF1E824C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: isMediaMissing ? 0 : 2,
              ),
              child: Text(
                isLastStep ? "ক্যাম্পেইন পাবলিশ করুন" : "পরবর্তী ধাপ",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isMediaMissing ? Colors.black38 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Confetti Success Screen animation
  void _showPublishSuccessScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Beautiful Custom 3D Rocket Icon Success Animation
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Transform.rotate(
                          angle: (1.0 - value) * -0.3,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E824C).withAlpha(0x2B),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/rocket.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    "অভিনন্দন! আপনার ক্যাম্পেইন সফলভাবে তৈরি হয়েছে",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "আপনার বিজ্ঞাপনটি বর্তমানে রিভিউয়ের জন্য পাঠানো হয়েছে। খুব শীঘ্রই এটি ডকের সকল নির্বাচিত ফিডে লাইভ করা হবে।",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Return to Dashboard Button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        // Pop twice: back to the Campaign Hub Screen
                        Navigator.pop(context); // pop success page
                        Navigator.pop(context); // pop wizard page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E824C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "ড্যাশবোর্ডে ফিরে যান",
                        style: GoogleFonts.hindSiliguri(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
