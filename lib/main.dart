import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';


void main() {
  runApp(const FitnessApp());
}


class DialogExerciseState {
  String name;
  Duration? duration; // nullable for it can be not set yet
  Set<String> days = {}; // Starts as an empty set of selected days

  DialogExerciseState({required this.name, this.duration});
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
  final List<String> exercises;

  const ExerciseCategory({
    required this.name,
    required this.icons,
    required this.exercises,
  });
}

// The Main Screen Widget
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => CreatePlanScreenState();
}

class CreatePlanScreenState extends State<CreatePlanScreen> {

  // Workout Plan
  final List<DialogExerciseState> planStates  = [];

  // Plan Dialog Building
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
        // Clear old plan for this category
        planStates.removeWhere((item) => category.exercises.contains(item.name));

        if (result.isNotEmpty) {
          // If the user confirmed with at least one exercise...
          planStates.addAll(result); // Add the new, updated plan
          selectedCategories.add(category.name); // MARK THE CARD AS SELECTED
        } else {
          // If the user confirmed with an EMPTY plan (or cleared it)...
          selectedCategories.remove(category.name); // MARK THE CARD AS DESELECTED
        }

      });
    }
  }

  // Exercise Categories
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
        name: 'Swimming',
        icons: ['assets/icons/swimming1.svg','assets/icons/swimming3.svg'],
        exercises: [] ),
    ExerciseCategory(
        name: 'Pilates',
        icons: ['assets/icons/pilates3.svg','assets/icons/pilates2.svg'],
        exercises: ['Pelvic Curl', 'Chest Lift', 'Chest Lift with Rotation', 'Spine Twist Supine', 'Single Leg Stretch', 'Roll Up', 'Roll-Like-a-Ball', 'Leg Circles'] ),
    ExerciseCategory(
        name: 'Stretching',
        icons: ['assets/icons/stretching1.svg','assets/icons/stretching2.svg'],
        exercises: ['Hamstring stretch', 'Standing calf stretch', 'Shoulder stretch', 'Triceps stretch', 'Knee to chest', 'Quad stretch', 'Cat Cow', 'Child\'s Pose', 'Quadriceps stretch', 'Kneeling hip flexor stretch', 'Side stretch', 'Chest and shoulder stretch', 'Neck Stretch', 'Spinal Twist', 'Bicep stretch', 'Cobra'] ),
    ExerciseCategory(
        name: 'Cycling',
        icons: ['assets/icons/cycling1.svg','assets/icons/cycling2.svg'],
        exercises: [] ),
  ];

  // Set to store the names of selected categories
  final Set<String> selectedCategories = {};

  // void toggleCategory(String categoryName) {
  //   setState(() {
  //     if (selectedCategories.contains(categoryName)) {
  //       selectedCategories.remove(categoryName);
  //     } else {
  //       selectedCategories.add(categoryName);
  //     }
  //   });
  // }

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
                        ((isSelected && (category.icons[1] == 'assets/icons/cardio2.svg')) ?
                        const Color(0xFFFF0000):
                        isSelected ?
                      const Color(0xFF0073E6) :
                      Color(0xFF00AEEF)),
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
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00B2FF),
            width: 1.5,
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

class ExerciseSelectionDialog extends StatefulWidget {
  final ExerciseCategory category;
  final List<DialogExerciseState> existingPlans;

  const ExerciseSelectionDialog({
    super.key,
    required this.category,
    this.existingPlans = const []
  });

  @override
  State<ExerciseSelectionDialog> createState() => ExerciseSelectionDialogState();
}

class ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {


  // A list to hold the temporary state for each exercise in the dialog
  late List<DialogExerciseState> planStates;

  final List<String> weekDays = ['Su', 'M', 'T', 'W', 'Th', 'F', 'Sa'];

