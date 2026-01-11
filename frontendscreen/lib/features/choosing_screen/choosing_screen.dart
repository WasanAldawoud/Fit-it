
import 'package:flutter/material.dart';
import '../plan_creation/presentation/screens/create_plan_screen.dart';

///ملف الإختيار

class ChoosingScreen extends StatelessWidget {
  const ChoosingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية
          SizedBox.expand(
            child: Image.asset(
              "assets/pic/bg.jpg",
              fit: BoxFit.cover,
            ),
          ), 
              


           Column(
  children: [
    Container(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 50),
        child: Text(
          "Stay fit pickee an AI-powered plan for smart guidance or go manual for full control.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ),
              const SizedBox(height: 70),

              // زر 1
              SizedBox(
  width: MediaQuery.of(context).size.width * 0.95,   // 90% من عرض الشاشة
 height: MediaQuery.of(context).size.height * 0.17,
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.fromARGB(255, 81, 166, 235), Color.fromARGB(255, 5, 38, 99)],
          begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color.fromARGB(255, 255, 255, 255), // لون الوهج
          blurRadius: 20, // مدى التوهج
          spreadRadius: 3, // مدى الوهج حول الزر
          offset: const Offset(0, 0), // وهج يعني محيط الزر بالكامل
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // شفاف لإظهار التدرج
        shadowColor: Colors.transparent, // بدون ظل
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
      ),
      child: Row(
        children: [
          // أيقونة
          Image.asset(
            "assets/pic/AiIcon.png",
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 15),

          // النصوص
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "Let AI Build My Plan",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Personalized Smart Plan Using AI",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),


              const SizedBox(height: 90), // مسافة بين الزرين

              // زر 2
             SizedBox(
  width: MediaQuery.of(context).size.width * 0.95,   // 90% من عرض الشاشة
 height: MediaQuery.of(context).size.height * 0.17,
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.fromARGB(255, 81, 166, 235), Color.fromARGB(255, 5, 38, 99)],
         begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Color.fromARGB(255, 255, 255, 255), // لون الوهج
          blurRadius: 20, // مدى التوهج
          spreadRadius: 3, // وهج حول الزر
          offset: const Offset(0, 0), //  وهج يعني محيط الزر بالكامل
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreatePlanScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // شفاف لإظهار التدرج
        shadowColor: Colors.transparent, // بدون ظل
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
      ),
      child: Row(
        children: [
          // أيقونة
          Image.asset(
            "assets/pic/micon.png",
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 15),

          // النصوص
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "Create My Own Plan",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Full Control to Design Your Plan",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
          
  ],
          ),
        ],
      ),
    );
  }
}



