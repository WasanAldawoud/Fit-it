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
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              ),
            ),
            title: const Text(
              'My Plans',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
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
              final isDeadlineReached = plan.deadline != null && DateTime.now().isAfter(plan.deadline!);

              return Container(
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
                            if (isDeadlineReached)
                              const SizedBox(height: 6),
                            if (isDeadlineReached)
                              Text(
                                'Final Date Reached at ${_formatDate(plan.deadline!)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                      ),
                      onPressed: () => _selectDefault(plan),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _modifyPlan(plan);
                        } else if (value == 'rename') {
                          _renamePlan(plan);
                        } else if (value == 'delete') {
                          _deletePlan(plan);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Modify'),
                            ],
                          ),
                        ),
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
              );
            },
          ),
        );
      },
    );
  }
}
