import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'boost_post_selection_screen.dart';
import 'campaign_wizard_screen.dart';
import '../../utils/routes.dart';

class AdsCampaignScreen extends StatefulWidget {
  const AdsCampaignScreen({super.key});

  @override
  State<AdsCampaignScreen> createState() => _AdsCampaignScreenState();
}

class _AdsCampaignScreenState extends State<AdsCampaignScreen> {
  int _selectedDaysIndex = 6; // Default to "7 Days" (Index 6)
  
  // Available timeframe choices: 1 to 15 days
  final List<int> _daysOptions = List.generate(15, (index) => index + 1);

  // Bengali translation of digits
  String _toBengaliNumber(String englishNumber) {
    const Map<String, String> translation = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    return englishNumber.split('').map((char) => translation[char] ?? char).join();
  }

  // Generates pseudorandom but deterministic stats based on selected day count
  double _getReach(int days) {
    return days * 1850.0 + (sin(days * 1.5) * 500.0) + 1200.0;
  }

  double _getEngagement(int days) {
    return days * 380.0 + (cos(days * 2.0) * 120.0) + 240.0;
  }

  double _getConversions(int days) {
    return (days * 12.4 + (sin(days * 0.8) * 4.2) + 8.0).roundToDouble();
  }

  double _getConversionRate(int days) {
    final reach = _getReach(days);
    final conversions = _getConversions(days);
    if (reach == 0) return 0.0;
    return (conversions / reach * 100 * 10).round() / 10.0;
  }

  // Map of cities and their base share of views
  List<Map<String, dynamic>> _getCitiesShare(int days) {
    // Dynamically shift percentages slightly based on selected timeframe
    double dhakaBase = 52.0 + sin(days * 0.5) * 4;
    double ctgBase = 24.0 + cos(days * 0.7) * 3;
    double sylhetBase = 12.0 + sin(days * 1.2) * 2;
    double khulnaBase = 7.0 + cos(days * 0.4) * 1.5;
    double rajBase = 5.0 + sin(days * 2.0) * 1;
    
    double total = dhakaBase + ctgBase + sylhetBase + khulnaBase + rajBase;
    dhakaBase = (dhakaBase / total) * 100;
    ctgBase = (ctgBase / total) * 100;
    sylhetBase = (sylhetBase / total) * 100;
    khulnaBase = (khulnaBase / total) * 100;
    rajBase = (rajBase / total) * 100;

    return [
      {"name": "ঢাকা", "percentage": dhakaBase},
      {"name": "চট্টগ্রাম", "percentage": ctgBase},
      {"name": "সিলেট", "percentage": sylhetBase},
      {"name": "খুলনা", "percentage": khulnaBase},
      {"name": "রাজশাহী", "percentage": rajBase},
    ];
  }

  // Map of specific areas and base share of views
  List<Map<String, dynamic>> _getAreasShare(int days) {
    double dhanmondi = 40.0 + cos(days * 0.6) * 5;
    double gec = 25.0 + sin(days * 0.9) * 4;
    double uttara = 18.0 + cos(days * 1.5) * 3;
    double mirpur = 12.0 + sin(days * 0.4) * 2;
    double gulshan = 5.0 + cos(days * 2.2) * 1.5;

    double total = dhanmondi + gec + uttara + mirpur + gulshan;
    dhanmondi = (dhanmondi / total) * 100;
    gec = (gec / total) * 100;
    uttara = (uttara / total) * 100;
    mirpur = (mirpur / total) * 100;
    gulshan = (gulshan / total) * 100;

    return [
      {"name": "ধানমন্ডি (ঢাকা)", "percentage": dhanmondi},
      {"name": "জিইসি মোড় (চট্টগ্রাম)", "percentage": gec},
      {"name": "উত্তরা (ঢাকা)", "percentage": uttara},
      {"name": "মিরপুর (ঢাকা)", "percentage": mirpur},
      {"name": "গুলশান (ঢাকা)", "percentage": gulshan},
    ];
  }

