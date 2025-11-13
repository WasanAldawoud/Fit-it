import 'package:flutter/material.dart';
import '../../data/models/dialog_exercise_state.dart';
import '../../data/models/exercise_category.dart';
import 'day_picker_row.dart';
import 'duration_picker.dart';


/// A dialog that allows users to select exercises from a given category.
///
/// This dialog displays a list of exercises from the provided [category].
/// For each exercise, the user can set a duration and select the days of the week
/// for the workout. It returns a list of [DialogExerciseState] for the configured exercises.
class ExerciseSelectionDialog extends StatefulWidget {
  /// The category of exercises to display in the dialog.
  final ExerciseCategory category;

  /// A list of existing exercise plans to pre-populate the dialog.
  final List<DialogExerciseState> existingPlans;

  /// Creates a new instance of [ExerciseSelectionDialog].
  ///
  /// The [category] is required. [existingPlans] is optional.
  const ExerciseSelectionDialog({
    super.key,
    required this.category,
    this.existingPlans = const []
  });

  @override
  State<ExerciseSelectionDialog> createState() => ExerciseSelectionDialogState();
}

/// The state for the [ExerciseSelectionDialog].
class ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {

  /// A list to hold the temporary state for each exercise in the dialog.
  /// This is initialized with existing plans or with default values.
  late List<DialogExerciseState> planStates;



  @override
  void initState() {
    super.initState();
    // When the dialog is created, initialize the plan states from the category data.
    planStates = widget.category.exercises.map((exerciseName) {

      // Check if there's an existing plan for this specific exercise.
      final existing = widget.existingPlans.firstWhere(
              (plan)=> plan.name == exerciseName,
          // If an existing plan is found, use it.
          // Otherwise, create a new DialogExerciseState.
          orElse: () => DialogExerciseState(name: exerciseName)
      );

      return existing ;
    }).toList();
  }

  /// Opens a duration picker for the exercise at the given [index].
  ///
  /// This method shows a modal bottom sheet with a duration picker. The selected
  /// duration is then used to update the state of the corresponding exercise.
  /// This is the recommended way to get a duration input from the user.
  void pickTime(int index) async {
    final Duration? newDuration = await showHMSDurationPicker(
      context,
      initialDuration: planStates[index].duration,
    );
    if (newDuration != null) {
      setState(() {
        planStates[index].duration = newDuration;
      });
    }
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

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(10.0),
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(exerciseState.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (exerciseState.duration != null && exerciseState.days.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear', // Add a tooltip for accessibility JUST A TIP
                          onPressed: () { // When user decide to clear the individual exercise after he has set it
                            setState(() { // He Just has to press the Close (X) icon button to clear the exercise
                              exerciseState.duration = null;
                              exerciseState.days.clear();
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // A row for picking the days of the week.
                  DayPickerRow(
                    selectedDays: exerciseState.days,
                    onDaysSelected: (newDays) {
                      setState(() {
                        exerciseState.days = newDays;
                      });
                    },
                  ),



                  const SizedBox(height: 8),

                  // A row for setting the exercise time.
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
        TextButton(
          onPressed: () {
            // Drop the entire plan for this category
            Navigator.of(context).pop(<DialogExerciseState>[]);
          },
          child: const Text('Drop Plan'),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {

           // Filter out exercises where a duration or days were not set.
            final confirmedPlan = planStates
                .where((state) => (state.duration != null && state.days.isNotEmpty)).toList();


            Navigator.of(context).pop(confirmedPlan);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }




}

