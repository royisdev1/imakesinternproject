import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthserviceHelper {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  // ✅ Create account with extra details + role
  static Future<String> createAccountWithEmail(
    String email,
    String password, {
    required String name,
    required String mobileNumber,
    required String address,
    String role = "user", // default role
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save extra details in Firestore
      await _firestore.collection("users").doc(userCred.user!.uid).set({
        "uid": userCred.user!.uid,
        "email": email,
        "name": name,
        "mobileNumber": mobileNumber,
        "address": address,
        "role": role,
        "createdAt": DateTime.now(),
      });

      return "Account created successfully";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ Login
  static Future<String> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Login Successful";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ Logout
  static Future logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      return e.toString();
    }
  }

  // ✅ Check if user already logged in
  static Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  // ✅ Update password (requires reauth)
  static Future<String> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "No user logged in";

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return "Password updated successfully";
    } catch (e) {
      return "Error updating password: $e";
    }
  }

  // ✅ Update user details in Firestore
  static Future<String> updateUserDetails({
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "No user logged in";

      await _firestore.collection("users").doc(user.uid).update({
        "name": name,
        "mobileNumber": mobileNumber,
        "address": address,
      });

      return "User details updated successfully";
    } catch (e) {
      return "Error updating details: $e";
    }
  }

  // ✅ Get user role
  static Future<String?> getUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot snap = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      return snap["role"];
    } catch (e) {
      return null;
    }
  }
}
