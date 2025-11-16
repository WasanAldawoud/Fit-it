import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import '../widgets/exercise_selection_dialog.dart';
import'../../data/models/dialog_exercise_state.dart';
import'../../data/models/exercise_category.dart';

/// A screen where users can create a custom workout plan.
///
/// This screen displays a grid of exercise categories. Tapping a category
/// opens a dialog to select exercises and set their duration and days.
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => CreatePlanScreenState();
}

class CreatePlanScreenState extends State<CreatePlanScreen> {

  /// This list holds the state of all exercises selected by the user across all categories.
  /// Each [DialogExerciseState] contains the exercise name, duration, and selected days.
  /// This is the main data structure representing the user's workout plan.
  final List<DialogExerciseState> planStates  = [];

  /// Opens a dialog to select exercises for a given [category].
  ///
  /// This method shows an [ExerciseSelectionDialog] populated with exercises
  /// from the selected [category]. It passes any existing plan states for that
  /// category to the dialog.
  ///
  /// When the dialog is closed, it updates the [planStates] with the new or
  /// modified exercise selections.
  void makePlanDialog(ExerciseCategory category) async {

    final existing = planStates
        .where((plan) => category.exercises.contains(plan.name))
        .toList();

    final List<DialogExerciseState>? result = await showDialog<List<DialogExerciseState>>(
      context: context,

      builder: (context)  {
        return ExerciseSelectionDialog(
          category: category,
          existingPlans: existing,
        );
      },
    );

    if (result != null) {
      setState(() {
        // Clear old plan for this category before adding the new one.
        planStates.removeWhere((item) => category.exercises.contains(item.name));

        if (result.isNotEmpty) {
          // If the user confirmed with at least one exercise, add the new plan.
          planStates.addAll(result); // Add the new, updated plan
          selectedCategories.add(category.name); // Mark the card as selected
        } else {
          // If the user confirmed with an empty plan, mark the card as deselected.
          selectedCategories.remove(category.name);
        }

      });
    }
  }

  /// The list of available exercise categories.
  /// This data is used to populate the grid of [CategoryCard]s.
  final List<ExerciseCategory> categories = [
    ExerciseCategory(
        name: 'Cardio',
        icons: ['assets/icons/cardio1.svg', 'assets/icons/cardio2.svg'],
        exercises: ['brisk walking', 'running', 'cycling', 'swimming', 'dancing', 'Jumping rope'] ),
    ExerciseCategory(
        name: 'Yoga',
        icons: ['assets/icons/yoga1.svg','assets/icons/yoga2.svg'],
        exercises: ['Downward Facing Dog', 'Mountain Pose', 'Tree Pose', 'Warrior 2','Cat Pose and Cow Pose', 'Chair Pose', 'Cobra Pose', 'Child\'s Pose'] ),
    ExerciseCategory(
        name: 'Strength Training',
        icons: ['assets/icons/strength_training1.svg','assets/icons/strength_training2.svg'],
        exercises: ['Squats', 'Deadlifts', 'Overhead Press', 'Push-ups', 'Pull-ups', 'Lunges', 'Rows', 'Kettlebell Swings', 'Planks', 'Burpees', 'Tricep Dips', 'Bicep Curls', 'Glute Bridges', 'Step-ups', 'Renegade Rows' ] ),
    ExerciseCategory(
      name: 'Core Exercises',
        icons: ['assets/icons/core_exercises1.svg','assets/icons/core_exercises2.svg'],
        exercises: ['Plank', 'Crunches', 'Leg Raises', 'Glute Bridge', 'Bird Dog', 'Dead Bug', 'Russian Twists', 'Mountain Climbers', 'Hollow Hold', 'Side Plank with Rotation', 'Stability Ball Pike', 'Flutter Kicks', 'Bicycle Crunches', 'Reverse Crunches', 'Single-Arm Farmers Carry', 'Renegade Rows', 'Hanging Windshield Wipers'] ),
    ExerciseCategory(
        name: 'Stretching',
        icons: ['assets/icons/stretching1.svg','assets/icons/stretching2.svg'],
        exercises: ['Hamstring stretch', 'Standing calf stretch', 'Shoulder stretch', 'Triceps stretch', 'Knee to chest', 'Quad stretch', 'Cat Cow', 'Child\'s Pose', 'Quadriceps stretch', 'Kneeling hip flexor stretch', 'Side stretch', 'Chest and shoulder stretch', 'Neck Stretch', 'Spinal Twist', 'Bicep stretch', 'Cobra'] ),
    ExerciseCategory(
        name: 'Pilates',
        icons: ['assets/icons/pilates3.svg','assets/icons/pilates2.svg'],
        exercises: ['Pelvic Curl', 'Chest Lift', 'Chest Lift with Rotation', 'Spine Twist Supine', 'Single Leg Stretch', 'Roll Up', 'Roll-Like-a-Ball', 'Leg Circles'] ),
  ];

  /// A set that stores the names of categories that have at least one exercise selected.
  /// This is used to visually indicate which categories are part of the current plan.
  final Set<String> selectedCategories = {};


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
                    final isSelected = selectedCategories.contains(category.name);

                    return CategoryCard(
                      category: category,
                      isSelected: isSelected,
                      onTap: () => makePlanDialog(category) ,
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
                  onPressed: () {/* TODO: Navigate to the next screen to finalize the plan */},
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
