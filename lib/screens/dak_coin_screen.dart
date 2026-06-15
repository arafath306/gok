import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/wallet_service.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import 'settings/subscription_settings_screen.dart';

class DakCoinScreen extends StatefulWidget {
  final int initialStep; // Allow pushing directly to buy coin flow if needed
  const DakCoinScreen({super.key, this.initialStep = 0});

  @override
  State<DakCoinScreen> createState() => _DakCoinScreenState();
}

class _DakCoinScreenState extends State<DakCoinScreen> {
  // Navigation steps:
  // 0: Main Wallet Dashboard ("Dak Coin Wallet")
  // 1: Buy Dak Coin Overview
  // 2: Package Selection
  // 3: Payment Method Selector
  // 4: Payment Details Input (bKash)
  // 5: Payment Success Details
  // 6: Transaction History
  // 7: Use Coin - Boost Post Selection
  late int _currentStep;

  // Selected parameters for transaction
  int _selectedCoinsPack = 100; // 100, 300, 500, 1000
  String _selectedPaymentMethod = "bkash"; // bkash, nagad, rocket, upay, visa, cellfin, bank
  final TextEditingController _bkashPhoneCtrl = TextEditingController(text: "017XXXXXXXX");

  // Transaction history filter tab: 'all', 'in', 'out'
  String _historyTab = "all";

