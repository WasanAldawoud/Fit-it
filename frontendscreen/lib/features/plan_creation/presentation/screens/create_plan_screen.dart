import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import '../widgets/exercise_selection_dialog.dart';
import '../../data/models/dialog_exercise_state.dart';
import '../../data/models/exercise_category.dart';
import '../../../common/main_shell.dart'; 
import 'plan_goal_screen.dart';
import '../../../common/plan_controller.dart';
import '../../../../app_styles/color_constants.dart';

import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:flutter/foundation.dart'; 
import 'package:http/browser_client.dart'; 
import 'dart:io'; 

class CreatePlanScreen extends StatefulWidget {
  // 1. Parameters MUST be defined here in the Widget class
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
  // 2. State variables
  late String _planName;
  final List<DialogExerciseState> planStates = [];
  final Set<String> selectedCategories = {};
  
  late bool _isEditMode;

  // Step 2 variables
  String? selectedGoal;
  int? selectedWeeks;
  DateTime? selectedDeadline;
  double? selectedCurrentWeight;
  double? selectedGoalWeight;

  @override
  void initState() {
    super.initState();
    
    // 3. Initialize logic for Edit vs Create
    _isEditMode = widget.existingPlan != null;
    
    if (_isEditMode) {
      final plan = widget.existingPlan!;
      _planName = plan.name;
      selectedGoal = plan.goal;
      selectedDeadline = plan.deadline;
      selectedWeeks = plan.durationWeeks;
      selectedCurrentWeight = plan.currentWeight;
      selectedGoalWeight = plan.goalWeight;
      
      // Load exercises into planStates
      for (final exercise in plan.exercises) {
        final state = DialogExerciseState(
          name: exercise.name,
          duration: exercise.duration,
        );
        state.days = Set<String>.from(exercise.days);
        planStates.add(state);
        
        // Find category for the UI highlights
        try {
          final categoryName = categories.firstWhere(
            (cat) => cat.exercises.contains(exercise.name)
          ).name;
          selectedCategories.add(categoryName);
        } catch (_) {}
      }
    } else {
      _planName = PlanController.instance.generateNextPlanName();
    }
  }

