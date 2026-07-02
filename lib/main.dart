// lib/main.dart
//
// CHANGE vs your current file:
//   - Added flutter_stripe import + Stripe.publishableKey init.
//   - Replace 'pk_test_XXXX...' below with YOUR actual publishable key
//     (safe to hardcode — it's meant to be public).

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:greenhub/app/app.dart';
import 'firebase_options.dart';
// import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check with debug provider for development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.deviceCheck,
  );

  // Initialize Stripe — publishable key only, this is safe to keep in code.
  Stripe.publishableKey =
      'pk_test_51ToZ04GREhCjOb1n9hggOBI36X4hviVAFFMVtXWtUsNjjg3O2s7JOrZ2Z9FHKJ48Mmizq8TEHKxd82nNJxaN8kaC00hykmvEna';
  await Stripe.instance.applySettings();

  // runApp(const MainApp());

  runApp(
    const ProviderScope(
      child: GreenHub(),
    ),
  );
}

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: Scaffold(body: Center(child: Text('Hello World!'))),
//     );
//   }
// }