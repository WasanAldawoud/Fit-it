import 'package:flutter/material.dart';
import '../plan_creation/presentation/screens/create_plan_screen.dart';
import '../Ai_chat/chat_screen.dart';

/// Choosing Screen - Updated to handle back button navigation
class ChoosingScreen extends StatelessWidget {
  final bool showBackButton;

  // Added showBackButton to the constructor with a default of false
  const ChoosingScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is used specifically to show/hide the back button
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true, // Allows background image to cover status bar
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              "assets/pic/bg.jpg",
              fit: BoxFit.cover,
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                Container(
                  alignment: Alignment.topCenter,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Text(
                      "Stay fit pick an AI-powered plan for smart guidance or go manual for full control.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Button 1: AI Plan
                _buildChoiceButton(
                  context: context,
                  title: "Let AI Build My Plan",
                  subtitle: "Personalized Smart Plan Using AI",
                  iconPath: "assets/pic/AiIcon.png",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Button 2: Manual Plan
                _buildChoiceButton(
                  context: context,
                  title: "Create My Own Plan",
                  subtitle: "Full Control to Design Your Plan",
                  iconPath: "assets/pic/micon.png",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Refactored Button Widget to maintain logic and UI consistency
  Widget _buildChoiceButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      height: MediaQuery.of(context).size.height * 0.17,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 81, 166, 235),
              Color.fromARGB(255, 5, 38, 99)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              blurRadius: 20,
              spreadRadius: 3,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
          ),
          child: Row(
            children: [
              Image.asset(
                iconPath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 15),
              Expanded( // Added Expanded to prevent text overflow on smaller screens
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, // Adjusted size slightly for better fitting
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}