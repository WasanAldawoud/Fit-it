import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: const CreatePlanScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Data Model
class ExerciseCategory {
  final String name;
  final List<String> icons;

  const ExerciseCategory({
    required this.name,
    required this.icons,
  });
}

// The Main Screen Widget
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => CreatePlanScreenState();
}

class CreatePlanScreenState extends State<CreatePlanScreen> {
  // Exercise Categories
  final List<ExerciseCategory> categories = [
    ExerciseCategory(
        name: 'Cardio',
        icons: ['assets/icons/cardio1.svg', 'assets/icons/cardio2.svg'],),
    ExerciseCategory(
        name: 'Yoga',
        icons: ['assets/icons/yoga1.svg','assets/icons/yoga2.svg'],),
    ExerciseCategory(
        name: 'Swimming',
        icons: ['assets/icons/swimming1.svg','assets/icons/swimming3.svg'],),
    ExerciseCategory(
        name: 'Pilates',
        icons: ['assets/icons/pilates3.svg','assets/icons/pilates2.svg'],),
    ExerciseCategory(
        name: 'Stretching',
        icons: ['assets/icons/stretching1.svg','assets/icons/stretching2.svg'],),
    ExerciseCategory(
        name: 'Cycling',
        icons: ['assets/icons/cycling1.svg','assets/icons/cycling2.svg'],),
  ];

  // Set to store the names of selected categories
  final Set<String> selectedCategories = {};

  void toggleCategory(String categoryName) {
    setState(() {
      if (selectedCategories.contains(categoryName)) {
        selectedCategories.remove(categoryName);
      } else {
        selectedCategories.add(categoryName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Your Own Plan',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step 1: Choose Exercise Categories',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected =
                    selectedCategories.contains(category.name);
                    return CategoryCard(
                      category: category,
                      isSelected: isSelected,
                      onTap: () => toggleCategory(category.name),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00AEEF), Color(0xFF00D1D1)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: ElevatedButton(
                  onPressed: () {/* Navigate to the next screen Here*/},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Category Card Widget
class CategoryCard extends StatelessWidget {
  final ExerciseCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    // inner content (icon and text)
    final cardContent = Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  
                  // First Icon
                  SvgPicture.asset(
                    category.icons[0], // Access 1
                    width: 50.0,
                    height: 50.0,
                    colorFilter: ColorFilter.mode(
                      (isSelected ? const Color(0xFFFFAE00) : Color(0xFF00AEEF)),
                      BlendMode.srcIn,
                    ),
                  ),


                  // Second Icon
                  SvgPicture.asset(
                    category.icons[1], // Access 2
                    width: 50.0,
                    height: 50.0,
                    colorFilter: ColorFilter.mode(
                      (isSelected ? const Color(0xFF0073E6) : Color(0xFF00AEEF)),
                      BlendMode.srcIn,
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 12.0),
              Text(
                category.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00B2FF),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: isSelected ?

      // IF SELECTED: double-border design
         Container(
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00B2FF),
            width: 2.0,
          ),

            borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
          BoxShadow(
            color: const Color(0xFFA1E2FF),
            blurRadius: 17.0,
          ),
          ]
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF00B2FF),
              width: 2.0,
            ),
            color: const Color(0xFFF7F7F7), // A light inner color for contrast
            borderRadius: BorderRadius.circular(16.0),
          ),

          child: cardContent,

        ),
      ) :



      // IF NOT SELECTED: "fog" effect
      Container(
        decoration: BoxDecoration(

          //Box Color
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16.0),

          // Shadow
          boxShadow: [
            // bottom right "dark" shadow
            BoxShadow(
              color: Colors.grey.shade500,
              offset: const Offset(4, 4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            // top left "light" shadow
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),

        child: cardContent,

      ),
    );
  }
}

