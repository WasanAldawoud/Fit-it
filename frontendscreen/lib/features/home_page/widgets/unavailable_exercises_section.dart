import 'package:flutter/material.dart';
import '../../../app_styles/color_constants.dart';
import '../../common/plan_controller.dart';

class UnavailableExercisesSection extends StatefulWidget {
  final Plan plan;
  final String todayDayName;

  const UnavailableExercisesSection({
    super.key,
    required this.plan,
    required this.todayDayName,
  });

  @override
  State<UnavailableExercisesSection> createState() => _UnavailableExercisesSectionState();
}

class _UnavailableExercisesSectionState extends State<UnavailableExercisesSection> {
  bool _showUnavailableExercises = false;

  @override
  Widget build(BuildContext context) {
    final unavailableExercises = widget.plan.exercises
        .where((ex) => !ex.days.contains(widget.todayDayName))
        .toList();

    if (unavailableExercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showUnavailableExercises = !_showUnavailableExercises;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _showUnavailableExercises ? Icons.expand_less : Icons.expand_more,
                        color: ColorConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Other Exercises This Week',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${unavailableExercises.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showUnavailableExercises)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: unavailableExercises.map((ex) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.fitness_center, color: Colors.grey.shade400, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Days: ${ex.days.join(", ")} • ${ex.duration.inMinutes} min',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
