import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import '../widgets/exercise_selection_dialog.dart';
import '../../data/models/dialog_exercise_state.dart';
import '../../data/models/exercise_category.dart';
import '../../../common/main_shell.dart'; // To navigate after saving
import 'plan_goal_screen.dart';
import '../../../common/plan_controller.dart';

/// A screen where users can create a custom workout plan.
///
/// This screen displays a grid of exercise categories. Tapping a category
/// opens a dialog to select exercises and set their duration and days.
import 'dart:convert'; // For jsonEncode: Converts Dart objects into JSON strings for the backend
import 'package:http/http.dart' as http; // Standard package for network requests
import 'package:flutter/foundation.dart'; // For kIsWeb: Checks if the app is running in a browser
import '../../../home_page/home_page.dart'; // Navigation destination after a successful save
import 'package:http/browser_client.dart'; // Specialized client for Web to handle Session Cookies
import 'dart:io'; // Required for Platform.isAndroid check

/// A screen where users can create a custom workout plan and save it to the PostgreSQL database.
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
  

  /// Step 2 (PlanGoalScreen) output.
  ///
  /// These are OPTIONAL settings controlled by checkboxes in Step 2.
  /// If a checkbox is disabled, the corresponding value is `null`.
  ///
  /// BACKEND: These map to `/auth/save-plan` payload keys:
  /// - selectedGoal -> `goal` (String?)
  /// - selectedWeeks -> `duration_weeks` (int?)
  /// - selectedDeadline -> `deadline` (String? ISO 8601)
  /// - selectedCurrentWeight -> `current_weight` (double?)
  /// - selectedGoalWeight -> `goal_weight` (double?)
  String? selectedGoal;

  /// BACKEND: Sent as `duration_weeks` (int?). Derived from deadline in Step 2.
  int? selectedWeeks;

  /// BACKEND: Sent as `deadline` (String? ISO 8601) using `toIso8601String()`.
  DateTime? selectedDeadline;

  /// BACKEND: Sent as `current_weight` (double?).
  double? selectedCurrentWeight;

  /// BACKEND: Sent as `goal_weight` (double?).
  double? selectedGoalWeight;

  /// Opens a dialog to select exercises for a given [category].
  ///
  /// This method shows an [ExerciseSelectionDialog] populated with exercises
  /// from the selected [category]. It passes any existing plan states for that
  /// category to the dialog.
  ///
  /// When the dialog is closed, it updates the [planStates] with the new or
  /// modified exercise selections.

  /// Holds the state of all exercises selected by the user.
  /// This is the data we will eventually map to our database schema.


  // --------------------------------------------------------------------------
  // BACKEND LINKING LOGIC
  // --------------------------------------------------------------------------
  
  /// Sends the created plan to the Node.js backend.
  Future<void> savePlanToDatabase() async {
    // 1. Client-side Validation
    if (planStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one exercise")),
      );
      return;
    }

    // 2. Dynamic URL Logic
    // Different platforms require different addresses to reach 'localhost'
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/auth/save-plan'; // Standard for browsers
    } else if (Platform.isAndroid) {
      // Use your specific computer IP if testing on a real Android device
      baseUrl = 'http://26.35.223.225:3000/auth/save-plan'; 
    } else {
      baseUrl = 'http://10.0.2.2:3000/auth/save-plan'; // Special alias for Android Emulators
    }

    // 3. Data Transformation (Mapping UI to DB Schema)
    // We convert the 'planStates' list into a List of Maps that match the Node.js 'req.body'
    final List<Map<String, dynamic>> exercisesJson = planStates.map((state) {
      // Find the category name for the current exercise
      final categoryName = categories.firstWhere(
        (cat) => cat.exercises.contains(state.name),
        orElse: () => categories[0],
      ).name;

      return {
        "category": categoryName,
        "name": state.name,
        // Convert Duration object to a string like "10m 0s" for the database TEXT column
        "duration": "${state.duration!.inMinutes}m ${state.duration!.inSeconds % 60}s",
        // Convert the 'Set' of days to a 'List' so PostgreSQL can save it as an ARRAY
        "days": state.days.toList(), 
      };
    }).toList();

    try {
      // 4. Client Setup (Handling Cookies/Sessions)
      var client = http.Client();

      if (kIsWeb) {
        // IMPORTANT: BrowserClient with 'withCredentials = true' ensures that
        // the Passport.js session cookie (connect.sid) is sent with the request.
        client = BrowserClient()..withCredentials = true;
      }

      // 5. Execution of the POST Request
      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          /// BACKEND: `/auth/save-plan` payload contract (nullable fields allowed)
          ///
          /// Required:
          /// - `plan_name`: String
          /// - `exercises`: List<Map>
          ///
          /// Optional (can be null due to checkboxes in Step 2):
          /// - `goal`: String?
          /// - `duration_weeks`: int?
          /// - `deadline`: String? (ISO 8601)
          /// - `current_weight`: double?
          /// - `goal_weight`: double?
          "plan_name": "My Custom Workout",
          "goal": selectedGoal,
          "duration_weeks": selectedWeeks,
          "deadline": selectedDeadline?.toIso8601String(),
          "current_weight": selectedCurrentWeight,
          "goal_weight": selectedGoalWeight,
          "exercises": exercisesJson,
        }),
      );

      // 6. Response Handling
      if (response.statusCode == 201) {
        // 201 Created means the backend 'COMMIT' was successful.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Plan saved to your account!")),
        );
        final name = PlanController.instance.generateNextPlanName();
        final exercises = planStates
            .map(
              (s) => PlanExercise(
                name: s.name,
                duration: s.duration ?? Duration.zero,
                days: s.days.toList(),
              ),
            )
            .toList();
        PlanController.instance.addNewPlan(
          name: name,
          goal: selectedGoal,
          deadline: selectedDeadline,
          durationWeeks: selectedWeeks,
          currentWeight: selectedCurrentWeight,
          goalWeight: selectedGoalWeight,
          exercises: exercises,
          setAsCurrent: true,
        );
        // Go to Main Shell after successful save
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        // If statusCode is 401 (Unauthorized) or 500 (Server Error)
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      // Catch network timeouts or connection refused errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save plan: $e")),
      );
    }
  }

  // --------------------------------------------------------------------------
  // UI LOGIC (Dialogs and Categories)
  // --------------------------------------------------------------------------

  void makePlanDialog(ExerciseCategory category) async {
    final existing = planStates
        .where((plan) => category.exercises.contains(plan.name))
        .toList();

    final List<DialogExerciseState>? result = await showDialog<List<DialogExerciseState>>(
      context: context,
      builder: (context) {
        return ExerciseSelectionDialog(
          category: category,
          existingPlans: existing,
        );
      },
    );

    if (result != null) {
      setState(() {
        planStates.removeWhere((item) => category.exercises.contains(item.name));
        if (result.isNotEmpty) {
          planStates.addAll(result);
          selectedCategories.add(category.name);
        } else {
          selectedCategories.remove(category.name);
        }
      });
    }
  }

  final List<ExerciseCategory> categories = [
    ExerciseCategory(
        name: 'Cardio',
        icons: ['assets/icons/cardio1.svg', 'assets/icons/cardio2.svg'],
        exercises: ['brisk walking', 'running', 'cycling', 'swimming', 'dancing', 'Jumping rope']),
    ExerciseCategory(
        name: 'Yoga',
        icons: ['assets/icons/yoga1.svg', 'assets/icons/yoga2.svg'],
        exercises: ['Downward Facing Dog', 'Mountain Pose', 'Tree Pose', 'Warrior 2', 'Cat Pose and Cow Pose', 'Chair Pose', 'Cobra Pose', 'Child\'s Pose']),
    ExerciseCategory(
        name: 'Strength Training',
        icons: ['assets/icons/strength_training1.svg', 'assets/icons/strength_training2.svg'],
        exercises: ['Squats', 'Deadlifts', 'Overhead Press', 'Push-ups', 'Pull-ups', 'Lunges', 'Rows', 'Kettlebell Swings', 'Planks', 'Burpees', 'Tricep Dips', 'Bicep Curls', 'Glute Bridges', 'Step-ups', 'Renegade Rows']),
    ExerciseCategory(
        name: 'Core Exercises',
        icons: ['assets/icons/core_exercises1.svg', 'assets/icons/core_exercises2.svg'],
        exercises: ['Plank', 'Crunches', 'Leg Raises', 'Glute Bridge', 'Bird Dog', 'Dead Bug', 'Russian Twists', 'Mountain Climbers', 'Hollow Hold', 'Side Plank with Rotation', 'Stability Ball Pike', 'Flutter Kicks', 'Bicycle Crunches', 'Reverse Crunches', 'Single-Arm Farmers Carry', 'Renegade Rows', 'Hanging Windshield Wipers']),
    ExerciseCategory(
        name: 'Stretching',
        icons: ['assets/icons/stretching1.svg', 'assets/icons/stretching2.svg'],
        exercises: ['Hamstring stretch', 'Standing calf stretch', 'Shoulder stretch', 'Triceps stretch', 'Knee to chest', 'Quad stretch', 'Cat Cow', 'Child\'s Pose', 'Quadriceps stretch', 'Kneeling hip flexor stretch', 'Side stretch', 'Chest and shoulder stretch', 'Neck Stretch', 'Spinal Twist', 'Bicep stretch', 'Cobra']),
    ExerciseCategory(
        name: 'Pilates',
        icons: ['assets/icons/pilates3.svg', 'assets/icons/pilates2.svg'],
        exercises: ['Pelvic Curl', 'Chest Lift', 'Chest Lift with Rotation', 'Spine Twist Supine', 'Single Leg Stretch', 'Roll Up', 'Roll-Like-a-Ball', 'Leg Circles']),
  ];

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
                      onTap: () => makePlanDialog(category),
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

                  // waits for the plan completion to be saved
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlanGoalScreen()),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        selectedGoal = result['goal'] as String?;
                        final weeks = result['durationWeeks'];
                        if (weeks is int) {
                          selectedWeeks = weeks;
                        } else {
                          selectedWeeks = null;
                        }
                        final deadline = result['deadline'];
                        if (deadline is DateTime) {
                          selectedDeadline = deadline;
                        } else {
                          selectedDeadline = null;
                        }
                        final cw = result['currentWeight'];
                        if (cw is num) {
                          selectedCurrentWeight = cw.toDouble();
                        } else {
                          selectedCurrentWeight = null;
                        }
                        final gw = result['goalWeight'];
                        if (gw is num) {
                          selectedGoalWeight = gw.toDouble();
                        } else {
                          selectedGoalWeight = null;
                        }
                      });
                    }
                    await savePlanToDatabase();
                  },

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