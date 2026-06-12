import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/routes.dart';
import 'settings/settings_screen.dart';
import 'boost/ads_campaign_screen.dart';
import 'boost/creator_insights_screen.dart';
import 'boost/creator_guidelines_screen.dart';
import 'boost/monetization/monetization_hub_screen.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Soft warm grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "প্রফেশনাল ড্যাশবোর্ড",
          style: GoogleFonts.hindSiliguri(
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Color(0xFF1E824C)),
            tooltip: "বিজ্ঞাপন ক্যাম্পেইন",
            onPressed: () {
              Navigator.push(
                context,
                NoTransitionPageRoute(child: const AdsCampaignScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                NoTransitionPageRoute(child: const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Box (Compact)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo_d_icon_v2.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Dak Official",
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF1E824C), size: 14),
                          ],
                        ),
                        Text(
                          "প্রফেশনাল অ্যাকাউন্ট",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11.5,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats row (Compact vertical padding)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Row(
                children: [
                  _buildStatItem("125", "পোস্ট"),
                  _buildDivider(),
                  _buildStatItem("1.2K", "অনুসারী"),
                  _buildDivider(),
                  _buildStatItem("850", "অনুসরণ করছেন"),
                  _buildDivider(),
                  _buildStatItem("24K", "পোস্ট ইম্প্রেশন"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Performance Header
            Text(
              "পারফরম্যান্স (গত ৭ দিন)",
              style: GoogleFonts.hindSiliguri(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            // Performance Grid (Highly space-efficient with 2.0 aspect ratio)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                _buildPerformanceCard("24K", "পোস্ট রিচ", "12.5%", Icons.people_outline),
                _buildPerformanceCard("3.5K", "ইন্টারঅ্যাকশন", "8.2%", Icons.favorite_border),
                _buildPerformanceCard("320", "নতুন অনুসারী", "15.3%", Icons.person_add_outlined),
                _buildPerformanceCard("128", "পোস্ট শেয়ার", "10.1%", Icons.share_outlined),
              ],
            ),

            const SizedBox(height: 16),

            // Impression graph card (Compact Graph height: 100)
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
                    "ইম্প্রেশন ট্রেন্ড",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // The Line Graph custom painter
                  SizedBox(
                    height: 100,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _LineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGraphDateLabel("May 10"),
                      _buildGraphDateLabel("May 11"),
                      _buildGraphDateLabel("May 12"),
                      _buildGraphDateLabel("May 13"),
                      _buildGraphDateLabel("May 14"),
                      _buildGraphDateLabel("May 15"),
                      _buildGraphDateLabel("May 16"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Creator Tools (NEW SECTION)
            Text(
              "ক্রিয়েটর টুলস (Creator Tools)",
              style: GoogleFonts.hindSiliguri(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Column(
                children: [
                  _buildToolTile(
                    Icons.analytics_outlined, 
                    "বিস্তারিত ইনসাইটস", 
                    "অডিয়েন্স ডেমোগ্রাফিকস ও রিচ অ্যানালিটিক্স",
                    onTap: () => Navigator.push(context, NoTransitionPageRoute(child: const CreatorInsightsScreen())),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  _buildToolTile(
                    Icons.monetization_on_outlined, 
                    "মনিটাইজেশন হাব", 
                    "আপনার আয়ের বিবরণ ও বোনাস প্রোগ্রাম",
                    onTap: () => Navigator.push(context, NoTransitionPageRoute(child: const MonetizationHubScreen())),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  _buildToolTile(
                    Icons.campaign_outlined,
                    "বিজ্ঞাপন HUB",
                    "পোস্ট প্রমোট করুন এবং ক্যাম্পেইন ম্যানেজ করুন",
                    onTap: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const AdsCampaignScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  _buildToolTile(
                    Icons.lightbulb_outline, 
                    "ক্রিয়েটর গাইডলাইন", 
                    "অডিয়েন্স বাড়ানোর সেরা টিপস ও ট্রিক্স",
                    onTap: () => Navigator.push(context, NoTransitionPageRoute(child: const CreatorGuidelinesScreen())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recent Posts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "সাম্প্রতিক পোস্ট",
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

            // Recent post item
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/logo_d_icon_v2.jpg', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "আজকের দিনটা সুন্দর কাটুক সবার! ☕️🌿",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "১ দিন আগে",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "24K",
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 10.5,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 0.5,
      height: 24,
      color: Colors.grey[300],
    );
  }

  Widget _buildPerformanceCard(String val, String title, String percentage, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 10.5,
                    color: Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 10, color: Color(0xFF1E824C)),
                    const SizedBox(width: 1),
                    Text(
                      percentage,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E824C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xB31E824C), size: 18),
        ],
      ),
    );
  }

  Widget _buildToolTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF1E824C), size: 20),
      title: Text(
        title,
        style: GoogleFonts.hindSiliguri(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.hindSiliguri(
          fontSize: 11,
          color: Colors.black45,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildGraphDateLabel(String date) {
    return Text(
      date,
      style: GoogleFonts.outfit(
        fontSize: 9.5,
        color: Colors.black38,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF1E824C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF1E824C)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.grey[100]!
      ..strokeWidth = 1;

    // Y values of points (from 0 to 1) where 0 is bottom, 1 is top
    final pointsY = [0.3, 0.45, 0.55, 0.5, 0.8, 0.4, 0.65];
    final pointsXStep = size.width / (pointsY.length - 1);

    // Draw horizontal grid lines
    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final path = Path();
    for (int i = 0; i < pointsY.length; i++) {
      final x = i * pointsXStep;
      // Invert Y because canvas origin is top-left
      final y = size.height - (pointsY[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw graph line
    canvas.drawPath(path, paintLine);

    // Draw dots on nodes
    for (int i = 0; i < pointsY.length; i++) {
      final x = i * pointsXStep;
      final y = size.height - (pointsY[i] * size.height);
      canvas.drawCircle(Offset(x, y), 3, paintDot);
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
