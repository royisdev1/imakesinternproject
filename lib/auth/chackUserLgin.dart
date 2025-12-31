import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_app_imakes/auth_ui/loginScreen.dart';
import 'package:food_app_imakes/screen/homeScreen.dart';
import 'package:food_app_imakes/screen/hotelownwerHome.dart';
import 'package:food_app_imakes/screen/deliveryHome.dart';
// import 'package:food_app_imakes/screen/adminHome.dart';

class CheckUserLogin extends StatefulWidget {
  const CheckUserLogin({super.key});

  @override
  State<CheckUserLogin> createState() => _CheckUserLoginState();
}

class _CheckUserLoginState extends State<CheckUserLogin> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  /// ✅ Check user login and navigate based on role
  Future<void> _checkUserAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Loginscreen()),
        );
      });
      return;
    }

    String? role;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users") // this matches your DB
          .doc(user.uid)
          .get();

      if (snapshot.exists && snapshot.data()?["role"] != null) {
        role = snapshot.data()?["role"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("role_${user.uid}", role!);
      }
    } catch (e) {
      debugPrint("Firestore fetch failed: $e");
    }

    if (role == null) {
      final prefs = await SharedPreferences.getInstance();
      role = prefs.getString("role_${user.uid}");
    }

    if (!mounted) return;

    // ✅ Navigate safely after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (role) {
        case "hotelOwner":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HotelOwnerHomePage()),
          );
          break;
        case "admin":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Admin Home Placeholder")),
              ),
            ),
          );
          break;
        case "delivery":
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DeliveryHomePage()),
          );
          break;
        default:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
      }
    });
  }

  /// ✅ Always refresh from Firestore on login
  Future<String?> _getUserRole(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (snapshot.exists) {
        final role = snapshot.data()?["role"];
        if (role != null) {
          // Update cache with fresh role
          await prefs.setString("role_$uid", role);
          return role;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Firestore role fetch failed: $e");
    }

    // 🔄 Fallback to cache if Firestore fails
    return prefs.getString("role_$uid");
  }

  @override
  Widget build(BuildContext context) {
    // Show loading until navigation happens
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
