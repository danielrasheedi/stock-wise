import 'package:flutter/material.dart';

enum SortOrder { ascending, descending, newest, oldest }

void showSortActionModal(
  BuildContext context, {
  required SortOrder currentSort,
  required Function(SortOrder) onSortSelected,
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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort Inventory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
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
              icon: Icons.calendar_month_rounded,
              label: 'Newest to Oldest',
              description: 'Show the most recently created first',
              color: const Color(0xFF6387A9),
              isSelected: currentSort == SortOrder.newest,
              onTap: () {
                Navigator.pop(context);
                onSortSelected(SortOrder.newest);
              },
            ),

            _buildModalItem(
              icon: Icons.calendar_month_rounded,
              label: 'Oldest to Newest',
              description: 'Show the oldest created first',
              color: const Color(0xFF6387A9),
              isSelected: currentSort == SortOrder.oldest,
              onTap: () {
                Navigator.pop(context);
                onSortSelected(SortOrder.oldest);
              },
            ),

            _buildModalItem(
              icon: Icons.sort_by_alpha_rounded,
              label: 'Alphabetical (A - Z)',
              description: 'Sort alphabetically from A to Z',
              color: const Color(0xFF6387A9),
              isSelected: currentSort == SortOrder.ascending,
              onTap: () {
                Navigator.pop(context);
                onSortSelected(SortOrder.ascending);
              },
            ),

            _buildModalItem(
              icon: Icons.sort_by_alpha_rounded,
              label: 'Alphabetical (Z - A)',
              description: 'Sort alphabetically from Z to A',
              color: const Color(0xFF6387A9),
              isSelected: currentSort == SortOrder.descending,
              onTap: () {
                Navigator.pop(context);
                onSortSelected(SortOrder.descending);
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
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: color, size: 28),
    title: Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? color : const Color(0xFF1E293B),
      ),
    ),
    subtitle: Text(
      description,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF64748B),
      ),
    ),
    trailing: isSelected 
        ? Icon(Icons.check_circle_rounded, color: color, size: 24)
        : null,
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
  );
}
