import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/general_settings_provider.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String? badgeType;
  final double size;
  
  const VerificationBadge({
    super.key, 
    required this.isVerified,
    this.badgeType,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();
    
    final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);
    
    if (!settings.isTieredBadgesEnabled) {
      return Icon(Icons.verified, color: Colors.blue, size: size);
    }
    
    // Tiered logic
    Color badgeColor;
    if (badgeType == 'gold') {
      badgeColor = Colors.amber;
    } else if (badgeType == 'gray') {
      badgeColor = Colors.grey;
    } else {
      badgeColor = Colors.blue;
    }
    
    return Icon(Icons.verified, color: badgeColor, size: size);
  }
}
