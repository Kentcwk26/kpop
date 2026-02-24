import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kpop/404.dart';
import 'package:kpop/adminstrator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'about.dart';
import 'home.dart';
import 'login.dart';
import 'notification.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'widgets/app_drawer.dart';

Future<void> requestAndroidNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.showNotification(
    id: message.hashCode,
    title: message.notification?.title ?? 'No Title',
    body: message.notification?.body ?? 'No Body',
    payload: message.data['payload'] ?? '',
  );
}

Future<void> _setupFCM() async {
  if (kIsWeb) return;

  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await messaging.getToken();
    print("🎫 FCM TOKEN: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NotificationService.showNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'No Body',
        payload: message.data['payload'] ?? '',
      );
    });

    print("✅ FCM setup completed");
  } catch (e) {
    print("❌ FCM setup error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  await requestAndroidNotificationPermission();
  await _setupFCM();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K-Hub',
      theme: _buildTheme(themeState),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const GoogleSignInPage(),
        '/home': (context) => const HomeScreen(),
        '/about': (context) => const AboutScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        '/terms-and-conditions': (context) => const TermsOfServiceScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => ErrorScreen(routeName: settings.name),
        );
      },
    );
  }

  ThemeData _buildTheme(ThemeState themeState) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: themeState.scaffoldBackgroundColor,
      primaryColor: themeState.primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: themeState.appBarColor,
        foregroundColor: _getContrastColor(themeState.appBarColor),
        elevation: 0,
        iconTheme: IconThemeData(
          color: _getContrastColor(themeState.appBarColor),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: themeState.primaryColor,
        onPrimary: _getContrastColor(themeState.primaryColor),
        secondary: themeState.secondaryColor,
        onSecondary: _getContrastColor(themeState.secondaryColor),
        background: themeState.scaffoldBackgroundColor,
        surface: themeState.scaffoldBackgroundColor,
        onBackground: _getContrastColor(themeState.scaffoldBackgroundColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeState.primaryColor,
          foregroundColor: _getContrastColor(themeState.primaryColor),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: themeState.scaffoldBackgroundColor,
        unselectedLabelColor: _getContrastColor(
          themeState.scaffoldBackgroundColor,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: themeState.primaryColor, width: 2.0),
          ),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: themeState.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _getContrastColor(themeState.scaffoldBackgroundColor),
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: _getContrastColor(
            themeState.scaffoldBackgroundColor,
          ).withOpacity(0.8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: themeState.primaryColor,
        foregroundColor: _getContrastColor(themeState.primaryColor),
      ),
      cardTheme: CardThemeData(
        color: _getCardColor(themeState.scaffoldBackgroundColor),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: themeState.scaffoldBackgroundColor,
        selectedItemColor: themeState.primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  Color _getCardColor(Color backgroundColor) {
    double luminance = backgroundColor.computeLuminance();
    if (luminance > 0.8) return Colors.white;
    if (luminance < 0.2) return Colors.grey;
    return backgroundColor.withOpacity(0.9);
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserRoleAndNavigate();
  }

  Future<void> _checkUserRoleAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GoogleSignInPage()),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (!doc.exists || doc.data()?['role'] == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    final role = doc.data()!['role'] as String;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminstratorScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            CircularProgressIndicator(),
            Text('Loading...')
          ],
        )
      ),
    );
  }
}