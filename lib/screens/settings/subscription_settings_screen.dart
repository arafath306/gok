import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriptionSettingsScreen extends StatelessWidget {
  const SubscriptionSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscription',
          style: GoogleFonts.hindSiliguri(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Subscription Plans\n(Coming Soon)',
          style: GoogleFonts.hindSiliguri(fontSize: 16, color: Colors.black45),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
