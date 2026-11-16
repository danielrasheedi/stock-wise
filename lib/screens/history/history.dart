import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utilities/database.dart';
import '../../state/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Formats a [DateTime] object into a string
  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "Today at ${_formatTime(dt)}";
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day && dt.month == yesterday.month && dt.year == yesterday.year) {
      return "Yesterday at ${_formatTime(dt)}";
    }
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${dt.day} ${months[dt.month - 1]} at ${_formatTime(dt)}";
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? "PM" : "AM";
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  /// Customizes the icon and colors based on the action type
  Widget _buildHistoryCard(HistoryEntry entry) {
    IconData icon;
    Color iconColor;
    String descriptionPrefix;
    String? quantityText;
    Color? quantityColor;

    switch (entry.actionType) {
      case 'add_item':
        icon = Icons.add_box_rounded;
        iconColor = const Color(0xFF0284C7); // Sky Blue
        descriptionPrefix = "Added ";
        quantityText = entry.quantity != null && entry.quantity! > 0 ? "+${entry.quantity}" : null;
        quantityColor = const Color(0xFF0284C7);
        break;
      case 'stock_in':
        icon = Icons.download_rounded;
        iconColor = const Color(0xFF059669); // Emerald Green
        descriptionPrefix = "Stocked In ";
        quantityText = "+${entry.quantity ?? 0}";
        quantityColor = const Color(0xFF059669);
        break;
      case 'stock_out':
        icon = Icons.upload_rounded;
        iconColor = const Color(0xFFD97706); // Amber Orange
        descriptionPrefix = "Stocked Out ";
        quantityText = "-${entry.quantity ?? 0}";
        quantityColor = const Color(0xFFD97706);
        break;
      case 'delete_item':
        icon = Icons.delete_outline_rounded;
        iconColor = const Color(0xFFE11D48); // Rose Red
        descriptionPrefix = "Deleted ";
        quantityText = null;
        quantityColor = null;
        break;
      default:
        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF64748B);
        descriptionPrefix = "Action on ";
        quantityText = null;
        quantityColor = null;
    }

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Roboto',
                      ),
                      children: [
                        TextSpan(
                          text: descriptionPrefix,
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: entry.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(entry.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (quantityText != null)
            Text(
              quantityText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: quantityColor,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                  'History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: Database.userDoc.collection('history').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final historyList = snapshot.data!.docs;

                  if (historyList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history_toggle_off_rounded,
                                color: Color(0xFF94A3B8),
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Activity Logged',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Any updates to items like stock in, stock out, additions, and deletions will show up here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final doc = historyList[index].data() as Map<String, dynamic>;
                      final entry = HistoryEntry(
                        id: historyList[index].id,
                        actionType: doc['actionType'] ?? 'unknown',
                        itemName: doc['itemName'] ?? 'Unknown Item',
                        quantity: doc['quantity'] as int?,
                        timestamp: ((doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()).toUtc().add(const Duration(hours: 8)),
                      );
                      return _buildHistoryCard(entry);
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
