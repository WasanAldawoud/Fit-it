// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
// import 'package:frontendscreen/app_styles/custom_widgets.dart';
// import 'package:frontendscreen/app_styles/color_constants.dart';
// import 'choosing_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'dart:convert'; // For jsonEncode: Converts Dart Maps into JSON strings for the server
import 'package:http/http.dart' as http; // Main package for making network requests
import 'package:flutter/foundation.dart'; // For kIsWeb: Checks if the app is in a browser
import 'package:http/browser_client.dart'; // Handles session cookies specifically for Web
import 'dart:io'; // Checks platform (Android/iOS) to set correct IP address
import '../../app_styles/custom_widgets.dart';
import '../../app_styles/color_constants.dart';
import '../choosing_screen/choosing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Text Controllers: These hold the text that the user types into the input fields
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final genderController = TextEditingController();
  final birthDateController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  bool isPasswordVisible = false;

  // Validation strings: If these are NOT null, an error message appears on the screen
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? genderError;
  String? birthDateError;
  String? weightError;
  String? heightError;
  String? selectedGender;

  DateTime? selectedBirthDate;

  bool isFormValid = false;
  bool startedTyping = false; // Prevents showing errors until the user actually starts typing
  bool isLoading = false; // Triggers the loading spinner when true

  /// Local validation logic to check inputs before bothering the server
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

      // The form is only valid if all error strings are null
      isFormValid =
          usernameError == null &&
          emailError == null &&
          passwordError == null &&
          confirmPasswordError == null;
    });
  }

  // ---------------------------------------------------------
  // BACKEND LINKING LOGIC: Connecting to Node.js
  // ---------------------------------------------------------
  Future<void> signupUser() async {
    setState(() {
      isLoading = true; // Show spinner
    });

    String baseUrl;
    // We must use different IPs depending on the device running the app
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/auth/signup'; 
    } else if (Platform.isAndroid) {
      // 26.35.223.225 is your computer's specific IP on the local network
      baseUrl = 'http://26.35.223.225:3000/auth/signup'; 
    } else {
      // 10.0.2.2 is the special gateway for the Android Emulator to see 'localhost'
      baseUrl = 'http://10.0.2.2:3000/auth/signup'; 
    }

    try {
      var client = http.Client();
      if (kIsWeb) {
        // withCredentials = true: Required for Passport.js to send the session cookie to the browser
        client = BrowserClient()..withCredentials = true;
      }

      // 1. SEND POST REQUEST: Sends user data as a JSON "box"
      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text.trim().toLowerCase(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "gender": selectedGender,
          "birthdate": selectedBirthDate.toString(),
          "weight": weightController.text,
          "height": heightController.text,
        }),
      );

      if (!mounted) return; // Prevent memory leaks if user leaves screen during request

      // 2. CHECK STATUS: 201 means "Created" (Success in Node.js)
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully!")),
        );

        // Success: Take the user to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChoosingScreen()),
        );
      } else {
        // Error: The backend sent a 409 (Duplicate) or 400 (Bad Data)
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? "Signup failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Crash: The server is down or the IP address in 'baseUrl' is wrong
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection failed. Check your server/IP. Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide the spinner whether we succeed or fail
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

                    // Inputs Section
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

                    // Gender Dropdown: Values must match your PostgreSQL 'gender' constraints
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: "Gender",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                          validateForm();
                        });
                      },
                    ),
                    if (startedTyping && genderError != null)
                      _buildErrorText(genderError!),
                    const SizedBox(height: 20),

                    // Birth Date Picker
                    CustomTextField(
                      controller: birthDateController,
                      hintText: "Birth Date",
                      icon: Icons.cake,
                      fieldKey: const ValueKey('signup_birthdate'),
                      readOnly: true,
                      onTap: () async {
                        FocusScope.of(context).unfocus(); // Close keyboard
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1980),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setState(() {
                            selectedBirthDate = picked;
                            // Format: YYYY-MM-DD (matches PostgreSQL date format)
                            birthDateController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            validateForm();
                          });
                        }
                      },
                    ),
                    if (startedTyping && birthDateError != null)
                      _buildErrorText(birthDateError!),
                    const SizedBox(height: 20),

                    // Weight Input
                    CustomTextField(
                      controller: weightController,
                      hintText: "Weight (kg)",
                      icon: Icons.monitor_weight,
                      fieldKey: const ValueKey('signup_weight'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => validateForm(),
                    ),
                    const SizedBox(height: 20),

                    // Height Input
                    CustomTextField(
                      controller: heightController,
                      hintText: "Height (cm)",
                      icon: Icons.height,
                      fieldKey: const ValueKey('signup_height'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => validateForm(),
                    ),
                    const SizedBox(height: 30),

                    // Create Account Button
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: () {
                              if (isFormValid) {
                                signupUser(); // Call the backend function
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fix errors first")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.accentColor,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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

                    // Already have an account? Sign In Link
                    RichText(
                      text: TextSpan(
                        text: "Already have an account?",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
                                Navigator.pop(context); // Goes back to SigninScreen
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Google OAuth Sign Up
                    ElevatedButton.icon(
                      key: const ValueKey('google_signup_button'),
                      onPressed: () async {
                        String url;
                        if (kIsWeb) {
                          url = 'http://localhost:3000/auth/google';
                        } else if (Platform.isAndroid) {
                          url = 'http://26.35.223.225:3000/auth/google';
                        } else {
                          url = 'http://10.0.2.2:3000/auth/google';
                        }

                        // Use url_launcher to open Google Login in the device browser
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                      icon: Image.asset('assets/pic/google.png', height: 24, width: 24),
                      label: const Text(
                        "Sign up with Google",
                        style: TextStyle(color: Color(0xFF8A5D82), fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  // Helper widget to display red error text beneath input fields
  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        error,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

}
