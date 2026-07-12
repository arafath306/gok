import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class VerificationDashboardScreen extends StatefulWidget {
  const VerificationDashboardScreen({super.key});

  @override
  State<VerificationDashboardScreen> createState() => _VerificationDashboardScreenState();
}

class _VerificationDashboardScreenState extends State<VerificationDashboardScreen> {
  bool _isLoading = true;
  
  Map<String, dynamic>? _activePlan;
  List<String> _earlyAccessFeatures = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    try {
      // 1. Fetch user's verification request to find out selected plan
      final request = await db.fetchUserVerificationRequest();
      
      // 2. Fetch all plans to get the price and name
      if (db.verificationPlans.isEmpty) {
        await db.fetchVerificationPlans();
      }
      
      Map<String, dynamic>? activePlan;
      if (request != null && request['selected_plan_id'] != null) {
        final planId = request['selected_plan_id'] as String;
        try {
          activePlan = db.verificationPlans.firstWhere((p) => p['id'] == planId);
        } catch (e) {
          debugPrint("Plan not found in list: $planId");
        }
      }

      // 3. Fetch early access features from system_settings
      // Assuming features granted to verified users are stored with key prefix 'early_access_'
      // or similar in system_settings. We'll fetch all and filter by value 'true'.
      final sysRes = await Supabase.instance.client
          .from('system_settings')
          .select('key, value, description');
      
      List<String> features = [];
      for (var row in sysRes) {
        final key = row['key'] as String;
        final val = row['value'] as String?;
        final desc = row['description'] as String?;
        
        if (key.startsWith('early_access_') && val == 'true') {
          // format key: early_access_voice_post -> Voice Post
          String name = key.replaceAll('early_access_', '').replaceAll('_', ' ');
          name = name.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
          features.add(desc ?? name);
        }
      }
      
      // If no dynamic features found, show some defaults
      if (features.isEmpty) {
        features = [
          'Voice Posts (Beta)',
          'Priority Support',
          'Extended Video Upload Limits',
        ];
      }

      if (mounted) {
        setState(() {
          
          _activePlan = activePlan;
          _earlyAccessFeatures = features;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading verification dashboard: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.select((DatabaseService db) => db.myProfile);
    
    if (profile == null) return const Scaffold();

    final expiresAt = profile.verifiedExpiresAt;
    final now = DateTime.now();
    int daysRemaining = 0;
    if (expiresAt != null) {
      daysRemaining = expiresAt.difference(now).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile Verification',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Badge Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          'Verified Badge Active',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '@${profile.username}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Subscription Details
              Text(
                'Subscription Details',
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context, 
                      'Plan', 
                      _activePlan?['name'] ?? 'Custom Plan'
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context, 
                      'Price', 
                      _activePlan != null ? '৳${_activePlan!["price"]}' : '---'
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context, 
                      'Days Remaining', 
                      '$daysRemaining Days'
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context, 
                      'Next Repayment', 
                      expiresAt != null 
                          ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}'
                          : 'Lifetime / Unknown',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Benefits / Early Access Features
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orange[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Early Access Benefits',
                    style: GoogleFonts.inter(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _earlyAccessFeatures.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: context.greenAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String title, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: context.textSecondary,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: isHighlight ? context.primaryAccent : context.textPrimary,
            fontSize: 15,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
