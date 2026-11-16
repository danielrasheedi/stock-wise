import 'package:flutter/material.dart';
import '../screens/home/home.dart';
import '../screens/inventory/inventory.dart';
import '../screens/history/history.dart';
import '../screens/settings/settings.dart';

/// A stateful widget that acts as the container for the main app tabs
class MainLayout extends StatefulWidget {
  final int tabIndex;
  const MainLayout({super.key, this.tabIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const _tabRoutes = ['/home', '/inventory', '/history', '/settings'];

  final GlobalKey<ItemsScreenState> _itemsScreenKey = GlobalKey<ItemsScreenState>();

  /// Returns the corresponding screen widget based on the active [tabIndex].
  Widget _getScreen() {
    switch (widget.tabIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return ItemsScreen(key: _itemsScreenKey);
      case 2:
        return const HistoryScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.house_rounded, "Home"),
                _buildNavItem(1, Icons.inventory_2_rounded, "Inventory"),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/scanner');
                  },
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.barcode_reader,
                      color: Color(0xFF64748B),
                      size: 28,
                    ),
                  ),
                ),
                _buildNavItem(2, Icons.receipt_long_rounded, "History"),
                _buildNavItem(3, Icons.settings_rounded, "Settings"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int targetIndex, IconData icon, String label) {
    final isSelected = widget.tabIndex == targetIndex;
    final activeColor = const Color(0xFF6387A9);
    final inactiveColor = const Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        if (widget.tabIndex != targetIndex) {
          Navigator.pushReplacementNamed(context, _tabRoutes[targetIndex]);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}