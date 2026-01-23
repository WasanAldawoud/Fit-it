import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart'; // For Web session cookies
import 'dart:convert';
import 'dart:io';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../common/app_nav_bar.dart';
import '../common/main_shell.dart';
import '../plan_creation/presentation/screens/create_plan_screen.dart';
import '../plan_creation/presentation/widgets/duration_picker.dart';
import '../plan_creation/presentation/widgets/day_selection_dialog.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  bool _isSyncing = false; // To show a loading indicator during DB updates

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDays(List<String> days) {
    return days.join(', ');
  }

  /// NEW: Helper to sync all changes to the PostgreSQL database
  Future<void> _syncWithBackend() async {
    setState(() => _isSyncing = true);
    
    String baseUrl = kIsWeb 
        ? 'http://localhost:3000' 
        : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://26.35.223.225:3000');

    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.post(
        Uri.parse('$baseUrl/auth/update-plan-exercises'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "plan_id": widget.plan.id,
          "exercises": widget.plan.exercises.map((ex) => {
            "name": ex.name,
            "duration": "${ex.duration.inMinutes}m ${ex.duration.inSeconds % 60}s",
            "days": ex.days,
          }).toList(),
        }),
      );

      if (response.statusCode != 200) throw Exception("Failed to sync");
      
      client.close();
    } catch (e) {
      debugPrint("❌ Sync Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud sync failed. Changes saved locally.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _editExercise(PlanExercise exercise, int index) async {
    final newDuration = await showHMSDurationPicker(context, initialDuration: exercise.duration);
    if (newDuration == null) return;

    final newDays = await showDialog<Set<String>>(
      context: context,
      builder: (context) => DaySelectionDialog(initialSelectedDays: exercise.days.toSet()),
    );
    if (newDays == null || newDays.isEmpty) return;

    setState(() {
      exercise.duration = newDuration;
      exercise.days = newDays.toList();
      exercise.perDayRemainingDuration.clear();
      for (final day in exercise.days) {
        exercise.perDayRemainingDuration[day] = exercise.duration;
      }
    });
    
    PlanController.instance.notifyCurrentPlanChanged();
    await _syncWithBackend(); // SYNC TO DB
  }

  void _deleteExercise(int index) async {
    final exercise = widget.plan.exercises[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"?'),
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

    if (confirm == true) {
      setState(() {
        widget.plan.exercises.removeAt(index);
      });
      PlanController.instance.notifyCurrentPlanChanged();
      await _syncWithBackend(); // SYNC TO DB
    }
  }

  Future<void> _modifyPlan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          existingPlan: widget.plan,
          source: 'plan_details',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.primaryColor,
        elevation: 0,
        title: Text(widget.plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_isSyncing) 
            const Padding(
              padding: EdgeInsets.all(12.0), 
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            ),
          IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: _modifyPlan),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header UI (omitted for brevity, keep your original header code here)
              _buildHeader(), 
              
              // Exercise List
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(20),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.plan.exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ex = widget.plan.exercises[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${ex.duration.inMinutes}m | ${_formatDays(ex.days)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editExercise(ex, index)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteExercise(index)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Paste your existing header Column here (Goal, Deadline, Exercise count)
    return const SizedBox.shrink(); // Placeholder
  }
}