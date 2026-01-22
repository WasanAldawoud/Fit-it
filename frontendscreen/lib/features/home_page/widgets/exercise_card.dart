import 'package:flutter/material.dart';
import '../../../app_styles/color_constants.dart';
import '../../common/plan_controller.dart';

class ExerciseCard extends StatelessWidget {
  final PlanExercise exercise;
  final PlanExercise? activeExercise;
  final VoidCallback onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.activeExercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = activeExercise == exercise;
    bool isCompleted = exercise.remainingDuration.inSeconds <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isActive ? const BorderSide(color: ColorConstants.accentColor, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_off,
          color: isCompleted ? Colors.green : ColorConstants.primaryColor,
          size: 24,
        ),
        title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("${exercise.duration.inMinutes} min", style: const TextStyle(fontSize: 12)),
        onTap: onTap,
      ),
    );
  }
}
