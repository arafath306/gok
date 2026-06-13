import 'package:flutter/material.dart';

/// Simple in-memory wallet service for Dak Coin balance.
class WalletService {
  // Current balance as a ValueNotifier so UI can rebuild reactively
  static final ValueNotifier<int> balance = ValueNotifier<int>(0);

  // Transaction history list (newest first)
  // Each entry: { "title": String, "date": String, "amount": int, "type": "in"|"out" }
  static final List<Map<String, dynamic>> transactions = [
    {
      "title": "Bought 100 Coins",
      "date": "Jun 10, 2026",
      "amount": 100,
      "type": "in",
    },
    {
      "title": "Post Boost",
      "date": "Jun 9, 2026",
      "amount": 50,
      "type": "out",
    },
  ];

  /// Add coins to balance (e.g., after purchase).
  static void addCoins(int amount) {
    balance.value += amount;
    transactions.insert(0, {
      "title": "Bought $amount Coins",
      "date": _todayString(),
      "amount": amount,
      "type": "in",
    });
  }

  /// Spend coins (e.g., boost post).
  /// Returns true if successful, false if insufficient balance.
  static bool spendCoins(int amount, {String reason = "Used Coins"}) {
    if (balance.value < amount) return false;
    balance.value -= amount;
    transactions.insert(0, {
      "title": reason,
      "date": _todayString(),
      "amount": amount,
      "type": "out",
    });
    return true;
  }

  /// Alias for spendCoins — deducts coins with a reason label.
  static bool deductCoins(int amount, String reason) {
    return spendCoins(amount, reason: reason);
  }

  static String _todayString() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${months[now.month - 1]} ${now.day}, ${now.year}";
  }
}
