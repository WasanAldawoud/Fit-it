// import 'package:flutter/material.dart';
// import 'package:/frontendscreen/choosing_screen/signin_screen.dart';

import 'package:flutter/material.dart';
import 'features/signin_signup/signin_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SigninScreen(),
    );
  }
}
