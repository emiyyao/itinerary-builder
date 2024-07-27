import 'dart:async';
import 'package:finalproj/login_screen.dart';
import 'package:finalproj/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "InsertAPIKeyHere",
        appId: "1:617404407191:android:54d7caaa19b8388b4e78d2",
        messagingSenderId: "617404407191",
        projectId: "cs4720-final-proj",
        storageBucket: "cs4720-final-proj.appspot.com")
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: Wrapper());
  }
}
