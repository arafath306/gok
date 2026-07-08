import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../state/monetization_controller.dart';
import '../../utils/app_theme.dart';

class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen> {
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }
  
  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile != null) {
      final mc = Provider.of<MonetizationController>(context, listen: false);
      await mc.fetchCreatorDashboard(myProfile.id);
      if (mc.creatorSettings != null) {
        _priceController.text = mc.creatorSettings!['monthly_price'].toString();
      } else {
        _priceController.text = "0";
      }
    }
  }

  Future<void> _savePrice() async {
    final newPrice = double.tryParse(_priceController.text) ?? 0.0;
    if (newPrice < 0) return;
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;
    
    try {
      final mc = Provider.of<MonetizationController>(context, listen: false);
      await mc.saveCreatorPrice(myProfile.id, newPrice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price updated successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update price: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mc = Provider.of<MonetizationController>(context);
    final isLoading = mc.isLoadingDashboard;

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
          'Creator Dashboard',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 48,
                      color: context.primaryAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${mc.activeSubscribers}',
                      style: GoogleFonts.inter(
                        color: context.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Active Subscribers',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Subscription Settings',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Price (৳)',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(color: context.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: GoogleFonts.inter(color: context.textSecondary.withValues(alpha: 0.5)),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePrice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save Settings',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
