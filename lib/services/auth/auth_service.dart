import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../notifications/notification_service.dart';

class AuthService {
  // instance of auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // instance of firestore
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // sign in
  Future<UserCredential> signInWithEmailPassword(String email, password) async {
    try {
      // sign user in
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // save user info if it doesn't already exist
      _firebaseFirestore.collection('Users').doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
        },
        SetOptions(merge: true),
      );

      // save device token
      NotificationService().setupTokenListeners();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign up
  Future<UserCredential> signUpWithEmailPassword(String email, password) async {
    try {
      // create user
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // save user info in a separate doc
      _firebaseFirestore.collection('Users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      });

      // save device token
      NotificationService().setupTokenListeners();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign out
  Future<void> signOut() async {
    // get current user's ID
    String? userId = _firebaseAuth.currentUser?.uid;
    // to clear the device token
    if (userId != null) {
      await NotificationService().clearTokenOnLogout(userId);
    }

    return await _firebaseAuth.signOut();
  }

  // delete account
  Future<void> deleteAccount() async {
    User? user = getCurrentUser();

    if (user != null) {
      // delete the user's data from firestore
      await _firebaseFirestore.collection('Users').doc(user.uid).delete();

      // delete the user's auth record
      await user.delete();
    }
  }

  // possible error messages
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'Exception: wrong-password':
        return 'The password is incorrect. Please try again.';
      case 'Exception: user-not-found':
        return 'No user found with this email. Please sign up.';
      case 'Exception: invalid-email':
        return 'This email does not exist';
      // Add other cases as needed
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }
}