  // Generates graph points based on the days count
  List<double> _getTrendPoints(int days) {
    List<double> points = [];
    for (int i = 0; i < days; i++) {
      // Simulate trend values between 0.1 and 0.95
      double val = 0.35 + (sin(i * 0.8) * 0.2) + (cos((i + days) * 0.5) * 0.15);
      points.add(val.clamp(0.1, 0.95));
    }
    // Handle single day case edge-case
    if (points.length == 1) {
      points.add(points[0]);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = _daysOptions[_selectedDaysIndex];
    final reach = _getReach(activeDays);
    final engagement = _getEngagement(activeDays);
    final conversions = _getConversions(activeDays);
    final convRate = _getConversionRate(activeDays);
    final cities = _getCitiesShare(activeDays);
    final areas = _getAreasShare(activeDays);
    final trendPoints = _getTrendPoints(activeDays);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Matches professional dashboard
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "বিজ্ঞাপন ক্যাম্পেইন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.black54),
            onPressed: () => _showHelpDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Quick Action Hub (Premium Glassmorphic-style row)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    title: "বিদ্যমান পোস্ট বুস্ট করুন",
                    subtitle: "আপনার পূর্বের সফল পোস্ট প্রমোট করুন",
                    icon: Icons.bolt_rounded,
                    gradientColors: [const Color(0xFF1E824C), const Color(0xFF2E9B5C)],
                    onTap: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const BoostPostSelectionScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    title: "নতুন ক্যাম্পেইন করুন",
                    subtitle: "টার্গেটেড বিজ্ঞাপন বা ক্যাম্পেইন শুরু করুন",
                    icon: Icons.add_circle_outline_rounded,
                    gradientColors: [const Color(0xFF2C3E50), const Color(0xFF34495E)],
                    onTap: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const CampaignWizardScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Timeframe Selector Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "বিজ্ঞাপন পারফরম্যান্স ও এনালাইটিক্স",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "সময়কাল নির্বাচন করুন",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: const Color(0xFF1E824C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Timeframe scrollable capsule selector (1 to 15 days)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _daysOptions.length,
                itemBuilder: (context, index) {
                  final days = _daysOptions[index];
                  final isSelected = index == _selectedDaysIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDaysIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E824C) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E824C) : const Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1E824C).withAlpha(0x4D),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            "গত ${ _toBengaliNumber(days.toString())} দিন",
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Metrics Grid (Reach, Engagement, Conversion)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: [
                _buildMetricCard(
                  title: "মোট রিচ (Reach)",
                  value: _toBengaliNumber(reach.toInt().toString()),
                  icon: Icons.people_outline_rounded,
                  accentColor: const Color(0xFF1E824C),
                  percentage: "১২.২%",
                  isUp: true,
                ),
                _buildMetricCard(
                  title: "এঙ্গেজমেন্ট (Engagement)",
                  value: _toBengaliNumber(engagement.toInt().toString()),
                  icon: Icons.touch_app_outlined,
                  accentColor: const Color(0xFFE67E22),
                  percentage: "৮.৫%",
                  isUp: true,
                ),
                _buildMetricCard(
                  title: "কনভার্সন রেট",
                  value: "${_toBengaliNumber(convRate.toString())}%",
                  icon: Icons.insights_rounded,
                  accentColor: const Color(0xFF9B59B6),
                  percentage: "${_toBengaliNumber(conversions.toInt().toString())} টি সেলস",
                  isUp: true,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Performance Trend Line Chart Card
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
                      Text(
                        "বিজ্ঞাপন ইম্প্রেশন ও ট্রেন্ড",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "১ - ${ _toBengaliNumber(activeDays.toString())} তম দিন",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Graph with Custom Paint
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _CampaignLineChartPainter(pointsY: trendPoints),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Custom dynamic timeline label row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      activeDays > 5 ? 5 : activeDays,
                      (index) {
                        int dayNum = 1;
                        if (activeDays > 5) {
                          dayNum = (index * (activeDays - 1) / 4).round() + 1;
                        } else {
                          dayNum = index + 1;
                        }
                        return Text(
                          "দিন $dayNum",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 9.5,
                            color: Colors.black38,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Geographic Breakdown (Cities and Areas side-by-side or stacked)
            Text(
              "অডিয়েন্স ও ভৌগোলিক অ্যানালিটিক্স",
              style: GoogleFonts.hindSiliguri(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            // Top Cities Card
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
                      const Icon(Icons.location_city_rounded, color: Color(0xFF1E824C), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "শীর্ষ শহরসমূহ (Top Cities)",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cities.map((city) => _buildProgressRow(
                        label: city["name"] as String,
                        percentage: city["percentage"] as double,
                        color: const Color(0xFF1E824C),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Top Areas Card
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
                      const Icon(Icons.map_rounded, color: Color(0xFF2C3E50), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "শীর্ষ এলাকাসমূহ (Top Areas)",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...areas.map((area) => _buildProgressRow(
                        label: area["name"] as String,
                        percentage: area["percentage"] as double,
                        color: const Color(0xFF34495E),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Past Campaigns Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "পূর্বের ক্যাম্পেইন ও বুস্টের ইতিহাস",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "সব দেখুন",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: const Color(0xFF1E824C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List of mock historical campaigns
            _buildCampaignHistoryItem(
              title: "বিদ্যমান পোশাক প্রোডাক্ট বুস্ট",
              campaignType: "পোস্ট বুস্ট",
              budget: "২,০০০ ৳",
              dateRange: "১ জুন - ৭ জুন, ২০২৬",
              reach: "২৮,৪৫০ জন",
              statusText: "সম্পূর্ণ",
              statusColor: Colors.grey,
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: 8),
            _buildCampaignHistoryItem(
              title: "ঈদ ধামাকা অফার ক্যাম্পেইন",
              campaignType: "নতুন ক্যাম্পেইন",
              budget: "৫,০০০ ৳",
              dateRange: "১০ জুন - ১৫ জুন, ২০২৬",
              reach: "১৪,২০০ জন",
              statusText: "চলমান",
              statusColor: const Color(0xFF1E824C),
              icon: Icons.campaign_rounded,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Quick Action Buttons Builder
  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha(0x3B),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withAlpha(0x3D),
                  radius: 20,
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Premium Metric Card Widget Builder
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String percentage,
    required bool isUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: accentColor.withAlpha(0x1F),
                radius: 14,
                child: Icon(icon, color: accentColor, size: 14),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 10,
                    color: isUp ? const Color(0xFF1E824C) : Colors.red,
                  ),
                  Text(
                    percentage,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isUp ? const Color(0xFF1E824C) : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.hindSiliguri(
              fontSize: 9.5,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Beautiful Progress Row for Demographics
  Widget _buildProgressRow({
    required String label,
    required double percentage,
    required Color color,
  }) {
    final displayPercentage = percentage.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${_toBengaliNumber(displayPercentage)}%",
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                width: MediaQuery.of(context).size.width * 0.8 * (percentage / 100),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Campaign History Item Builder
  Widget _buildCampaignHistoryItem({
    required String title,
    required String campaignType,
    required String budget,
    required String dateRange,
    required String reach,
    required String statusText,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(0x1C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        campaignType,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 9.5,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "বাজেট: $budget",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateRange,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10.5,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(0x2B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "রিচ: $reach",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




  // Simple Info Dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "বিজ্ঞাপন ও ক্যাম্পেইন গাইড",
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, fontSize: 15.5),
        ),
        content: Text(
          "Dak বিজ্ঞাপন হাবের মাধ্যমে আপনার পণ্য বা সার্ভিসের প্রসার বাড়াতে পারবেন। আপনার যেকোনো পোস্ট বুস্ট করতে পারবেন অথবা নতুন প্রচার শুরু করতে পারবেন। \n\nআপনার কাস্টমার যে এলাকা থেকে বেশি ভিজিট করছেন বা যে সময় বেশি অ্যাক্টিভ থাকছেন, তার বিবরণ এনালাইটিক্স বিভাগে দেখতে পাবেন।",
          style: GoogleFonts.hindSiliguri(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "বুঝতে পেরেছি",
              style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          )
        ],
      ),
    );
  }
}

// Custom painter for Campaign Trend Graph
class _CampaignLineChartPainter extends CustomPainter {
  final List<double> pointsY;

  _CampaignLineChartPainter({required this.pointsY});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF1E824C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintArea = Paint()
      ..color = const Color(0xFF1E824C).withAlpha(0x1F)
      ..style = PaintingStyle.fill;

    final paintDot = Paint()
      ..color = const Color(0xFF1E824C)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final pointsXStep = size.width / (pointsY.length - 1);
    final path = Path();
    final areaPath = Path();

    areaPath.moveTo(0, size.height);

    for (int i = 0; i < pointsY.length; i++) {
      final x = i * pointsXStep;
      final y = size.height - (pointsY[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Draw shading area
    canvas.drawPath(areaPath, paintArea);

    // Draw line
    canvas.drawPath(path, paintLine);

    // Draw nodes/dots (draw less nodes if there are too many to avoid overlap clutter)
    int skipInterval = (pointsY.length / 8).ceil();
    if (skipInterval < 1) skipInterval = 1;

    for (int i = 0; i < pointsY.length; i += skipInterval) {
      final x = i * pointsXStep;
      final y = size.height - (pointsY[i] * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, paintDot);
      canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = Colors.white);
    }
    
    // Always draw the last node
    if ((pointsY.length - 1) % skipInterval != 0) {
      final x = size.width;
      final y = size.height - (pointsY.last * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, paintDot);
      canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _CampaignLineChartPainter oldDelegate) {
    return oldDelegate.pointsY != pointsY;
  }
}
