import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(text: '${AppState.lowStockThreshold.value}');
    AppState.lowStockThreshold.addListener(_onThresholdStateChanged);
  }

  @override
  void dispose() {
    AppState.lowStockThreshold.removeListener(_onThresholdStateChanged);
    _thresholdController.dispose();
    super.dispose();
  }

  /// Synchronizes the text field with the global [AppState.lowStockThreshold]
  void _onThresholdStateChanged() {
    final stateVal = AppState.lowStockThreshold.value;
    final textVal = int.tryParse(_thresholdController.text) ?? 0;
    if (stateVal != textVal) {
      _thresholdController.text = '$stateVal';
      _thresholdController.selection = TextSelection.fromPosition(
        TextPosition(offset: _thresholdController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No Email';
    final emailParts = email.split('@');
    final emailUsername = emailParts.isNotEmpty ? emailParts[0] : email;
    final emailDomain = emailParts.length > 1 ? '@${emailParts.sublist(1).join('@')}' : '';
    
    final displayName = user?.displayName ?? 'User';
    final firstName = displayName.isNotEmpty ? displayName.split(' ').first : 'User';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

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
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
                children: [
                  Container(
                    height: 128,
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
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF6387A9),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                firstName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      emailUsername,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (emailDomain.isNotEmpty)
                                    Text(
                                      emailDomain,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0),
                    child: Text(
                      'Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                  ),
                  const SizedBox(height: 10),

                  Container(
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
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706), // Amber warning color
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Low Stock',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Alerts when items drop',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        ValueListenableBuilder<int>(
                          valueListenable: AppState.lowStockThreshold,
                          builder: (context, threshold, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: Color(0xFF64748B),
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    if (threshold > 0) {
                                      AppState.lowStockThreshold.value = threshold - 1;
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 52,
                                  child: TextField(
                                    controller: _thresholdController,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) {
                                      final parsed = int.tryParse(value);
                                      if (parsed != null) {
                                        AppState.lowStockThreshold.value = parsed;
                                      } else if (value.isEmpty) {
                                        AppState.lowStockThreshold.value = 0;
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: Color(0xFF6387A9),
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    AppState.lowStockThreshold.value = threshold + 1;
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushNamed(context, '/currency');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_money_rounded,
                                color: Color(0xFF059669), // Emerald Green
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Default Currency',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Set display currency',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              ValueListenableBuilder<String>(
                                valueListenable: AppState.currency,
                                builder: (context, currentCurrency, _) {
                                  return Text(
                                    currentCurrency,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6387A9),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5),
                  ),
                  const SizedBox(height: 10),
                  
                  Container(
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    width: double.infinity,
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          AppState.isManualLogout = true;
                          if (!kIsWeb) await GoogleSignIn().signOut(); // web signs in through Firebase only
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 28, color: Colors.redAccent),
                            SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
