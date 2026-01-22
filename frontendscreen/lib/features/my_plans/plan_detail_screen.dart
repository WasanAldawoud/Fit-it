import 'dart:async';
import 'package:flutter/material.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../plan_creation/presentation/widgets/duration_picker.dart';
import '../plan_creation/presentation/widgets/day_selection_dialog.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDays(List<String> days) {
    return days.join(', ');
  }

  Future<void> _editExercise(PlanExercise exercise, int index) async {
    // First, select duration
    final newDuration = await showHMSDurationPicker(context, initialDuration: exercise.duration);
    if (newDuration == null) return;

    // Then, select days
    final newDays = await showDialog<Set<String>>(
      context: context,
      builder: (context) => DaySelectionDialog(initialSelectedDays: exercise.days.toSet()),
    );
    if (newDays == null || newDays.isEmpty) return;

    // Update the exercise
    setState(() {
      exercise.duration = newDuration;
      exercise.days = newDays.toList();
      // Reset per-day tracking
      exercise.perDayRemainingDuration.clear();
      for (final day in exercise.days) {
        exercise.perDayRemainingDuration[day] = exercise.duration;
      }
    });
    PlanController.instance.notifyCurrentPlanChanged();
  }

  void _deleteExercise(int index) async {
    final exercise = widget.plan.exercises[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text('Are you sure you want to delete "${exercise.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        widget.plan.exercises.removeAt(index);
      });
      PlanController.instance.notifyCurrentPlanChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${exercise.name}" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.plan.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Info Header
              Container(
                color: ColorConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ColorConstants.accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.plan.goal ?? 'No Goal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.plan.deadline != null)
                          Text(
                            'Deadline: ${_formatDate(widget.plan.deadline!)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Exercises: ${widget.plan.exercises.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Exercises List
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exercises',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.plan.exercises.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Text(
                            'No exercises yet',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.plan.exercises.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final exercise = widget.plan.exercises[index];
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: ColorConstants.primaryColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: ColorConstants.primaryColor.withOpacity(0.15),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: ColorConstants.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${exercise.duration.inMinutes} min',
                                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _formatDays(exercise.days),
                                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: ColorConstants.primaryColor, size: 20),
                                      onPressed: () => _editExercise(exercise, index),
                                      tooltip: 'Edit exercise',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteExercise(index),
                                      tooltip: 'Delete exercise',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}