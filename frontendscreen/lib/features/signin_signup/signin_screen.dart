// import 'package:flutter/material.dart';
// import 'package:frontendscreen/app_styles/color_constants.dart';
// import 'package:frontendscreen/app_styles/custom_widgets.dart';
// import 'package:frontendscreen/choosing_screen/home_page.dart';
// import 'package:frontendscreen/choosing_screen/signup_screen.dart';

import 'package:flutter/material.dart';
import '../../app_styles/color_constants.dart';
import '../../app_styles/custom_widgets.dart';
import '../home_page/home_page.dart';
import 'signup_screen.dart';
// ⚠️  to talk to the backend
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import 'dart:io'; //to use it on device 
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
 //--- NEW FUNCTION: Connects to Node.js for Sign In ---
  Future<void> signInUser() async {
  setState(() => isLoading = true);

  String baseUrl; 
  
  if (kIsWeb) {
  // 1. Running in a Chrome Browser (localhost is fine here)
  baseUrl = 'http://localhost:3000/auth/signup'; 
} else if (Platform.isAndroid) {
  // 2. Running on Android
  // Note: You need to import 'import 'dart:io';' for 'Platform'
  
  // Choose ONE of these:
  // baseUrl = 'http://10.0.2.2:3000/auth/signup'; // For Emulator
  baseUrl = 'http://26.35.223.225:3000/auth/signup'; // For Physical Device via Wi-Fi
} else {
  // 3. For iOS Simulator or other platforms
  baseUrl = 'http://localhost:3000/auth/signup';
}
  try {
    var client = http.Client();
    if (kIsWeb) {
      client = BrowserClient()..withCredentials = true; // Essential for session cookies
    }

    final response = await client.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text, // Sending only what's needed
        "password": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signed in successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorData['error'] ?? "Sign in failed")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connection failed: $e")),
    );
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/pic/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "Welcome to your fitness app\nFit-It",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 60),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: usernameController,
                          hintText: "Username",
                          icon: Icons.person,
                          fieldKey: const ValueKey('username_field'),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: passwordController,
                          hintText: "Password",
                          icon: Icons.lock,
                          toggleVisibility: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          obscureText: !isPasswordVisible,
                          fieldKey: const ValueKey('password_field'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Update 1: Replace CustomButton with logic ---
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : CustomButton(
                              title: "Sign In",
                              onTap: () {
                                if (usernameController.text.isNotEmpty &&
                                    passwordController.text.isNotEmpty) {
                                  // 🔑 CALL THE NEW BACKEND FUNCTION
                                  signInUser(); 
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Please enter both username and password")),
                                  );
                                }
                              },
                              backgroundColor: Colors.white,
                              buttonKey: const ValueKey('sign_in_button'),
                            ),
                      // --- End Update 1 ---

                      const SizedBox(width: 15),
                      CustomButton(
                        title: "Create Account",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignupPage()),
                          );
                        },
                        backgroundColor: ColorConstants.primaryColor,
                        isWhiteText: true,
                        buttonKey: const ValueKey('create_account_button'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    key: const ValueKey('google_sign_in_button'),
                    onPressed: () {
                      print('Sign in with Google pressed');
                    },
                    icon: Image.asset(
                      'assets/pic/google.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text(
                      "Sign in with Google",
                      style: TextStyle(
                        color: Color(0xFF8A5D82),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
