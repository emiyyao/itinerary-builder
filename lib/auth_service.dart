import 'dart:developer';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<UserCredential?> loginWithGoogle()async {
    try{
      final googleUser = await GoogleSignIn().signIn();

      final googleAuth = await googleUser?.authentication;

      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth?.idToken,
        accessToken: googleAuth?.accessToken,
      );

      return await _auth.signInWithCredential(cred);
    } catch (e) {
      return Future.error("Failed to sign in with Google: $e");
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      return Future.error(exceptionHandler(e.code));
    } catch (e) {
      return Future.error("Something went wrong: $e");
    }
  }

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      return Future.error(exceptionHandler(e.code));
    } catch (e) {
      return Future.error("Something went wrong: $e");
    }
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      return Future.error("Failed to sign out: $e");
    }
  }
}

String exceptionHandler(String code) {
  switch (code) {
    case "invalid-credential":
      return "Your login credentials are invalid";
    case "weak-password":
      return "Your password must be at least 6 characters";
    case "email-already-in-use":
      return "User already exists";
    default:
      return "Something went wrong";
  }
}