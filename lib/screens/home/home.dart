import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Generates a formatted date string for the current day
  TextSpan _getFormattedDateSpan() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return TextSpan(
      children: [
        TextSpan(
          text: "${now.day} ${months[now.month - 1]} ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: "${now.year}",
          style: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ],
    );
  }

  /// A helper method to build a row displaying a metric
  Widget _buildBorderlessRow({
    required String label,
    required ValueNotifier<int> valueNotifier,
    Color? valueColor,
    double topPadding = 14.0,
    double bottomPadding = 14.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: valueNotifier,
            builder: (context, val, _) {
              return Text(
                '$val',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF1E293B),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              color: const Color(0xFF6387A9),
              child: const Center(
                child: Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        height: 128,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Opacity(
                              opacity: 0.0,
                              child: Text.rich(
                                _getFormattedDateSpan(),
                                style: const TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: AppState.dailyStockIn,
                                  builder: (context, stockInVal, _) {
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: -48,
                                          child: Text.rich(
                                            _getFormattedDateSpan(),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.download_rounded, 
                                              color: Colors.green, 
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Stock In',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '$stockInVal',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                ),
                                
                                Container(
                                  width: 1.5,
                                  height: 32,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                
                                ValueListenableBuilder<int>(
                                  valueListenable: AppState.dailyStockOut,
                                  builder: (context, stockOutVal, _) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.upload_rounded, 
                                          color: Colors.orange, 
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Stock Out',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$stockOutVal',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5, height: 1),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
                      child: Column(
                        children: [
                          _buildBorderlessRow(
                            label: 'Low Stock',
                            valueNotifier: AppState.lowStockItemsCount,
                            valueColor: Colors.orange,
                            topPadding: 0.0,
                            bottomPadding: 14.0,
                          ),
                          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
                          _buildBorderlessRow(
                            label: 'Out of Stock',
                            valueNotifier: AppState.outOfStockItemsCount,
                            valueColor: Colors.redAccent,
                            topPadding: 14.0,
                            bottomPadding: 14.0,
                          ),
                          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
                          _buildBorderlessRow(
                            label: 'Folders',
                            valueNotifier: AppState.totalFolders,
                            topPadding: 14.0,
                            bottomPadding: 14.0,
                          ),
                          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
                          _buildBorderlessRow(
                            label: 'Total Items',
                            valueNotifier: AppState.totalItems,
                            topPadding: 14.0,
                            bottomPadding: 0.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
