import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  // Rates come from the app's own server function, which keeps the API key private
  static const String apiUrl = 'https://stockwisemy.vercel.app/api/rates';
  static const String cacheKey = 'exchange_rates_cache';
  static const String cacheTimeKey = 'exchange_rates_time';

  static Future<Map<String, double>?> fetchRates() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check cache first (24 hour expiry)
    final cachedTimeStr = prefs.getString(cacheTimeKey);
    if (cachedTimeStr != null) {
      final cachedTime = DateTime.parse(cachedTimeStr);
      if (DateTime.now().difference(cachedTime).inHours < 24) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final Map<String, dynamic> json = jsonDecode(cachedData);
          return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
        }
      }
    }

    // Fetch from API
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          final conversionRates = data['conversion_rates'] as Map<String, dynamic>;
          
          // Cache the result
          await prefs.setString(cacheKey, jsonEncode(conversionRates));
          await prefs.setString(cacheTimeKey, DateTime.now().toIso8601String());
          
          return conversionRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        }
      }
    } catch (e) {
      // Fallback to expired cache if network fails
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final Map<String, dynamic> json = jsonDecode(cachedData);
        return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    }
    
    return null; // Return null if fetching fails and no cache exists
  }
}
