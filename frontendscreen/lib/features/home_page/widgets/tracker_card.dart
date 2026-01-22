import 'package:flutter/material.dart';
import '../../../app_styles/color_constants.dart';
import '../../common/plan_controller.dart';

class TrackerCard extends StatelessWidget {
  final PlanExercise? activeExercise;
  final bool isRunning;
  final VoidCallback? onStartPause;
  final VoidCallback? onReset;
  final String todayDayName;

  const TrackerCard({
    super.key,
    required this.activeExercise,
    required this.isRunning,
    required this.onStartPause,
    required this.onReset,
    required this.todayDayName,
  });

  String _formatDuration(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  Duration _getRemainingTime() {
    if (activeExercise == null) return Duration.zero;

    final remaining = activeExercise!.perDayRemainingDuration[todayDayName];
    if (remaining == null) {
      return activeExercise!.duration;
    }
    return remaining;
  }

  Widget _buildSmallControlButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null ? Colors.grey.shade200 : color.withValues(alpha:0.15),
        ),
        child: Icon(icon, color: onTap == null ? Colors.grey : color, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeExercise?.name ?? 'Select Exercise',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                Text(
                  _formatDuration(_getRemainingTime()),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // COMPACT START/PAUSE
          _buildSmallControlButton(
            icon: isRunning ? Icons.pause : Icons.play_arrow,
            color: ColorConstants.primaryColor,
            onTap: activeExercise == null ? null : onStartPause,
          ),
          const SizedBox(width: 12),
          // COMPACT RESET
          _buildSmallControlButton(
            icon: Icons.refresh,
            color: Colors.grey.shade400,
            onTap: activeExercise == null ? null : onReset,
          ),
        ],
      ),
    );
  }
}
