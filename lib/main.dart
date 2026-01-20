import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wedding_invite/firebase_options.dart';
import 'package:wedding_invite/router/router_provider.dart';
// Import the new router file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (make sure you have your firebase_options.dart file)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // NOTE: Uncomment the Firebase initialization when ready.

  runApp(const ProviderScope(child: WeddingPlannerApp()));
}

class WeddingPlannerApp extends ConsumerWidget {
  const WeddingPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter provider
    final router = ref.watch(goRouterProvider);
        final colorSeed = const Color(0xFFB0773B);

    return MaterialApp.router(
      title: 'Wedding Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorSeed,
          background: const Color(0xFFF4EEE6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4EEE6),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF2E2A27),
              displayColor: const Color(0xFF2E2A27),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFAF5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE4D4C4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE4D4C4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: colorSeed.withOpacity(0.9), width: 1.4),
          ),
          labelStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF7B6A5A),
          ),
        ),
      ),
      routerConfig: router, // Use the GoRouter config
    );
  }

  // Theme data remains the same
  ThemeData _buildThemeData() {
    const primaryColor = Color(0xFFC06A78);
    const accentColor = Color(0xFF5C3C3C);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: const Color(0xFFFFF8F3),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFF8F3),
      textTheme: const TextTheme(
        // ... (Text styles remain the same)
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          color: accentColor,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w800,
          color: accentColor,
        ),
      ),
      // ... (InputDecorationTheme and FilledButtonThemeData remain the same)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE3D3C5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE3D3C5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8A6A60)),
        hintStyle: TextStyle(color: const Color(0xFFB08C82).withOpacity(0.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
