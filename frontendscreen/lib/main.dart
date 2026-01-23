// import 'package:flutter/material.dart';
// import 'package:/frontendscreen/choosing_screen/signin_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';// 🔹 Added for jsonDecode
import 'dart:io';// 🔹 Added for Platform.isAndroid
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'features/signin_signup/signin_screen.dart';
import 'features/common/main_shell.dart';
import 'features/common/plan_controller.dart'; // 🔹 Added to access syncFromBackend

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
 // 🔹 The loop-breaker: Check if the browser already has a session cookie
  Future<void> _checkAuthStatus() async {
  // Use dynamic IP logic like in your other files
  String baseUrl = kIsWeb ? 'http://localhost:3000' 
      : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://26.35.223.225:3000');

  try {
    var client = http.Client();
    if (kIsWeb) client = BrowserClient()..withCredentials = true;

    final response = await client.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {"Accept": "application/json"},
    ).timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check for our new flag
      if (data['authenticated'] == false) {
        setState(() => _initialScreen = const SigninScreen());
      } else {
        setState(() => _initialScreen = const MainShell());
      }
    } else {
      setState(() => _initialScreen = const SigninScreen());
    }
  } catch (e) {
    debugPrint("Auth check failed: $e");
    setState(() => _initialScreen = const SigninScreen());
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