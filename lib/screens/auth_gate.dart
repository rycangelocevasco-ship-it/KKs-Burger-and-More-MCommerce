
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;

import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';
import 'admin/admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Authentication error.')),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return RoleGate(user: user);
      },
    );
  }
}

class RoleGate extends StatelessWidget {
  final User user;

  const RoleGate({
    super.key,
    required this.user,
  });

  Future<rtdb.DataSnapshot> checkRealtimeDatabase() async {
    final database = rtdb.FirebaseDatabase.instance;

    return await database
        .ref()
        .child('users')
        .child(user.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, firestoreSnapshot) {
        if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (firestoreSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Firestore Error:\n${firestoreSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // CHECK FIRESTORE FIRST
        if (firestoreSnapshot.hasData &&
            firestoreSnapshot.data!.exists) {
          final data = firestoreSnapshot.data!.data();

          final role = data?['role']
              ?.toString()
              .trim()
              .toLowerCase();

          debugPrint('ACCOUNT CHECK');
          debugPrint('Email: ${user.email}');
          debugPrint('UID: ${user.uid}');
          debugPrint('Role: $role');

          if (role == 'admin') {
            return const AdminDashboard();
          }

          if (role == 'customer') {
            return const MainScreen();
          }
        }

        // IF NO FIRESTORE DOCUMENT, CHECK REALTIME DATABASE
        return FutureBuilder<rtdb.DataSnapshot>(
          future: checkRealtimeDatabase(),
          builder: (context, databaseSnapshot) {
            if (databaseSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (databaseSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Realtime Database Error:\n'
                      '${databaseSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            if (databaseSnapshot.hasData &&
                databaseSnapshot.data!.exists) {
              debugPrint('CUSTOMER ACCOUNT FOUND');
              debugPrint('Email: ${user.email}');
              debugPrint('UID: ${user.uid}');
              debugPrint('Database: Realtime Database');

              return const MainScreen();
            }

            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(
                    'ACCOUNT PROFILE NOT FOUND\n\n'
                    'Email: ${user.email}\n\n'
                    'UID: ${user.uid}\n\n'
                    'Checked Firestore and Realtime Database.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