  // Selected boost coin package: 250, 500, 1000
  int _selectedBoostCoins = 500;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
  }

  @override
  void dispose() {
    _bkashPhoneCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    String appBarTitle = "Dak Coin Wallet";
    if (_currentStep == 1 || _currentStep == 2) appBarTitle = "Buy Dak Coin";
    if (_currentStep == 3) appBarTitle = "Payment Method";
    if (_currentStep == 4) appBarTitle = "Payment";
    if (_currentStep == 5) appBarTitle = "Payment Success";
    if (_currentStep == 6) appBarTitle = "Coin Transaction History";
    if (_currentStep == 7) appBarTitle = "Use Coin - Boost Post";

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
          onPressed: () {
            setState(() {
              if (_currentStep == 0) {
                Navigator.pop(context);
              } else if (_currentStep == 5) {
                _currentStep = 0; // Success goes to dashboard
              } else if (_currentStep == 6) {
                _currentStep = 0; // History goes to dashboard
              } else if (_currentStep == 7) {
                _currentStep = 0; // Boost goes to dashboard
              } else if (_currentStep == 1) {
                _currentStep = 0; // Buy overview goes to dashboard
              } else {
                _currentStep--; // Step backward in buy chain
              }
            });
          },
        ),
        title: Text(
          appBarTitle,
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: WalletService.balance,
        builder: (context, balance, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            physics: const BouncingScrollPhysics(),
            child: _buildStepView(balance),
          );
        },
      ),
    );
  }

  Widget _buildStepView(int balance) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Dashboard(balance);
      case 1:
        return _buildStep1Overview(balance);
      case 2:
        return _buildStep2SelectPack();
      case 3:
        return _buildStep3PaymentMethod();
      case 4:
        return _buildStep4bKashInput();
      case 5:
        return _buildStep5PaymentSuccess();
      case 6:
        return _buildStep6TransactionHistory();
      case 7:
        return _buildStep7BoostPostCoins(balance);
      default:
        return const SizedBox.shrink();
    }
  }

  // Beautiful stylized golden coin
  Widget _buildGoldCoin({double size = 24.0}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFDF00), Color(0xFFD4AF37), Color(0xFF996515)],
          center: Alignment(-0.2, -0.2),
          radius: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF996515).withAlpha(0x66),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: const Color(0xFFFFEA75), width: 1.5),
      ),
      child: Center(
        child: Text(
          "D",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.55,
            shadows: const [
              Shadow(
                color: Color(0xFF6B4702),
                offset: Offset(0.5, 1.0),
                blurRadius: 1.0,
              )
            ],
          ),
        ),
      ),
    );
  }

  // SCREEN 6 IN MOCK: Main Dak Coin Wallet Dashboard (Step 0)
  Widget _buildStep0Dashboard(int balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green card balance display
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006A4E), Color(0xFF0D5E3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006A4E).withAlpha(0x40),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
                child: Row(
                  children: [
                    _buildGoldCoin(size: 48.0),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Dak Coin Balance",
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(0xD9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "$balance",
                                style: GoogleFonts.inter(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Coins",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(0xB3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 1; // Buy Overview
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF006A4E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Text(
                      "Buy More Coin",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Actions Row
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.card_membership_rounded,
                label: "Subscription",
                onTap: () {
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(child: const SubscriptionSettingsScreen()),
                  ).then((_) {
                    setState(() {}); // Rebuild to sync balance when returning
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.bolt_rounded,
                label: "Boost Post",
                onTap: () {
                  setState(() {
                    _currentStep = 7; // Boost post coin selection
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionItem(
                icon: Icons.history_edu_rounded,
                label: "Transaction History",
                onTap: () {
                  setState(() {
                    _currentStep = 6; // History list
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Recent Transactions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Transactions",
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _currentStep = 6;
                });
              },
              child: Text(
                "View All",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  color: context.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: WalletService.transactions.length.clamp(0, 4),
              separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
              itemBuilder: (context, index) {
                final tx = WalletService.transactions[index];
                final isIn = tx["type"] == "in";
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: isIn 
                        ? (context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9)) 
                        : (context.isDarkMode ? const Color(0xFF4C1C1C) : const Color(0xFFFDEDEC)),
                    radius: 20,
                    child: Icon(
                      isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isIn 
                          ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                          : const Color(0xFFE74C3C),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    tx["title"] as String,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    tx["date"] as String,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11.5,
                      color: context.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    "${isIn ? '+' : '-'}${tx['amount']}",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isIn 
                          ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                          : const Color(0xFFE74C3C),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(0x05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC),
                  radius: 22,
                  child: Icon(icon, color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E), size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SCREEN 1 IN MOCK: Buy Dak Coin Overview (Step 1)
  Widget _buildStep1Overview(int balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        _buildGoldCoin(size: 80.0),
        const SizedBox(height: 16),

        Text(
          "Your Dak Coin Balance",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "$balance",
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            _buildGoldCoin(size: 18.0),
          ],
        ),

        const SizedBox(height: 24),

        // Explanation text card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(0x05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What is Dak Coin?",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Dak Coin is a digital currency for the Dak app. You can use this coin to buy subscriptions, boost posts, and access more premium features.",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1, color: context.border),
              ),

              _buildBenefitBullet(Icons.card_membership_rounded, "Get Subscription"),
              _buildBenefitBullet(Icons.bolt_rounded, "Post Boost করুন"),
              _buildBenefitBullet(Icons.stars_rounded, "Use Premium Features"),
              _buildBenefitBullet(Icons.shield_rounded, "Secure & Safe Transactions"),
            ],
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2; // Package Selection
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Buy Dak Coin",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitBullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC),
            radius: 12,
            child: Icon(icon, color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E), size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13.5,
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 2 IN MOCK: Select Pack (Step 2)
  Widget _buildStep2SelectPack() {
    final List<int> packs = [100, 300, 500, 1000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _buildGoldCoin(size: 72.0),
        const SizedBox(height: 12),

        Text(
          "1 Dak Coin = 1 BDT",
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              "Minimum Purchase: Must buy at least 100 Coins",
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                color: context.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // List of packs
        ...packs.map((packAmount) {
          final isSel = _selectedCoinsPack == packAmount;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSel 
                  ? (context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC)) 
                  : context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel 
                    ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                    : context.border,
                width: isSel ? 2.0 : 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              onTap: () => setState(() => _selectedCoinsPack = packAmount),
              title: Text(
                "$packAmount Coin",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSel 
                      ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                      : context.textPrimary,
                ),
              ),
              trailing: Text(
                "$packAmount ৳",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSel 
                      ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                      : context.textPrimary,
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3; // Payment Method
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Continue",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SCREEN 3 IN MOCK: Payment Method Selector (Step 3)
  Widget _buildStep3PaymentMethod() {
    final List<Map<String, String>> methods = [
      {"id": "bkash", "name": "bKash"},
      {"id": "nagad", "name": "Nagad"},
      {"id": "rocket", "name": "Rocket"},
      {"id": "upay", "name": "Upay"},
      {"id": "visa", "name": "Visa / MasterCard"},
      {"id": "cellfin", "name": "CellFin"},
      {"id": "bank", "name": "Bank Transfer"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Payment Method",
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: methods.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
              itemBuilder: (context, index) {
                final m = methods[index];
                final isSel = _selectedPaymentMethod == m["id"];
                return InkWell(
                  onTap: () => setState(() => _selectedPaymentMethod = m["id"]!),
                  child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSel 
                              ? (context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC)) 
                              : (context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F4F6)),
                          radius: 18,
                          child: Icon(
                            m["id"] == "bkash" || m["id"] == "nagad" || m["id"] == "rocket" || m["id"] == "upay"
                                ? Icons.account_balance_wallet_rounded
                                : (m["id"] == "bank" ? Icons.business_rounded : Icons.credit_card_rounded),
                            color: isSel 
                                ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                                : context.textSecondary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            m["name"]!,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel 
                                  ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                                  : context.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel 
                                  ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                                  : context.textMuted,
                              width: isSel ? 6.0 : 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                if (_selectedPaymentMethod == "bkash") {
                  _currentStep = 4; // bKash details input
                } else {
                  _processMockPayment();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Pay $_selectedCoinsPack BDT",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SCREEN 4 IN MOCK: Secure bKash Payment Screen (Step 4)
  Widget _buildStep4bKashInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Secure payment banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0C5E3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                "Secure Payment",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2125B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        "b",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Enter bKash Number",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bkashPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF006A4E), width: 1.5),
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14, letterSpacing: 1.0, color: context.textPrimary),
              ),

              const SizedBox(height: 16),

              Text(
                "Amount",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$_selectedCoinsPack ৳",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: context.border),
              const SizedBox(height: 16),

              Text(
                "Go to your bKash mobile menu",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _buildStepInstructions("১", "Dial *247#"),
              _buildStepInstructions("২", "Select Payment option"),
              _buildStepInstructions("৩", "Make bKash Payment"),
              _buildStepInstructions("৪", "Enter Payment Reference"),
            ],
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _processMockPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Confirm Payment",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 3; // Back to selector
              });
            },
            child: Text(
              "Cancel",
              style: GoogleFonts.hindSiliguri(
                color: const Color(0xFFE74C3C),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepInstructions(String stepNo, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC),
            child: Text(
              _toBengaliNumber(stepNo),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 5 IN MOCK: Payment Success Details (Step 5)
  Widget _buildStep5PaymentSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Green Tick with bounce
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFF006A4E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          "Payment Successful!",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "আপনার অ্যাকাউন্ট সফলভাবে\n${_toBengaliNumber(_selectedCoinsPack.toString())} Dak Coin যুক্ত করা হয়েছে।",
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: context.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 28),

        // Payment Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment Details",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: context.border),
              ),
              _buildDetailItem("Coin Purchased", "$_selectedCoinsPack Coin"),
              const SizedBox(height: 10),
              _buildDetailItem("Amount", "$_selectedCoinsPack BDT"),
              const SizedBox(height: 10),
              _buildDetailItem("Transaction ID", "TRX1234567890"),
              const SizedBox(height: 10),
              _buildDetailItem("Date & Time", "19 May 2024, 10:30 AM"),
            ],
          ),
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 0; // Return to Dashboard
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Back to Wallet",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF006A4E),
                  content: Text("Downloading receipt...", style: GoogleFonts.hindSiliguri()),
                ),
              );
            },
            child: Text(
              "View Receipt",
              style: GoogleFonts.hindSiliguri(
                color: context.primaryAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 13,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.hindSiliguri(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  // SCREEN 6 DETAILS: Transaction History (Step 6)
  Widget _buildStep6TransactionHistory() {
    final filtered = WalletService.transactions.where((tx) {
      if (_historyTab == "in") return tx["type"] == "in";
      if (_historyTab == "out") return tx["type"] == "out";
      return true;
    }).toList();

    return Column(
      children: [
        // Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildHistoryTabItem("all", "All"),
              _buildHistoryTabItem("in", "Coin In"),
              _buildHistoryTabItem("out", "Coin Out"),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // History List
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
              itemBuilder: (context, index) {
                final tx = filtered[index];
                final isIn = tx["type"] == "in";
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: isIn 
                            ? (context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9)) 
                            : (context.isDarkMode ? const Color(0xFF4C1C1C) : const Color(0xFFFDEDEC)),
                        radius: 18,
                        child: Icon(
                          isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isIn 
                              ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                              : const Color(0xFFE74C3C),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx["title"] as String,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx["date"] as String,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 11,
                                color: context.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tx["id"] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${isIn ? '+' : '-'}${tx['amount']}",
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isIn 
                              ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                              : const Color(0xFFE74C3C),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Load More button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF006A4E),
                  content: Text("No additional transactions.", style: GoogleFonts.hindSiliguri()),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Load More",
              style: GoogleFonts.hindSiliguri(
                color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTabItem(String id, String label) {
    final isSel = _historyTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _historyTab = id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? context.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(0x05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel 
                    ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                    : context.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SCREEN 5 DETAILS: Use Coin - Boost Post (Step 7)
  Widget _buildStep7BoostPostCoins(int balance) {
    final List<Map<String, dynamic>> boostPacks = [
      {"coins": 250, "reach": "5K - 10K Reach"},
      {"coins": 500, "reach": "15K - 30K Reach", "tag": "Medium Boost"},
      {"coins": 1000, "reach": "50K - 100K Reach", "tag": "Maximum Boost"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mock post preview card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.isDarkMode ? const Color(0xFF151824) : Colors.grey[200],
                    child: Icon(Icons.person, color: context.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Dak Official",
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                        ],
                      ),
                      Text(
                        "2h",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 11,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "প্রকৃতির মাঝে হারিয়ে যাওয়া একটা অসাধারণ অনুভূতি!",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13.5,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC),
                  child: Center(
                    child: Icon(Icons.image_outlined, size: 40, color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          "Boost This Post",
          style: GoogleFonts.hindSiliguri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        Text(
          "আপনার Postকে বেশি মানুষের কাছে পৌঁছে Day",
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            color: context.textMuted,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          "Select Boost Package:",
          style: GoogleFonts.hindSiliguri(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        ...boostPacks.map((pack) {
          final isSel = _selectedBoostCoins == pack["coins"];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSel 
                  ? (context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE6F0EC)) 
                  : context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel 
                    ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                    : context.border,
                width: isSel ? 2.0 : 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => setState(() => _selectedBoostCoins = pack["coins"] as int),
              title: Row(
                children: [
                  Text(
                    "${pack['coins']} Coin",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isSel 
                          ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                          : context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (pack["tag"] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel 
                            ? (context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9)) 
                            : (context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pack["tag"] as String,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E),
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Text(
                pack["reach"] as String,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSel 
                      ? (context.isDarkMode ? const Color(0xFF2ECC71) : const Color(0xFF006A4E)) 
                      : context.textSecondary,
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _processPostBoost(balance),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Boost for $_selectedBoostCoins Coin",
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Process checkout loading & success for buying coins
  void _processMockPayment() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          navigator.pop(); // Close dialog
          WalletService.addCoins(_selectedCoinsPack);
          setState(() {
            _currentStep = 5; // Payment success details
          });
        });
        return AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: Color(0xFF006A4E)),
              const SizedBox(height: 20),
              Text(
                "Payment is processing...",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait...",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11.5,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Process post boost
  void _processPostBoost(int balance) {
    if (balance < _selectedBoostCoins) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "ব্যালেন্স অপর্যাপ্ত!",
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: context.textPrimary,
            ),
          ),
          content: Text(
            "Post বুস্ট করার জন্য আপনার ওয়ালেটে পর্যাপ্ত কয়েন নেই। দয়া করে রিচার্জ করুন।",
            style: GoogleFonts.hindSiliguri(
              fontSize: 13.5,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: GoogleFonts.hindSiliguri(color: context.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _currentStep = 1; // Direct to Buy Overview
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A4E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "Buy More Coin",
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          navigator.pop(); // close loading dialog
          WalletService.deductCoins(_selectedBoostCoins, "Post Boost");
          setState(() {
            _currentStep = 0; // Return to Dashboard
          });
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF006A4E),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Post বুস্ট সফলভাবে সম্পন্ন হয়েছে!",
                    style: GoogleFonts.hindSiliguri(fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        });
        return AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: Color(0xFF006A4E)),
              const SizedBox(height: 20),
              Text(
                "Post বুস্ট করা হচ্ছে...",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait...",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11.5,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
