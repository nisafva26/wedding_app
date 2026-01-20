import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wedding_invite/feature/auth/screens/intro_screen.dart';
import 'package:wedding_invite/feature/auth/screens/login_screen.dart';
import 'package:wedding_invite/feature/auth/screens/onboarding_screen.dart';
import 'package:wedding_invite/feature/auth/screens/success_screen.dart';
import 'package:wedding_invite/feature/auth/screens/user_details_screen.dart';
import 'package:wedding_invite/feature/guest_list/screens/master_guest_list_screen.dart';
import 'package:wedding_invite/feature/invite/screens/invite_screen.dart';
import 'package:wedding_invite/feature/profile/screens/profile_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/screens/event_details_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/add_event_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/admin_home_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/create_wedding_screen.dart';
import 'package:wedding_invite/feature/wedding_admin/presentation/wedding_details_screen.dart';
import 'package:wedding_invite/main_screen.dart';
import 'package:wedding_invite/version_1/dashbaord/screens/user_dashborad_screen.dart';

// --- Shared State Providers (from your code) ---

// 0) Guest toggle (not used in this final flow, but kept for context)
final isGuestProvider = StateProvider<bool>((_) => false);

// 1) Firebase auth state
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// 2) Has seen onboarding (placeholder, always true for now)
// final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
//   // In a real app, this would use SharedPreferences
//   await Future.delayed(const Duration(milliseconds: 100));
//   return true;
// });

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
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;
  // final uid = user?.uid;

  //-----init screen------
  final hasSeenInitAsync = ref.watch(hasSeenInitProvider);
  final hasSeenInit = hasSeenInitAsync.asData?.value ?? false;

  final hasSeenOnboardingAsync = ref.watch(hasSeenOnboardingProvider);
  final hasSeenOnboarding = hasSeenOnboardingAsync.asData?.value ?? false;
  // final hasSeenOnboarding =  false;

  final justLoggedIn = ref.watch(justLoggedInProvider); // 👈 add this

  // Placeholder: Simulate UserDoc check. Replace with your actual logic if needed.
  // We'll skip complex userDoc logic for this core implementation.
  // final userDocExists = true;
  // final userDoc = uid != null
  //     ? ref.watch(userDataProvider(uid)).asData?.value
  //     : null;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/', // Start at Login
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final loc = state.uri.toString();
      log('loc : $loc');
      final onOnboarding = loc.startsWith('/onboarding');
      final onLogin = loc == '/';
      final onUserDetails = loc.startsWith('/user-details');
      final onSuccess = loc.startsWith('/success');
      final onInit = loc.startsWith('/init');

      log('on login ? $onLogin , onboarding ? $onOnboarding');

      // // 1) First-launch → onboarding
      // if (!hasSeenOnboarding && !onOnboarding) {
      //   return '/onboarding';
      // }

      // 0) First launch flow (2-step)
      if (!hasSeenInit && !onInit) {
        return '/init';
      }
      if (hasSeenInit && !hasSeenOnboarding && !onOnboarding) {
        return '/onboarding';
      }

      // 2) Not logged in
      if (user == null) {
        if (onOnboarding) return null; // Allow onboarding
        if (onLogin) return null; // Allow login
        return '/'; // Force login
      }

      if (onSuccess) {
        return null;
      }

      // 4) Logged in & we're on "/" (login)
      if (onLogin) {
        // If this navigation is right after login, go to /success instead of /home
        if (justLoggedIn) {
          return '/success';
        }
        // Normal logged-in navigation → home
        return '/home';
      }

      // 5) Leave /user-details alone, SuccessScreen will decide when to go there.
      // If you want to prevent logged-in users from manually going to onboarding:
      if (onOnboarding) {
        return '/home';
      }

      // // 4) Logged in: keep them off login/onboarding/user-details
      // if (onLogin || onOnboarding) {
      //   return '/home';
      // }

      return null;
    },

    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(),
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
        pageBuilder: (c, s) =>
            const NoTransitionPage(child: UserDashboardScreen()),
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
      //   path: '/home',
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
