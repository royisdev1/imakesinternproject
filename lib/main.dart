import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_app_imakes/screen/deliveryHome.dart';
import 'package:food_app_imakes/screen/profile_page.dart';
import 'package:get/get.dart';

import 'package:food_app_imakes/auth/chackUserLgin.dart';
import 'package:food_app_imakes/auth_ui/loginScreen.dart';
import 'package:food_app_imakes/auth_ui/signupScreen.dart';
import 'package:food_app_imakes/firebase_options.dart';
import 'package:food_app_imakes/screen/homeScreen.dart';
import 'package:food_app_imakes/screen/hotelownwerHome.dart';
import 'package:food_app_imakes/screen/settings.dart';
import 'package:food_app_imakes/utils/notifications.dart';
import 'package:food_app_imakes/screen/edit_profile_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

//  await NotificationService.instance.initialize();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('STEP 1: Starting initialization...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('STEP 2: Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase init failed: $e');
  }

  if (!kIsWeb) {
    try {
      await NotificationService.instance.initialize();
      print('STEP 3: Notifications initialized!');
    } catch (e) {
      print('❌ Notification init failed: $e');
    }
  }

  print('STEP 4: Running app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFFF3B30), // Red
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF3B30), // Red
          secondary: Color(0xFFFF6A00), // Orange
          surface: Colors.white,
          background: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          ),
        ),
      ),
      //home: const CheckUserLogin(),
      initialRoute: "/",
      routes: {
        "/": (context) => const CheckUserLogin(),
        "/login": (context) => const Loginscreen(),
        "/signup": (context) => const Signupscreen(),
        "/home": (context) => const Home(),
        "/settings": (context) => SettingsScreen(),
        "/editProfile": (context) => EditProfileScreen(),
        "/hotelOwnerHome": (context) => const HotelOwnerHomePage(),
        "/deliveryHome": (context) => const DeliveryHomePage(),
        "/profile": (context) => const ProfilePage(),
        // later: "/adminHome": (context) => const AdminHomePage(),
      },
    );
  }
}
