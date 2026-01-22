import 'package:flutter/material.dart';
import '../../../app_styles/color_constants.dart';
import '../../common/plan_controller.dart';

class HeroProgress extends StatelessWidget {
  final double progress;
  final Plan? plan;

  const HeroProgress({
    super.key,
    required this.progress,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      child: Column(
        children: [
          const Text(
            'Today\'s Workout Progress',
            style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              // Extra large progress ring
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: ColorConstants.accentColor, // Orange
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${plan?.completedToday ?? 0}/${plan?.totalExercises ?? 0} Exercises",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
