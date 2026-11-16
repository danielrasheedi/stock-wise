import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/database.dart';
import '../services/currency_service.dart';

class HistoryEntry {
  final String id;
  final String actionType; // 'add_item', 'stock_in', 'stock_out', 'delete_item'
  final String itemName;
  final int? quantity;
  final DateTime timestamp;

  const HistoryEntry({
    required this.id,
    required this.actionType,
    required this.itemName,
    this.quantity,
    required this.timestamp,
  });
}

/// A central repository for the application's global state
class AppState {
  static bool isManualLogout = false;
  static StreamSubscription<DocumentSnapshot>? _analyticsSubscription;

  static final ValueNotifier<int> dailyStockIn = ValueNotifier<int>(0);
  static final ValueNotifier<int> dailyStockOut = ValueNotifier<int>(0);
  
  static final ValueNotifier<int> lowStockThreshold = ValueNotifier<int>(5);

  static final ValueNotifier<String> currency = ValueNotifier<String>('USD (\$)');
  static final ValueNotifier<Map<String, double>> exchangeRates = ValueNotifier<Map<String, double>>({});
  
  static final ValueNotifier<int> totalFolders = ValueNotifier<int>(0);
  static final ValueNotifier<int> totalItems = ValueNotifier<int>(0);
  static final ValueNotifier<double> totalInventoryValueUsd = ValueNotifier<double>(0.0);
  static final ValueNotifier<int> lowStockItemsCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> outOfStockItemsCount = ValueNotifier<int>(0);

  /// Resets all temporary in-memory state variables when logging out
  static void reset() {
    dailyStockIn.value = 0;
    dailyStockOut.value = 0;
    totalFolders.value = 0;
    totalItems.value = 0;
    totalInventoryValueUsd.value = 0.0;
    lowStockItemsCount.value = 0;
    outOfStockItemsCount.value = 0;
    _analyticsSubscription?.cancel();
  }

  /// Increments stock in counter in Firebase
  static Future<void> incrementStockIn(int qty) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await Database.userDoc.collection('analytics').doc(todayStr).set({
      'stockIn': FieldValue.increment(qty),
    }, SetOptions(merge: true));
  }

  /// Increments stock out counter in Firebase
  static Future<void> incrementStockOut(int qty) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await Database.userDoc.collection('analytics').doc(todayStr).set({
      'stockOut': FieldValue.increment(qty),
    }, SetOptions(merge: true));
  }

  /// Loads the daily stock in/out counters from Firebase analytics.
  static Future<void> loadDailyCounters() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final docRef = Database.userDoc.collection('analytics').doc(todayStr);

    _analyticsSubscription?.cancel();
    _analyticsSubscription = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        dailyStockIn.value = data['stockIn'] as int? ?? 0;
        dailyStockOut.value = data['stockOut'] as int? ?? 0;
      } else {
        dailyStockIn.value = 0;
        dailyStockOut.value = 0;
      }
    });
  }

  /// Initializes exchange rates
  static Future<void> loadExchangeRates() async {
    final rates = await CurrencyService.fetchRates();
    if (rates != null) {
      exchangeRates.value = rates;
    }
  }

  /// Extracts the currency symbol (e.g. '$', 'RM')
  static String getCurrencySymbol() {
    final currencyStr = currency.value;
    final startIndex = currencyStr.indexOf('(');
    final endIndex = currencyStr.indexOf(')');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return currencyStr.substring(startIndex + 1, endIndex);
    }
    return '\$';
  }

  /// Converts a USD price to the currently active currency
  static double getConvertedPrice(double usdPrice) {
    if (exchangeRates.value.isEmpty) return usdPrice;
    
    final currencyStr = currency.value;
    final currencyCode = currencyStr.substring(0, 3); // Extracts 'USD', 'MYR', etc.
    
    final rate = exchangeRates.value[currencyCode];
    if (rate != null) {
      return usdPrice * rate;
    }
    return usdPrice; // Fallback to raw if rate not found
  }

  /// Converts a local currency price back to USD
  static double getUsdPrice(double localPrice) {
    if (exchangeRates.value.isEmpty) return localPrice;
    
    final currencyStr = currency.value;
    final currencyCode = currencyStr.substring(0, 3);
    
    final rate = exchangeRates.value[currencyCode];
    if (rate != null && rate > 0) {
      return localPrice / rate;
    }
    return localPrice;
  }

  /// Helper to record an entry in the user's history collection
  static Future<void> addHistory(String actionType, String itemName, int? quantity) async {
    try {
      await Database.userDoc.collection('history').add({
        'actionType': actionType,
        'itemName': itemName,
        'quantity': quantity,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to add history: $e');
    }
  }
}
