import 'package:flutter/material.dart';

void showItemActionModal(
  BuildContext context, {
  required String itemName,
  required VoidCallback onEditDetails,
  required VoidCallback onStockIn,
  required VoidCallback onStockOut,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
            ),
            const SizedBox(height: 8),

            _buildModalItem(
              icon: Icons.edit_note_rounded,
              label: 'Edit Details',
              description: 'Modify name, pricing and more',
              color: const Color(0xFF6387A9), // Matches our dusty pastel blue
              onTap: () {
                Navigator.pop(context);
                onEditDetails();
              },
            ),

            _buildModalItem(
              icon: Icons.download_rounded,
              label: 'Stock In',
              description: 'Increase quantity of an existing item',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                onStockIn();
              },
            ),

            _buildModalItem(
              icon: Icons.upload_rounded,
              label: 'Stock Out',
              description: 'Decrease quantity of an existing item',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                onStockOut();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

Widget _buildModalItem({
  required IconData icon,
  required String label,
  required String description,
  required Color color,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: color, size: 28),
    title: Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    ),
    subtitle: Text(
      description,
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF64748B),
      ),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
  );
}
