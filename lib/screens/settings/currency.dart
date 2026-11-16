import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencies = [
      'AED (د.إ)',
      'ARS (\$)',
      'AUD (\$)',
      'BDT (৳)',
      'BRL (R\$)',
      'CAD (\$)',
      'CHF (Fr)',
      'CLP (\$)',
      'CNY (¥)',
      'COP (\$)',
      'CZK (Kč)',
      'DKK (kr)',
      'EGP (£)',
      'EUR (€)',
      'GBP (£)',
      'HKD (\$)',
      'HUF (Ft)',
      'IDR (Rp)',
      'ILS (₪)',
      'INR (₹)',
      'JPY (¥)',
      'KES (KSh)',
      'KRW (₩)',
      'LKR (Rs)',
      'MAD (DH)',
      'MXN (\$)',
      'MYR (RM)',
      'NGN (₦)',
      'NOK (kr)',
      'NZD (\$)',
      'PHP (₱)',
      'PKR (₨)',
      'PLN (zł)',
      'RON (lei)',
      'RUB (₽)',
      'SAR (﷼)',
      'SEK (kr)',
      'SGD (\$)',
      'THB (฿)',
      'TRY (₺)',
      'TWD (NT\$)',
      'USD (\$)',
      'VND (₫)',
      'ZAR (R)',
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              color: const Color(0xFF6387A9),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Text(
                    'Currency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ValueListenableBuilder<Map<String, double>>(
                valueListenable: AppState.exchangeRates,
                builder: (context, rates, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: AppState.currency,
                    builder: (context, activeCurrency, _) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        itemCount: currencies.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                        itemBuilder: (context, index) {
                          final currency = currencies[index];
                          final currencyCode = currency.substring(0, 3);
                          final isSelected = currency == activeCurrency;
                          final rate = rates[currencyCode];
                          
                          return InkWell(
                            onTap: () {
                              AppState.currency.value = currency;
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currency,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF6387A9) : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (rate != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '1 USD = ${rate.toStringAsFixed(2)} $currencyCode',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF059669),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
