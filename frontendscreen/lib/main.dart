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
        // 1. Session is valid! Now determine the URL to fetch the workout plan
        String fetchUrl;
        if (kIsWeb) {
          fetchUrl = 'http://localhost:3000/auth/get-plan';
        } else if (Platform.isAndroid) {
          // Use your specific IP if on a real device, or 10.0.2.2 for emulator
          fetchUrl = 'http://10.0.2.2:3000/auth/get-plan'; 
        } else {
          fetchUrl = 'http://localhost:3000/auth/get-plan';
        }

        // 2. Fetch the plan data
        final fetchRes = await client.get(Uri.parse(fetchUrl));

        if (fetchRes.statusCode == 200) {
          final data = jsonDecode(fetchRes.body);
          if (data['plan'] != null) {
            // 3. Populate the PlanController so HomePage has data
            PlanController.instance.syncFromBackend(data['plan']);
          }
        }

        // 4. Move to MainShell (which contains the Bottom Navbar)
        setState(() {
          _initialScreen = const MainShell();
        });
      }else {
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