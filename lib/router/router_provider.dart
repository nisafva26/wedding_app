import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'package:wedding_invite/feature/auth/screens/intro_screen.dart';
import 'package:wedding_invite/feature/auth/screens/login_screen.dart';
import 'package:wedding_invite/feature/auth/screens/onboarding_screen.dart';
import 'package:wedding_invite/feature/auth/screens/success_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/screens/event_details_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/add_event_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/create_wedding_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/wedding_details_screen.dart';
import 'package:wedding_invite/version_1/admin/screens/admin_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/user_dashborad_screen.dart';
import 'package:wedding_invite/version_2/screens/wedding_dashboard_screen.dart';

// --- Shared State Providers (from your code) ---

// 0) Guest toggle (not used in this final flow, but kept for context)
final isGuestProvider = StateProvider<bool>((_) => false);

// 1) Firebase auth state
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final isRsvpedForThisWeddingProvider = StateProvider<bool>((_) => false);

// 3) User doc (profile gate) – placeholder for data check
final userDataProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>?, String>(
      (ref, uid) =>
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
    );

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_seen_onboarding') ?? false;
});

final hasSeenInitProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_seen_init') ?? false;
});

// --- GoRouter Setup ---

final rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch all necessary states
  final authAsync = ref.watch(authStateProvider);
  final initAsync = ref.watch(hasSeenInitProvider);
  final onboardingAsync = ref.watch(hasSeenOnboardingProvider);
  final isGuest = ref.watch(isGuestProvider);
  // final isRsvpedForThisWedding =
  //   ref.read(isRsvpedForThisWeddingProvider);

  return GoRouter(
    initialLocation: '/splash', // Start at splash to wait for data
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),

    redirect: (context, state) {
      // 1. Log the Loading States
      print('--- ROUTER REDIRECT ---');
      print(
        'Loading States -> Auth: ${authAsync.isLoading}, Init: ${initAsync.isLoading}, Onboard: ${onboardingAsync.isLoading}',
      );

      if (authAsync.isLoading ||
          initAsync.isLoading ||
          onboardingAsync.isLoading) {
        print('Redirecting to: /splash (Waiting for data)');
        return '/splash';
      }

      // 2. Log the values
      final user = authAsync.value;
      final isGuest = ref.read(isGuestProvider); // Log this!
      final hasSeenInit = initAsync.value ?? false;
      final hasSeenOnboarding = onboardingAsync.value ?? false;
      final loc = state.uri.path;

      final isRsvpedForThisWedding = ref.read(isRsvpedForThisWeddingProvider);

      print(
        'State Values -> User: ${user?.uid}, isGuest: $isGuest, hasSeenInit: $hasSeenInit, hasSeenOnboarding: $hasSeenOnboarding',
      );
      print('Current Loc: $loc');

      // 3. Log the decision logic
      if (!hasSeenInit) {
        final target = loc == '/init' ? null : '/init';
        print('Decision: Intro not seen. Target: $target');
        return target;
      }

      // if (!hasSeenOnboarding) {
      //   final target = loc == '/onboarding' ? null : '/onboarding';
      //   print('Decision: Onboarding not seen. Target: $target');
      //   return target;
      // }

      // 3. Wedding-specific onboarding ONLY
      // if (isRsvpedForThisWedding && !hasSeenOnboarding) {
      //   return loc == '/onboarding' ? null : '/onboarding';
      // }

      if (user == null && !isGuest) {
        final target = loc == '/' ? null : '/';
        print('Decision: No User & Not Guest. Target: $target');
        return target;
      }

      // This is where you might be stuck
      if ((loc == '/' || loc == '/splash') && (user != null || isGuest)) {
        print(
          'Decision: Authenticated/Guest found on Login/Splash. Target: /home',
        );
        return '/home';
      }

      print('Decision: No redirect needed (returning null)');
      return null;
    },

    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(),
      ),

      GoRoute(
        path: '/splash',
        builder: (context, state) => Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  child: LoadingIndicator(
                    indicatorType:
                        Indicator.ballScaleMultiple, // Soft pulsing circles
                    colors: [
                      const Color(0xFF06471D), // Your deep green
                      const Color(0xFF8B2B57), // Your badge pink
                    ],
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      GoRoute(
        path: '/init',
        builder: (context, state) => const RsvpIntroScreen(),
      ),

      // Login (Initial route)
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),

      // Post-login success/redirect handler
      GoRoute(
        path: '/success',
        builder: (context, state) => const SuccessScreen(),
      ),

      // Collect minimal user data
      // GoRoute(
      //   path: '/user-details',
      //   builder: (context, state) => const UserDetailsScreen(),
      // ),
      GoRoute(
        path: '/wedding/:weddingId',
        pageBuilder: (context, state) {
          final weddingId = state.pathParameters['weddingId']!;
          return NoTransitionPage(
            child: WeddingDetailsScreen(weddingId: weddingId),
          );
        },
      ),

      GoRoute(
        path: '/home',
        pageBuilder: (c, s) => NoTransitionPage(
          child: UpgradeAlert(
            dialogStyle: UpgradeDialogStyle.cupertino, // iOS-style dialog

            upgrader: Upgrader(
              countryCode: 'in',
              debugLogging: false,
              debugDisplayAlways: false, // for testing – show every time
              // remove minAppVersion for now, keep it simple
            ),

            showIgnore: false,
            showLater: false,
            child: UserDashboardScreen(),
            // child: WeddingDashboardScreen(),
          ),
        ),
        routes: [
          // Deep sub-routes mounted under /home if you prefer
        ],
      ),

      // // Persistent bottom bar
      // ShellRoute(
      //   // navigatorKey: shellNavigatorKey,
      //   builder: (context, state, child) {
      //     // final user = ref.watch(currentUserProvider).value;
      //     // final isAdmin = user?.isAdmin == true;
      //     return MainScreen(child: child);
      //   },

      //   routes: [
      //     GoRoute(
      //       path: '/home',
      //       pageBuilder: (c, s) =>
      //           const NoTransitionPage(child: UserDashboardScreen()),
      //       routes: [
      //         // Deep sub-routes mounted under /home if you prefer
      //       ],
      //     ),

      //     // in your router
      //     GoRoute(
      //       path: '/guest-list',
      //       name: 'masterGuestList',
      //       pageBuilder: (context, state) =>
      //           const NoTransitionPage(child: MasterGuestListScreen()),
      //     ),
      //     GoRoute(
      //       path: '/invite',
      //       pageBuilder: (c, s) =>
      //           const NoTransitionPage(child: InviteOverviewScreen()),
      //     ),
      //     GoRoute(
      //       path: '/profile',
      //       pageBuilder: (c, s) =>
      //           const NoTransitionPage(child: ProfileScreen()),
      //     ),
      //   ],
      // ),
      GoRoute(
        path: '/wedding/:weddingId/event/:eventId',
        builder: (context, state) {
          final weddingId = state.pathParameters['weddingId']!;
          final event = state.extra as Event;
          return EventDetailsScreen(weddingId: weddingId, event: event);
        },
      ),

      // Main application screen (Home is the AdminHomeScreen)
      // GoRoute(
      //   path: '/admin',
      //   builder: (context, state) => const AdminHomeScreen(),
      // ),
      GoRoute(
        path: '/create-wedding',
        builder: (context, state) => const CreateWeddingScreen(),
      ),
      GoRoute(
        path: '/add-event/:weddingId',
        builder: (context, state) {
          final weddingId = state.pathParameters['weddingId']!;
          return AddEventScreen(weddingId: weddingId);
        },
      ),

      // You can add other routes here if needed (e.g., /admin, /profile)
    ],
  );
});
