import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../common/main_shell.dart';
import '../plan_creation/presentation/screens/create_plan_screen.dart';
import '../choosing_screen/choosing_screen.dart';
import 'plan_detail_screen.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => MyPlansScreenState();
}

class MyPlansScreenState extends State<MyPlansScreen> {
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

  Future<void> _modifyPlan(Plan plan) async {
    // Navigate to CreatePlanScreen with existing plan for editing
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          existingPlan: plan,
          source: 'my_plans',
        ),
      ),
    );

    // After returning from edit, refresh the UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addNewPlanFlow() async {
    // Go to ChoosingScreen with back button enabled
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChoosingScreen(showBackButton: true),
      ),
    );

    // Refresh plans after returning
    if (mounted) {
      setState(() {});
    }
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
    }
  }

  void _deletePlan(Plan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Plan'),
          content: Text('Are you sure you want to delete \"${plan.name}\"? This cannot be undone.'),
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

    if (confirm != true) return;

    // Call backend to delete the plan
    final success = await _deletePlanFromBackend(plan.id);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete plan from server')),
      );
      return;
    }

    PlanController.instance.plans.remove(plan);
    if (PlanController.instance.currentPlan.value == plan) {
      if (PlanController.instance.plans.isNotEmpty) {
        PlanController.instance.setCurrentPlan(PlanController.instance.plans.first);
      } else {
        PlanController.instance.currentPlan.value = null;
      }
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('\"${plan.name}\" deleted')),
    );
  }

  Future<bool> _deletePlanFromBackend(int? planId) async {
    if (planId == null) return false;

    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000/auth/delete-plan';
    } else {
      baseUrl = 'http://26.35.223.225:3000/auth/delete-plan';
    }

    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.delete(
        Uri.parse('$baseUrl/$planId'),
        headers: {"Content-Type": "application/json"},
      );

      client.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Delete failed: $e");
      return false;
    }
  }

  void _selectDefault(Plan plan) {
    PlanController.instance.setCurrentPlan(plan);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} set as current plan')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Plan?>(
      valueListenable: PlanController.instance.currentPlan,
      builder: (context, currentPlan, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: ColorConstants.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              ),
            ),
            title: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'My Plans',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _addNewPlanFlow,
              ),
            ],
          ),
          body: Container(
            color: Colors.grey[50],
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: PlanController.instance.plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final plan = PlanController.instance.plans[index];
                final isDefault = currentPlan == plan;
                final isDeadlineReached = plan.deadline != null && DateTime.now().isAfter(plan.deadline!);

                return Card(
                  elevation: 4,
                  shadowColor: ColorConstants.primaryColor.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: ColorConstants.accentColor.withOpacity(0.2),
                          child: Icon(Icons.fitness_center, color: ColorConstants.accentColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlanDetailScreen(plan: plan),
                                ),
                              );
                            },
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
                                          fontSize: 17,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.accentColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.flag, size: 14, color: ColorConstants.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Goal: ${plan.goal ?? '—'}',
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: ColorConstants.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Deadline: ${plan.deadline == null ? '—' : _formatDate(plan.deadline!)}',
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 14, color: ColorConstants.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '~${plan.durationWeeks ?? '—'} weeks',
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (isDeadlineReached)
                                  const SizedBox(height: 8),
                                if (isDeadlineReached)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Deadline reached: ${_formatDate(plan.deadline!)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: isDefault ? ColorConstants.accentColor : Colors.grey,
                            size: 24,
                          ),
                          onPressed: () => _selectDefault(plan),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'rename') {
                              _renamePlan(plan);
                            } else if (value == 'delete') {
                              _deletePlan(plan);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note, size: 18),
                                  SizedBox(width: 8),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
