import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import '../widgets/exercise_selection_dialog.dart';
import'../../data/models/dialog_exercise_state.dart';
import'../../data/models/exercise_category.dart';
import '../../../../app_styles/color_constants.dart';
import '../../../common/main_shell.dart'; // To navigate after saving
import 'plan_goal_screen.dart';

import 'dart:convert'; // For jsonEncode
import 'package:http/http.dart' as http; // For network requests
import 'package:flutter/foundation.dart'; // For kIsWeb check
import 'package:http/browser_client.dart'; // Add this for Web support
import 'dart:io'; //to use it on device
import '../../../common/plan_controller.dart';

/// A screen where users can create a custom workout plan.
///
/// This screen displays a grid of exercise categories. Tapping a category
/// opens a dialog to select exercises and set their duration and days.
class CreatePlanScreen extends StatefulWidget {
  final Plan? existingPlan;
  final String? source;

  const CreatePlanScreen({
    super.key,
    this.existingPlan,
    this.source,
  });

  @override
  State<CreatePlanScreen> createState() => CreatePlanScreenState();
}

class CreatePlanScreenState extends State<CreatePlanScreen> {

  /// This list holds the state of all exercises selected by the user across all categories.
  /// Each [DialogExerciseState] contains the exercise name, duration, and selected days.
  /// This is the main data structure representing the user's workout plan.
  final List<DialogExerciseState> planStates  = [];

  /// Plan name (editable at Step 1)
  late String _planName;

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

  /// Whether this is an edit mode (modifying existing plan)
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingPlan != null;
    
    // Initialize plan name
    if (_isEditMode) {
      _planName = widget.existingPlan!.name;
    } else {
      _planName = PlanController.instance.generateNextPlanName();
    }
    
    // If editing existing plan, load its data
    if (_isEditMode) {
      final plan = widget.existingPlan!;
      selectedGoal = plan.goal;
      selectedDeadline = plan.deadline;
      selectedWeeks = plan.durationWeeks;
      selectedCurrentWeight = plan.currentWeight;
      selectedGoalWeight = plan.goalWeight;
      
      // Load existing exercises
      for (final exercise in plan.exercises) {
        final state = DialogExerciseState(
          name: exercise.name,
          duration: exercise.duration,
        );
        state.days = Set<String>.from(exercise.days);
        planStates.add(state);
        
        // Mark categories as selected
        final categoryName = categories.firstWhere(
          (cat) => cat.exercises.contains(exercise.name),
          orElse: () => categories[0],
        ).name;
        selectedCategories.add(categoryName);
      }
    }
  }

  /// Opens a dialog to select exercises for a given [category].
  ///
  /// This method shows an [ExerciseSelectionDialog] populated with exercises
  /// from the selected [category]. It passes any existing plan states for that
  /// category to the dialog.
  ///
  /// When the dialog is closed, it updates the [planStates] with the new or
  /// modified exercise selections.

  void _showRenamePlanDialog() async {
    final controller = TextEditingController(text: _planName);
    String? errorText;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rename Plan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter plan name',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty) {
                        setState(() => errorText = 'Plan name cannot be empty');
                      } else {
                        // Check for existing plan names (case-insensitive)
                        final exists = PlanController.instance.plans.any(
                          (p) => p.name.toLowerCase() == trimmed.toLowerCase() && p != widget.existingPlan
                        );
                        setState(() => errorText = exists ? 'Plan name already exists' : null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: errorText == null && controller.text.trim().isNotEmpty
                      ? () => Navigator.pop(context, controller.text.trim())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _planName = newName;
      });
    }
  }

  Future<void> savePlanToDatabase() async {
    if (planStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one exercise")),
      );
      return;
    }

    // Determine URL based on platform (Same logic as your Sign-up)
   String baseUrl;

 if (kIsWeb) {
  baseUrl = 'http://localhost:3000/auth/save-plan'; // 
} else if (Platform.isAndroid) {
  baseUrl = 'http://10.0.2.2:3000/auth/save-plan'; // 
} else {
  baseUrl = 'http://localhost:3000/auth/save-plan'; // 
}
    // Map your planStates (UI) to the Database Schema
    final List<Map<String, dynamic>> exercisesJson = planStates.map((state) {
      // Logic to find which category this exercise belongs to
      final categoryName = categories.firstWhere(
        (cat) => cat.exercises.contains(state.name),
        orElse: () => categories[0],
      ).name;

      return {
        "category": categoryName,
        "name": state.name,
        // Convert Duration to string "MM:SS"
        "duration": "${state.duration!.inMinutes}m ${state.duration!.inSeconds % 60}s",
        "days": state.days.toList(), // Convert Set to List for PostgreSQL TEXT[]
      };
    }).toList();

    try {
    // --- THE FIX STARTS HERE ---
      // We create a special 'client' that is capable of sending cookies on Web
      var client = http.Client();

      if (kIsWeb) {
        // This line tells the browser: "Attach the Session Cookie to this request"
        client = BrowserClient()..withCredentials = true;
      }

      final payload = {
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
        "plan_name": _planName,
        "goal": selectedGoal,
        "duration_weeks": selectedWeeks,
        "deadline": selectedDeadline?.toIso8601String(),
        "current_weight": selectedCurrentWeight,
        "goal_weight": selectedGoalWeight,
        "exercises": exercisesJson,
      };

      // For edit mode, include plan_id to update existing plan
      if (_isEditMode) {
        payload["plan_id"] = widget.existingPlan!.id;
      }

      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Plan saved to your account!")),
        );
        
        final exercises = planStates
            .map(
              (s) => PlanExercise(
                name: s.name,
                duration: s.duration ?? Duration.zero,
                days: s.days.toList(),
              ),
            )
            .toList();
        
        if (_isEditMode) {
          // Update existing plan
          final plan = widget.existingPlan!;
          PlanController.instance.updatePlan(
            plan,
            goal: selectedGoal,
            deadline: selectedDeadline,
            durationWeeks: selectedWeeks,
            currentWeight: selectedCurrentWeight,
            goalWeight: selectedGoalWeight,
            exercises: exercises,
            currentWeightEnabledAtCreation: selectedCurrentWeight != null,
          );
        } else {
          // Create new plan
          final name = PlanController.instance.generateNextPlanName();
          PlanController.instance.addNewPlan(
            name: name,
            goal: selectedGoal,
            deadline: selectedDeadline,
            durationWeeks: selectedWeeks,
            currentWeight: selectedCurrentWeight,
            goalWeight: selectedGoalWeight,
            exercises: exercises,
            setAsCurrent: true,
            currentWeightEnabledAtCreation: selectedCurrentWeight != null,
          );
        }
        
        // Go to Main Shell after successful save
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save plan: $e")),
      );
    }
  }
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
          // Remove any potential duplicates before adding
          for (final newExercise in result) {
            planStates.removeWhere((existing) => existing.name == newExercise.name);
          }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // If editing from my_plans, go back to my_plans
            // If creating new or from elsewhere, just pop
            if (_isEditMode && widget.source == 'my_plans') {
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isEditMode ? 'Edit Plan - Step 1' : 'Create Your Own Plan - Step 1',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Name Button (Editable)
              TextButton.icon(
                onPressed: _showRenamePlanDialog,
                icon: const Icon(Icons.edit),
                label: Text(
                  _planName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ColorConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditMode ? 'Step 1: Edit Exercise Categories' : 'Step 1: Choose Exercise Categories',
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