  @override
  void initState() {
    super.initState();
    // When the dialog is created, initialize the plan states from the category data
    planStates = widget.category.exercises.map((exerciseName) {

      // existing plan check for the specific exercise
      final existing = widget.existingPlans.firstWhere(
          (plan)=> plan.name == exerciseName,
      // if found return it
    // if not create a new one
    orElse: () => DialogExerciseState(name: exerciseName)
      );

      return existing ;
    }).toList();
  }

  Future<Duration?> showDurationInputDialog(Duration? duration) async {

    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Pre-fill the text field if an initial duration exists
    if (duration != null) {
      final minutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      controller.text = '$minutes:$seconds';
    }

    // To parse the text
    Duration? parseDuration(String? input) {
      if (input == null) return null;
      try {
        final parts = input.split(':');
        if (parts.length == 2) {
          final minutes = int.parse(parts[0]);
          final seconds = int.parse(parts[1]);
          if (seconds < 60) {
            return Duration(minutes: minutes, seconds: seconds);
          }
        }
      } catch (e) { }
      return null;
    }

    return await showDialog<Duration>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Duration'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true, // Automatically focus on Text Field
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                DurationInputFormatter(), // this formats exist at the very bottom of this code
              ],
              decoration: const InputDecoration(
                labelText: 'Duration (MM:SS)',
                hintText: '05:30',
              ),
              validator: (value) {

                int seconds = int.parse(value!.split(':')[1]);
                if (seconds >= 60) {
                  return 'Seconds must be less than 60 SEC';
                }
                return null;
              }

            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {

                String input = controller.text;

                //fulfill 'MM:' automatically to 'MM:00'
                if(input.endsWith(':'))
                {
                  input += '00';
                  controller.text = input;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: input.length),
                  );
                }


                // validate the form
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(parseDuration(input));
                }

              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void pickTime(int index) async {

    //wait dialog result
    final Duration? newDuration = await showDurationInputDialog(
      planStates[index].duration, // Pass the existing duration
    );

      setState(() {
        planStates[index].duration = newDuration;
      });

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Plan Your ${widget.category.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: planStates.length,

          itemBuilder: (context, index) {

            final exerciseState = planStates[index];
            final durationText = exerciseState.duration != null
                ? '${exerciseState.duration!.inMinutes}Min ${exerciseState.duration!.inSeconds % 60}Sec'
                : 'Set Time';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exerciseState.name, style: const TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),

                  // Row for Days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((day) {
                      final isDaySelected = exerciseState.days.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isDaySelected) {
                              exerciseState.days.remove(day);
                            } else {
                              exerciseState.days.add(day);
                            }
                          });
                        },
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDaySelected ? Colors.blue : Colors.grey.shade300,
                          child: Text(day, style: TextStyle(color: isDaySelected ? Colors.white : Colors.black, fontSize: 10)),
                        ),
                      );
                    }).toList(),
                  ),




                  const SizedBox(height: 8),

                  // Row for Time
                  InkWell(
                    onTap: () => pickTime(index),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(durationText),
                          const Icon(Icons.timer_outlined),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            // Filter out exercises where a duration was not set
            final confirmedPlan = planStates.where((state) => state.duration != null).toList();
            Navigator.of(context).pop(confirmedPlan);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class DurationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String newText = newValue.text;
    final StringBuffer buffer = StringBuffer();
    int colonCount = 0;

    for (int i = 0; i < newText.length; i++) {
      if (newText[i] == ':') {
        colonCount++;
        if (colonCount > 1) { // Only allow one colon
          break;
        }
      }
      buffer.write(newText[i]);
    }

    String formattedText = buffer.toString();

    // Add colon automatically if two digits for minutes are entered
    if (formattedText.length == 2 && !formattedText.contains(':')) {
      formattedText += ':';
    }

    // Limit length to MM:SS (5 characters)
    if (formattedText.length > 5) {
      formattedText = formattedText.substring(0, 5);
    }

    if (formattedText == '00:00') { // Reset to empty if 00:00
      formattedText =  '';
    }




    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}