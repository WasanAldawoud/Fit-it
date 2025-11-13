import 'package:flutter/material.dart';
import 'package:frontendscreen/app_styles/color_constants.dart';
import 'package:frontendscreen/app_styles/custom_widgets.dart';
import 'package:frontendscreen/screens/home_page.dart';
import 'package:frontendscreen/screens/signup_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;

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
                      CustomButton(
                        title: "Sign In",
                        onTap: () {
                          if (usernameController.text.isNotEmpty &&
                              passwordController.text.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => HomePage()),
                            );
                          }
                        },
                        backgroundColor: Colors.white,
                        buttonKey: const ValueKey('sign_in_button'),
                      ),
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
