import 'package:flutter/material.dart';
import 'features/plan_creation/presentation/screens/create_plan_screen.dart';


/// The main entry point of the application.
void main() {
  runApp(const FitIt());
}




/// The root widget of the Fit-It application.
///
/// This widget sets up the [MaterialApp], which provides the basic
/// application structure, theming, and navigation.
class FitIt extends StatelessWidget {
  const FitIt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      // The initial screen of the application is set to CreatePlanScreen.
      home: const CreatePlanScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
