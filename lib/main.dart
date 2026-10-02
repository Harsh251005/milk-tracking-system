import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android reads its Firebase config from android/app/google-services.json.
  // M1 runs on sample data; sign-in and Firestore are wired in M2/M3.
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MilkTrackerApp()));
}
