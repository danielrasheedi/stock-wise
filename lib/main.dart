import 'package:flutter/material.dart';
import 'widgets/bottom_navigation.dart';
import 'screens/barcode/scanner.dart';
import 'screens/inventory/item.dart';
import 'screens/inventory/stock_in.dart';
import 'screens/inventory/stock_out.dart';
import 'screens/settings/currency.dart';
import 'screens/auth/login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';

/// Starting point of the application execution
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppState.loadExchangeRates();
  await AppState.loadDailyCounters();
  runApp(const MyApp());
}

/// The root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Wise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6387A9)),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
            TargetPlatform.macOS: NoTransitionsBuilder(),
            TargetPlatform.windows: NoTransitionsBuilder(),
            TargetPlatform.linux: NoTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const MainLayout(tabIndex: 0);
            }
            // User is logged out (either manually or deleted from Firebase)
            if (!AppState.isManualLogout) {
              AppState.reset();
            }
            return const LoginScreen();
          },
        ),
        '/home': (context) => const MainLayout(tabIndex: 0),
        '/inventory': (context) => const MainLayout(tabIndex: 1),
        '/scanner': (context) => const ScannerScreen(),
        '/history': (context) => const MainLayout(tabIndex: 2),
        '/settings': (context) => const MainLayout(tabIndex: 3),
        '/item': (context) => const ItemScreen(),
        '/stock-in': (context) => const StockInScreen(),
        '/stock-out': (context) => const StockOutScreen(),
        '/currency': (context) => const CurrencyScreen(),
      },
    );
  }
}

/// A custom page transition builder that disables all transition animations globally.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}