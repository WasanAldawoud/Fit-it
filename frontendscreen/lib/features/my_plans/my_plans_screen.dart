import 'package:flutter/material.dart';
import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../common/main_shell.dart';
import '../choosing_screen/choosing_screen.dart';
import '../plan_creation/presentation/screens/create_plan_screen.dart';

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
    // Ensure at least one plan exists
    if (PlanController.instance.plans.isEmpty) {
      PlanController.instance.addNewPlan();
    }
  }

  Future<void> _addNewPlanFlow() async {
    // Go to choosing flow with 'my_plans' as source to show back button
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChoosingScreen(
          showBackButton: true,
          source: 'my_plans',
        ),
      ),
    );
    // After returning, create the plan with the first available name and set as current
    final plan = PlanController.instance.addNewPlan(setAsCurrent: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} created and set as current')),
    );
    // Navigate to Home (MainShell default index = Home)
    if (!mounted) return;
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
              style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      // If name exists, auto-increment until unique
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

  void _modifyPlan(Plan plan) async {
    // Navigate to CreatePlanScreen with the existing plan for editing
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          existingPlan: plan,
          source: 'my_plans',
        ),
      ),
    );
    // Refresh UI after returning from edit
    setState(() {});
  }

  void _modifyPlanQuick(Plan plan) async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modify Plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.deadline != null) ...[_buildModifyField('Deadline', plan, 'deadline', setState), const SizedBox(height: 12)],
                    if (plan.currentWeight != null) ...[_buildModifyField('Current Weight', plan, 'currentWeight', setState), const SizedBox(height: 12)],
                    if (plan.goalWeight != null) ...[_buildModifyField('Goal Weight', plan, 'goalWeight', setState), const SizedBox(height: 12)],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {}); // Update UI after modifications
  }

  Widget _buildModifyField(String label, Plan plan, String fieldType, StateSetter setState) {
    if (fieldType == 'deadline') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: plan.deadline ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) {
                setState(() {
                  plan.deadline = picked;
                  final now = DateTime.now();
                  plan.durationWeeks = ((picked.difference(DateTime(now.year, now.month, now.day)).inDays) / 7).ceil();
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${plan.deadline!.year}-${plan.deadline!.month.toString().padLeft(2, '0')}-${plan.deadline!.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      );
    } else if (fieldType == 'currentWeight') {
      final controller = TextEditingController(text: plan.currentWeight?.toString() ?? '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter weight in kg',
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                setState(() {
                  plan.currentWeight = parsed;
                });
              }
            },
          ),
        ],
      );
    } else if (fieldType == 'goalWeight') {
      final controller = TextEditingController(text: plan.goalWeight?.toString() ?? '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter goal weight in kg',
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                setState(() {
                  plan.goalWeight = parsed;
                });
              }
            },
          ),
        ],
      );
    }
    return const SizedBox();
  }

  void _selectDefault(Plan plan) {
    PlanController.instance.setCurrentPlan(plan);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} set as current plan')),
    );
    // Navigate to Home (MainShell default index = Home)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
          ),
        ),
        title: const Text('My Plans', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: ColorConstants.primaryColor),
            onPressed: _addNewPlanFlow,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final plan = PlanController.instance.plans[index];
          final isDefault = PlanController.instance.currentPlan.value == plan;
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ColorConstants.accentColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Goal: ${plan.goal ?? '—'}  •  Deadline: ${plan.deadline == null ? '—' : _formatDate(plan.deadline!)}  •  ~${plan.durationWeeks ?? '—'}w',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (plan.deadline != null && DateTime.now().isAfter(plan.deadline!))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Final Date Reached at ${_formatDate(plan.deadline!)}',
                              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Rename'),
                        onTap: () => _renamePlan(plan),
                      ),
                      PopupMenuItem(
                        child: const Text('Modify Plan'),
                        onTap: () => _modifyPlan(plan),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: PlanController.instance.plans.length,
      ),
    );
  }
}

