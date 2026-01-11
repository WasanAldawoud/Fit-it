// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
// import 'package:frontendscreen/app_styles/custom_widgets.dart';
// import 'package:frontendscreen/app_styles/color_constants.dart';
// import 'choosing_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'dart:convert'; // Needed for JSON encoding/decoding
import 'package:http/http.dart' as http; // Needed to talk to the server
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http/browser_client.dart';
import 'dart:io'; //to use it on device 
import '../../app_styles/custom_widgets.dart';
import '../../app_styles/color_constants.dart';
import '../choosing_screen/choosing_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;

  // Validation messages
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  bool isFormValid = false;
  bool startedTyping = false;
  bool isLoading = false; // To show a loading spinner while signing up

  void validateForm() {
    setState(() {
      startedTyping = true;

      usernameError = usernameController.text.isEmpty
          ? "Username cannot be empty"
          : null;

      emailError = !emailController.text.contains('@')
          ? "Enter a valid email"
          : null;

      passwordError = passwordController.text.length < 6
          ? "Password must be at least 6 characters"
          : null;

      confirmPasswordError =
          confirmPasswordController.text != passwordController.text
              ? "Passwords do not match"
              : null;

      isFormValid = usernameError == null &&
          emailError == null &&
          passwordError == null &&
          confirmPasswordError == null;
    });
  }

  // --- NEW FUNCTION: Connects to Node.js ---
  Future<void> signupUser() async {
    setState(() {
      isLoading = true; // Start loading
    });

    // NOTE: Use '10.0.2.2' for Android Emulator. Use 'localhost' for iOS Simulator.
    // Use your computer's IP (e.g., 192.168.1.5) for a real physical device.
    String baseUrl;

  if (kIsWeb) {
  baseUrl = 'http://localhost:3000/auth/signup'; // ✅ CORRECT
} else if (Platform.isAndroid) {
  baseUrl = 'http://10.0.2.2:3000/auth/signup'; // ✅ CORRECT
} else {
  baseUrl = 'http://localhost:3000/auth/signup'; // ✅ CORRECT
}

    try {
    // IMPORTANT: Use BrowserClient withCredentials for Web
    var client = http.Client();
    if (kIsWeb) {
      client = BrowserClient()..withCredentials = true;
    }

    final response = await client.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
         "email"  :emailController.text,
        "password": passwordController.text,
      }),
    );

      if (!mounted) return; // Check if widget is still on screen

      if (response.statusCode == 201) {
        // SUCCESS: Navigate to Choosing Screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChoosingScreen()),
        );
      } else {
        // FAILURE: Show error from backend
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? "Signup failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // NETWORK ERROR (Server down or wrong IP)
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection failed. Is the server running? Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false); {
        setState(() {
          isLoading = false; // Stop loading
        });
      }
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "Welcome to Fit-It\nCreate your account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Inputs
                    CustomTextField(
                      controller: usernameController,
                      hintText: "Username",
                      icon: Icons.person,
                      fieldKey: const ValueKey('signup_username'),
                      onChanged: (_) => validateForm(),
                    ),
                    if (startedTyping && usernameError != null)
                      _buildErrorText(usernameError!),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: emailController,
                      hintText: "Email",
                      icon: Icons.email,
                      fieldKey: const ValueKey('signup_email'),
                      onChanged: (_) => validateForm(),
                    ),
                    if (startedTyping && emailError != null)
                      _buildErrorText(emailError!),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: passwordController,
                      hintText: "Password",
                      icon: Icons.lock,
                      obscureText: !isPasswordVisible,
                      fieldKey: const ValueKey('signup_password'),
                      onChanged: (_) => validateForm(),
                      toggleVisibility: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    if (startedTyping && passwordError != null)
                      _buildErrorText(passwordError!),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: confirmPasswordController,
                      hintText: "Confirm Password",
                      icon: Icons.check,
                      obscureText: true,
                      fieldKey: const ValueKey('signup_confirm_password'),
                      onChanged: (_) => validateForm(),
                    ),
                    if (startedTyping && confirmPasswordError != null)
                      _buildErrorText(confirmPasswordError!),
                    const SizedBox(height: 30),

                    // Create Account Button
                    isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                      onPressed: () {
                        if (isFormValid) {
                          // Call the new backend function
                          signupUser();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fix errors first")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign In Link
                    RichText(
                      text: TextSpan(
                        text: "Already have an account?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: " Sign In",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pop(context);
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Google Sign Up
                    ElevatedButton.icon(
                      key: const ValueKey('google_signup_button'),
                      onPressed: () {
                        print('Sign up with Google pressed');
                      },
                      icon: Image.asset(
                        'assets/pic/google.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text(
                        "Sign up with Google",
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
      ),
    );
  }

  // Helper widget for error text to keep code clean
  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
} 
