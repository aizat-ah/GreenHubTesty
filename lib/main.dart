import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
