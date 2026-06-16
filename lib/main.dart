import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:wedding_invite/firebase_options.dart';
import 'package:wedding_invite/notifications/notification_service.dart';
import 'package:wedding_invite/router/router_provider.dart';
// Import the new router file

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep empty unless you need Firebase work here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (make sure you have your firebase_options.dart file)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init(
    onNotificationTap: NotificationService.instance.cacheTapData,
  );

  // NOTE: Uncomment the Firebase initialization when ready.

  runApp(const ProviderScope(child: WeddingPlannerApp()));
}

class WeddingPlannerApp extends ConsumerWidget {
  const WeddingPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final colorSeed = const Color(0xFFB0773B);

    return ScreenUtilInit(
      // 👇 IMPORTANT: match your design reference device
      // If your designs are based on iPhone 14/15 Pro Max → 430x932
      // If iPhone 13 → 390x844
      designSize: const Size(430, 932),

      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        return MaterialApp.router(
          title: 'Wedding Admin',
          debugShowCheckedModeBanner: false,

          // 🔒 Stabilize text scaling (WebView-safe)
          builder: (context, widget) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
              child: widget!,
            );
          },

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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18.w,
                vertical: 14.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Color(0xFFE4D4C4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Color(0xFFE4D4C4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: colorSeed.withOpacity(0.9),
                  width: 1.4.w,
                ),
              ),
              labelStyle: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF7B6A5A),
              ),
            ),
          ),

          routerConfig: router,
        );
      },
    );
  }
}
