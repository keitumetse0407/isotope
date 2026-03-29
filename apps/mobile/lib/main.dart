// ISOTOPE v2.0 — Main Entry Point
// AI-Powered Gold Trading Signals for South Africa
// Built by Elkai | ELEV8 DIGITAL

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/upgrade_screen.dart';
import 'screens/admin_dashboard.dart';
import 'services/auth_service.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (for auth and notifications)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase not configured yet - app will still work with limited features
    debugPrint('Firebase initialization skipped: $e');
  }

  runApp(const IsotopeApp());
}

class IsotopeApp extends StatelessWidget {
  const IsotopeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'ISOTOPE',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/upgrade': (context) => UpgradeScreen(userId: ''),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.amber,
      scaffoldBackgroundColor: const Color(0xFF0A0E21),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: const Color(0xFF13172F),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: const Color(0xFF13172F),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber,
          side: const BorderSide(color: Colors.amber),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Bottom Navigation Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF13172F),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF13172F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: Colors.amber,
        secondary: Colors.amberAccent,
        surface: Color(0xFF13172F),
        error: Colors.red,
      ),
    );
  }
}

// ============================================
// AUTH WRAPPER
// ============================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Check if user is logged in
    if (authService.isLoggedIn && authService.currentUser != null) {
      // Admin users go straight to admin dashboard
      if (authService.isAdmin) {
        return AdminDashboard(
          admin: authService.adminUser!,
        );
      }
      
      // Regular users go to home screen
      return HomeScreen(user: authService.currentUser);
    }

    return const OnboardingScreen();
  }
}
