import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../common/main_shell.dart';
import '../choosing_screen/choosing_screen.dart';
import 'plan_detail_screen.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen> {
  // Helper to format dates consistently
  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  void initState() {
    super.initState();
    // Fetch fresh data from the DB as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PlanController.instance.fetchAllPlans();
    });
  }

  // --- LOGIC: ADD NEW PLAN ---
  Future<void> _addNewPlanFlow() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChoosingScreen(showBackButton: true)),
    );
    // After returning, the PlanController should already have the new plan.
    // fetchAllPlans is usually called inside the creation flow, but we call it here to be safe.
    await PlanController.instance.fetchAllPlans();
    if (mounted) setState(() {});
  }

  // --- LOGIC: RENAME PLAN ---
  Future<void> _renamePlan(Plan plan) async {
    final controller = TextEditingController(text: plan.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Plan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter plan name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != plan.name) {
      String baseUrl = kIsWeb 
          ? 'http://localhost:3000' 
          : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://26.35.223.225:3000');
      
      try {
        var client = http.Client();
        if (kIsWeb) client = BrowserClient()..withCredentials = true;

        final response = await client.post(
          Uri.parse('$baseUrl/auth/rename-plan'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"plan_id": plan.id, "new_name": newName}),
        );

        if (response.statusCode == 200) {
          setState(() => plan.name = newName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan renamed successfully!')),
            );
          }
        }
        client.close();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to rename on server')),
          );
        }
      }
    }
  }

  // --- LOGIC: DELETE PLAN ---
  Future<void> _deletePlan(Plan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    String baseUrl = kIsWeb 
        ? 'http://localhost:3000' 
        : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://26.35.223.225:3000');
    
    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.post(Uri.parse('$baseUrl/auth/delete-plan/${plan.id}'));

      if (response.statusCode == 200) {
        PlanController.instance.plans.remove(plan);
        // Logic to switch active plan if the deleted one was current
        if (PlanController.instance.currentPlan.value == plan) {
          PlanController.instance.currentPlan.value = 
              PlanController.instance.plans.isNotEmpty ? PlanController.instance.plans.first : null;
        }
        setState(() {});
      }
      client.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting plan from server')),
        );
      }
    }
  }

  // --- LOGIC: SELECT DEFAULT ---
  void _selectDefault(Plan plan) {
    PlanController.instance.setCurrentPlan(plan);
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
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: ColorConstants.primaryColor,
            elevation: 0,
            title: const Text(
              'My Plans', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNewPlanFlow,
              ),
            ],
          ),
          body: PlanController.instance.plans.isEmpty 
          ? const Center(child: Text("No plans found. Create one!"))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: PlanController.instance.plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final plan = PlanController.instance.plans[index];
                final isDefault = currentPlan == plan;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan))
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: ColorConstants.accentColor.withOpacity(0.1),
                            child: Icon(Icons.fitness_center, color: ColorConstants.accentColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plan.name, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)
                                      )
                                    ),
                                    if (isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ColorConstants.accentColor, 
                                          borderRadius: BorderRadius.circular(20)
                                        ),
                                        child: const Text(
                                          'Active', 
                                          style: TextStyle(color: Colors.white, fontSize: 12)
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Goal: ${plan.goal ?? '—'}', 
                                  style: const TextStyle(color: Colors.black54, fontSize: 13)
                                ),
                                Text(
                                  'Deadline: ${plan.deadline == null ? '—' : _formatDate(plan.deadline!)}', 
                                  style: const TextStyle(color: Colors.black54, fontSize: 13)
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.check_circle, 
                              color: isDefault ? ColorConstants.accentColor : Colors.grey
                            ),
                            onPressed: () => _selectDefault(plan),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'rename') _renamePlan(plan);
                              if (val == 'delete') _deletePlan(plan);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'rename', child: Text('Rename')),
                              const PopupMenuItem(
                                value: 'delete', 
                                child: Text('Delete', style: TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        ],
                      ),
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