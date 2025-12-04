// import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
// import 'package:frontendscreen/app_styles/custom_widgets.dart';
// import 'package:frontendscreen/app_styles/color_constants.dart';
// import 'choosing_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

  // رسائل التحقق لكل حقل
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  bool isFormValid = false;
  bool startedTyping = false; // لتجنب ظهور الرسائل قبل الكتابة

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

      isFormValid =
          usernameError == null &&
          emailError == null &&
          passwordError == null &&
          confirmPasswordError == null;
    });
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

                    // حقول التسجيل مع رسائل التحقق تظهر فقط بعد الكتابة
                    CustomTextField(
                      controller: usernameController,
                      hintText: "Username",
                      icon: Icons.person,
                      fieldKey: const ValueKey('signup_username'),
                      onChanged: (_) => validateForm(),
                    ),
                    if (startedTyping && usernameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          usernameError!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: emailController,
                      hintText: "Email",
                      icon: Icons.email,
                      fieldKey: const ValueKey('signup_email'),
                      onChanged: (_) => validateForm(),
                    ),
                    if (startedTyping && emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          emailError!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          passwordError!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          confirmPasswordError!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),

                    // زر إنشاء الحساب
                    ElevatedButton(
                      onPressed: () {
                        if (isFormValid) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => choosing_screen()),//تصميم عمر 
                          );
                        } else {
                          // هنا ممكن تضيفي رسائل الخطأ أو تترك الزر يعمل فقط إذا صحيح
                          print("Form is invalid");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ColorConstants.accentColor, // اللون الأصلي
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
                          color: Colors.white, // النص ثابت أبيض
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // رابط تسجيل الدخول
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
}
