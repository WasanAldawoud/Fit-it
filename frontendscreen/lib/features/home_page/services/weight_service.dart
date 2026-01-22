import 'package:flutter/material.dart';
import '../../../app_styles/color_constants.dart';
import '../../common/plan_controller.dart';

class WeightService {
  static Future<void> promptWeight(BuildContext context, Plan plan) async {
    final controller = TextEditingController();

    if (plan.currentWeight != null) {
      controller.text = plan.currentWeight.toString();
    }

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Weekly Check-in'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter your weight (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: ColorConstants.primaryColor))
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final parsed = double.tryParse(text);
                Navigator.pop(context, parsed);
              },
              style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (value == null) return;

    plan.weightLog.add(WeightEntry(date: DateTime.now(), weight: value));
    plan.currentWeight = value;

    // Mark weight as prompted using the new strict weekly logic
    PlanController.instance.markWeightPrompted(plan);
    PlanController.instance.notifyCurrentPlanChanged();
  }

  static void showDeadlineAlert(BuildContext context, Plan plan) {
    DateTime? newDeadline;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('GO ON!! Don\'t give up'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your deadline has passed, but you haven\'t reached your goal yet!'),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: today.add(const Duration(days: 7)),
                        firstDate: today,
                        lastDate: today.add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          newDeadline = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              newDeadline == null
                                  ? 'Select new deadline'
                                  : '${newDeadline!.year}-${newDeadline!.month.toString().padLeft(2, '0')}-${newDeadline!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: newDeadline != null
                      ? () {
                          plan.deadline = newDeadline;
                          PlanController.instance.notifyCurrentPlanChanged();
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor),
                  child: const Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showGoalReachedAlert(BuildContext context, Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: const Text('You have reached your goal weight!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
            ),
            child: const Text('Great!'),
          )
        ],
      ),
    );
  }
}
