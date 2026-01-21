// import 'package:flutter/material.dart';
// import 'package:frontendscreen/app_styles/color_constants.dart';
// import 'package:frontendscreen/app_styles/custom_widgets.dart';
// import 'package:frontendscreen/choosing_screen/home_page.dart';
// import 'package:frontendscreen/choosing_screen/signup_screen.dart';

import 'package:flutter/material.dart';
import '../../app_styles/color_constants.dart';
import '../../app_styles/custom_widgets.dart';
import '../common/main_shell.dart';
import 'signup_screen.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async'; 
import 'package:uni_links/uni_links.dart'; 


// 🔹 Required for Web redirection logic
// This allows the app to refresh the browser tab to the backend URL
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; 

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
  
  // 🔹 DEEP LINK SUBSCRIPTION
  // This listens for when Google sends the user back to "fititapp://login-success"
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // Mobile only: Initialize the listener for the deep link handshake
    if (!kIsWeb) {
      _initDeepLinkListener();
    }
  }

  @override
  void dispose() {
    _sub?.cancel(); // Stop listening to links when the screen is destroyed
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // 1. MOBILE DEEP LINK LOGIC (Google Auth Return)
  // ---------------------------------------------------------
  
  void _initDeepLinkListener() async {
    // This stream triggers whenever the app is opened via a URI (like fititapp://)
    _sub = linkStream.listen((String? link) {
      if (link != null && link.contains("fititapp://login-success")) {
        debugPrint("🔗 Deep Link Received: $link");
        _handleLoginSuccess(); // Move the user to the Home Page
      }
    }, onError: (err) {
      debugPrint("❌ Deep Link Error: $err");
    });
  }

  // Common navigation after successful login
  void _handleLoginSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login Successful!")),
    );
    // Remove the login screen from the stack and go to Home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  // ---------------------------------------------------------
  // 2. MANUAL SIGN-IN (Username/Password)
  // ---------------------------------------------------------
  
  Future<void> signInUser() async {
    setState(() => isLoading = true);

    // Platform-specific URL logic
    String baseUrl; 
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/auth/signin';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://26.35.223.225:3000/auth/signin';
    } else {
      baseUrl = 'http://10.0.2.2:3000/auth/signin';
    }

    try {
      var client = http.Client();
      if (kIsWeb) {
        // 🔹 WEB FIX: withCredentials = true allows the browser to receive and 
        // store the "connect.sid" cookie from the Node.js server.
        client = BrowserClient()..withCredentials = true; 
      }

      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text.trim().toLowerCase(),
          "password": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _handleLoginSuccess(); 
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
                    "Welcome to Fit-It",
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 30, 
                      fontWeight: FontWeight.bold
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
                          icon: Icons.person
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: passwordController,
                          hintText: "Password",
                          icon: Icons.lock,
                          obscureText: !isPasswordVisible,
                          toggleVisibility: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : CustomButton(
                              title: "Sign In", 
                              onTap: signInUser, 
                              backgroundColor: Colors.white
                            ),
                      const SizedBox(width: 15),
                      CustomButton(
                        title: "Create Account", 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())), 
                        backgroundColor: ColorConstants.primaryColor, 
                        isWhiteText: true
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // ---------------------------------------------------------
                  // 3. GOOGLE SIGN IN BUTTON LOGIC
                  // ---------------------------------------------------------
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (kIsWeb) {
                        // 🌐 WEB LOGIC: 
                        // We must change the current window's URL to our backend.
                        // Using window.location.href ensures the OAuth flow happens in the 
                        // SAME session, keeping the user logged in upon return.
                        html.window.location.href = 'http://localhost:3000/auth/google';
                      } else {
                        // 📱 MOBILE LOGIC:
                        // Open the external browser (Chrome/Safari) to handle the Google login.
                        String url = Platform.isAndroid
                            ? 'http://26.35.223.225:3000/auth/google'
                            : 'http://10.0.2.2:3000/auth/google';
                        
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(
                            Uri.parse(url), 
                            mode: LaunchMode.externalApplication // Launch in phone browser
                          );
                        }
                      }
                    },
                    icon: Image.asset('assets/pic/google.png', height: 24),
                    label: const Text(
                      "Sign in with Google", 
                      style: TextStyle(color: Color(0xFF8A5D82))
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, 
                      shape: const StadiumBorder()
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
