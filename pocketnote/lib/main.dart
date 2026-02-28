// lib/main.dart
//
// App entry:
// - Init Flutter bindings
// - Init LocalDb (Hive offline DB)
// - Init Firebase (for auth + firestore sync; safe to run even if offline)
// - Run AppRoot (providers + MaterialApp)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'data/local/local_db.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env.local");
  // Offline-first: local DB must be ready no matter what.
  await LocalDb.init();

  // Firebase is for online sync + auth.
  // If Firebase is not configured correctly yet, it will throw.
  // During setup stage, keep it strict so you notice configuration issues early.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(),
    providerApple: const AppleDebugProvider(),
  );
  
  runApp(const AppRoot());
}
