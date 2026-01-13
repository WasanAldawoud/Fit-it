// import 'package:flutter/material.dart';
// import 'package:/frontendscreen/choosing_screen/signin_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'features/signin_signup/signin_screen.dart';
//import 'features/plan_creation/presentation/screens/create_plan_screen.dart';// Import the CreatePlanScreen for tests
//import 'features/common/main_shell.dart'; //Import the CreatePlanScreen for tests

import 'features/home_page/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // 🔹 The loop-breaker: Check if the browser already has a session cookie
  Future<void> _checkAuthStatus() async {
    // Port 3000 is your Node.js server
    const String url = 'http://localhost:3000/auth/profile';

    try {
      var client = http.Client();
      if (kIsWeb) {
        // 🔹 ESSENTIAL: This forces the browser to send the 'connect.sid' cookie
        client = BrowserClient()..withCredentials = true;
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // Session valid! User is already logged in via Google/Local
        setState(() {
          _initialScreen = const HomePage();
        });
      } else {
        // No session found
        setState(() {
          _initialScreen = const SigninScreen();
        });
      }
    } catch (e) {
      debugPrint("Auth check failed: $e");
      setState(() {
        _initialScreen = const SigninScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fit-It',
      // Show a loading spinner until we know if the user is logged in
      home: _initialScreen ?? const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      ),
    );
  }
}