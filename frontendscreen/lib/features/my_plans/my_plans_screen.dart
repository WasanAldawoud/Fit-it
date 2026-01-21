import 'dart:async';
import 'package:flutter/material.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../common/main_shell.dart';
import '../choosing_screen/choosing_screen.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen> {
  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
  

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await PlanController.instance.fetchAllPlans();
  });
}


  Future<void> _addNewPlanFlow() async {
    // Go to choosing flow first
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChoosingScreen()),
    );

    // After returning, create the plan locally
    final plan = PlanController.instance.addNewPlan(setAsCurrent: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} created and set as current')),
    );

    // Navigate to MainShell (Home)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _renamePlan(Plan plan) async {
    final controller = TextEditingController(text: plan.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Plan'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter plan name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      String candidate = newName;
      int i = 2;
      final list = PlanController.instance.plans;
      while (list.any((p) => p != plan && p.name.toLowerCase() == candidate.toLowerCase())) {
        candidate = '$newName $i';
        i++;
      }
      setState(() {
        plan.name = candidate;
      });
      // Note: You may want to add a backend PUT request here to update the plan name in DB
    }
  }

  void _selectDefault(Plan plan) {
    // 1. Update the controller state
    PlanController.instance.setCurrentPlan(plan);
    
    // 2. Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} set as current plan')),
    );
    
    // 3. Navigate back to the MainShell (where HomePage/Progress is)
    // pushAndRemoveUntil ensures the user can't "Go Back" to the plan list incorrectly
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the current plan to update UI markers (like the 'Default' chip)
    return ValueListenableBuilder<Plan?>(
      valueListenable: PlanController.instance.currentPlan,
      builder: (context, currentPlan, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'My Plans',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: ColorConstants.primaryColor),
                onPressed: _addNewPlanFlow,
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: PlanController.instance.plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = PlanController.instance.plans[index];
              final isDefault = currentPlan == plan;

              return InkWell(
                onTap: () => _selectDefault(plan),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ColorConstants.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.fitness_center, color: ColorConstants.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.accentColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Goal: ${plan.goal ?? '—'} • Deadline: ${plan.deadline == null ? '—' : _formatDate(plan.deadline!)} • ~${plan.durationWeeks ?? '—'}w',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _renamePlan(plan),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}