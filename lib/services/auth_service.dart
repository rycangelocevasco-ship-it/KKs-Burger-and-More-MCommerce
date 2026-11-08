
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as firebase_database;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  firebase_database.DatabaseReference get _root =>
      firebase_database.FirebaseDatabase.instance.ref();

  Stream<User?> get authChanges => _auth.authStateChanges();

  // LOGIN USING USERNAME
  Future<void> signIn(String username, String password) async {
    final usernameLower = username.trim().toLowerCase();

    if (usernameLower.isEmpty) {
      throw Exception('Please enter your username.');
    }

    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }

    try {
      final lookupSnapshot =
          await _root.child('usernameLookup').child(usernameLower).get();

      if (!lookupSnapshot.exists || lookupSnapshot.value == null) {
        throw Exception('Incorrect username.');
      }

      final email = lookupSnapshot.value.toString();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw Exception('Incorrect password.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many attempts. Please try again later.');
        case 'network-request-failed':
          throw Exception('Please check your internet connection.');
        default:
          throw Exception('Login failed. Please try again.');
      }
    }
  }

  // REGISTER NEW ACCOUNT
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanUsername = username.trim();
    final usernameLower = cleanUsername.toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    final usernameRef =
        _root.child('usernameLookup').child(usernameLower);

    final existingUsername = await usernameRef.get();

    if (existingUsername.exists) {
      throw Exception('Username is already taken. Please choose another.');
    }

    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Unable to create account.');
    }

    final user = credential.user;

    if (user == null) {
      throw Exception('Account creation failed. Please try again.');
    }

    try {
      final transaction = await usernameRef.runTransaction((currentData) {
        if (currentData != null) {
          return firebase_database.Transaction.abort();
        }

        return firebase_database.Transaction.success(cleanEmail);
      });

      if (!transaction.committed) {
        throw Exception('Username is already taken.');
      }

      // SAVE USER PROFILE TO CLOUD FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': cleanName,
        'username': cleanUsername,
        'usernameLower': usernameLower,
        'email': cleanEmail,
        'phone': '',
        'address': '',
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await usernameRef.remove();

      if (_auth.currentUser?.uid == user.uid) {
        await user.delete();
      }

      rethrow;
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