  // --- Logic Methods ---

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
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter plan name',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  if (value.trim().isEmpty) {
                    setState(() => errorText = 'Name cannot be empty');
                  } else {
                    setState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: errorText == null && controller.text.trim().isNotEmpty 
                    ? () => Navigator.pop(context, controller.text.trim()) 
                    : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newName != null) {
      setState(() => _planName = newName);
    }
  }

  Future<void> savePlanToDatabase() async {
    if (planStates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one exercise")),
      );
      return;
    }

    String baseUrl = kIsWeb 
        ? 'http://localhost:3000/auth/save-plan' 
        : (Platform.isAndroid ? 'http://10.0.2.2:3000/auth/save-plan' : 'http://26.35.223.225:3000/auth/save-plan');

    final List<Map<String, dynamic>> exercisesJson = planStates.map((state) {
      final categoryName = categories.firstWhere(
        (cat) => cat.exercises.contains(state.name),
        orElse: () => categories[0],
      ).name;

      return {
        "category": categoryName,
        "name": state.name,
        "duration": "${state.duration!.inMinutes}m ${state.duration!.inSeconds % 60}s",
        "days": state.days.toList(), 
      };
    }).toList();

    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final Map<String, dynamic> payload = {
        "plan_name": _planName,
        "goal": selectedGoal,
        "duration_weeks": selectedWeeks,
        "deadline": selectedDeadline?.toIso8601String(),
        "current_weight": selectedCurrentWeight,
        "goal_weight": selectedGoalWeight,
        "exercises": exercisesJson,
      };

      // Add plan_id if editing
      if (_isEditMode) {
        payload["plan_id"] = widget.existingPlan!.id;
      }

      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan saved successfully!")));
        
        await PlanController.instance.fetchAllPlans(); // Refresh global state
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save plan: $e")));
    }
  }

  void makePlanDialog(ExerciseCategory category) async {
    final existing = planStates.where((plan) => category.exercises.contains(plan.name)).toList();

    final List<DialogExerciseState>? result = await showDialog<List<DialogExerciseState>>(
      context: context,
      builder: (context) => ExerciseSelectionDialog(
        category: category,
        existingPlans: existing,
      ),
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
    ExerciseCategory(name: 'Cardio', icons: ['assets/icons/cardio1.svg', 'assets/icons/cardio2.svg'], exercises: ['brisk walking', 'running', 'cycling', 'swimming', 'dancing', 'Jumping rope']),
    ExerciseCategory(name: 'Yoga', icons: ['assets/icons/yoga1.svg', 'assets/icons/yoga2.svg'], exercises: ['Downward Facing Dog', 'Mountain Pose', 'Tree Pose', 'Warrior 2', 'Cat Pose and Cow Pose', 'Chair Pose', 'Cobra Pose', 'Child\'s Pose']),
    ExerciseCategory(name: 'Strength Training', icons: ['assets/icons/strength_training1.svg', 'assets/icons/strength_training2.svg'], exercises: ['Squats', 'Deadlifts', 'Overhead Press', 'Push-ups', 'Pull-ups', 'Lunges', 'Rows', 'Kettlebell Swings', 'Planks', 'Burpees', 'Tricep Dips', 'Bicep Curls', 'Glute Bridges', 'Step-ups', 'Renegade Rows']),
    ExerciseCategory(name: 'Core Exercises', icons: ['assets/icons/core_exercises1.svg', 'assets/icons/core_exercises2.svg'], exercises: ['Plank', 'Crunches', 'Leg Raises', 'Glute Bridge', 'Bird Dog', 'Dead Bug', 'Russian Twists', 'Mountain Climbers', 'Hollow Hold', 'Side Plank with Rotation', 'Stability Ball Pike', 'Flutter Kicks', 'Bicycle Crunches', 'Reverse Crunches', 'Single-Arm Farmers Carry', 'Renegade Rows', 'Hanging Windshield Wipers']),
    ExerciseCategory(name: 'Stretching', icons: ['assets/icons/stretching1.svg', 'assets/icons/stretching2.svg'], exercises: ['Hamstring stretch', 'Standing calf stretch', 'Shoulder stretch', 'Triceps stretch', 'Knee to chest', 'Quad stretch', 'Cat Cow', 'Child\'s Pose', 'Quadriceps stretch', 'Kneeling hip flexor stretch', 'Side stretch', 'Chest and shoulder stretch', 'Neck Stretch', 'Spinal Twist', 'Bicep stretch', 'Cobra']),
    ExerciseCategory(name: 'Pilates', icons: ['assets/icons/pilates3.svg', 'assets/icons/pilates2.svg'], exercises: ['Pelvic Curl', 'Chest Lift', 'Chest Lift with Rotation', 'Spine Twist Supine', 'Single Leg Stretch', 'Roll Up', 'Roll-Like-a-Ball', 'Leg Circles']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode ? 'Edit Your Plan' : 'Create Your Own Plan',
                style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showRenamePlanDialog,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(_planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: ColorConstants.primaryColor, padding: EdgeInsets.zero),
              ),
              Text(
                'Step 1: Choose Exercise Categories',
                style: TextStyle(fontSize: 16.0, color: Colors.grey[900]),
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
                    return CategoryCard(
                      category: category,
                      isSelected: selectedCategories.contains(category.name),
                      onTap: () => makePlanDialog(category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00AEEF), Color(0xFF00D1D1)]),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlanGoalScreen()),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        selectedGoal = result['goal'];
                        selectedWeeks = result['durationWeeks'];
                        selectedDeadline = result['deadline'];
                        selectedCurrentWeight = (result['currentWeight'] as num?)?.toDouble();
                        selectedGoalWeight = (result['goalWeight'] as num?)?.toDouble();
                      });
                    }
                    await savePlanToDatabase();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}