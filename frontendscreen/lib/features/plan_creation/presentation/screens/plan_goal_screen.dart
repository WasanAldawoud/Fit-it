import 'package:flutter/material.dart';
import '../../../../app_styles/color_constants.dart';
import '../../../../app_styles/custom_widgets.dart';

class PlanGoalScreen extends StatefulWidget {
  const PlanGoalScreen({super.key});

  @override
  State<PlanGoalScreen> createState() => _PlanGoalScreenState();
}

class _PlanGoalScreenState extends State<PlanGoalScreen> {
  bool _goalEnabled = true;
  bool _deadlineEnabled = true;
  bool _currentWeightEnabled = false;
  bool _goalWeightEnabled = false;

  String _goal = 'Gain weight';
  DateTime? _deadline;

  final _currentWeightController = TextEditingController();
  final _goalWeightController = TextEditingController();

  final List<String> _goals = const [
    'Gain weight',
    'Lose weight',
    'Maintain weight',
    'Health care',
  ];

  @override
  void dispose() {
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final computedWeeks = _deadline == null
        ? null
        : ((_deadline!.difference(DateTime(now.year, now.month, now.day)).inDays) / 7).ceil();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Your Own Plan',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 2: Plan Settings',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _goalEnabled,
                                  onChanged: (v) => setState(() => _goalEnabled = v ?? true),
                                  activeColor: ColorConstants.primaryColor,
                                ),
                                const Text(
                                  'Goal',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: _goalEnabled ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_goalEnabled,
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 3.6,
                                  children: _goals.map((g) {
                                    final selected = g == _goal;
                                    return ChoiceChip(
                                      label: SizedBox(
                                        width: double.infinity,
                                        child: Text(g, textAlign: TextAlign.center),
                                      ),
                                      selected: selected,
                                      onSelected: (_) => setState(() => _goal = g),
                                      selectedColor: ColorConstants.primaryColor,
                                      labelStyle: TextStyle(
                                        color: selected ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      backgroundColor: Colors.grey.shade100,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _deadlineEnabled,
                                  onChanged: (v) => setState(() => _deadlineEnabled = v ?? true),
                                  activeColor: ColorConstants.primaryColor,
                                ),
                                const Text(
                                  'Deadline',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: _deadlineEnabled ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_deadlineEnabled,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _deadline ?? now.add(const Duration(days: 7)),
                                      firstDate: now,
                                      lastDate: DateTime(now.year + 5),
                                    );
                                    if (picked != null) {
                                      setState(() => _deadline = picked);
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event, color: Colors.black54),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _deadline == null
                                                ? 'Select target date'
                                                : '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (computedWeeks != null)
                                          Text('~$computedWeeks w', style: const TextStyle(color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _currentWeightEnabled,
                                  onChanged: (v) => setState(() => _currentWeightEnabled = v ?? false),
                                  activeColor: ColorConstants.primaryColor,
                                ),
                                const Text(
                                  'Current weight',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: _currentWeightEnabled ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_currentWeightEnabled,
                                child: TextField(
                                  controller: _currentWeightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(hintText: 'e.g. 72.5'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _goalWeightEnabled,
                                  onChanged: (v) => setState(() => _goalWeightEnabled = v ?? false),
                                  activeColor: ColorConstants.primaryColor,
                                ),
                                const Text(
                                  'Goal weight',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Opacity(
                              opacity: _goalWeightEnabled ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_goalWeightEnabled,
                                child: TextField(
                                  controller: _goalWeightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(hintText: 'e.g. 65.0'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                      title: 'Back',
                      onTap: () => Navigator.pop(context),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      title: 'Save & Continue',
                      onTap: () {
                        final currentWeight = double.tryParse(_currentWeightController.text.trim());
                        final goalWeight = double.tryParse(_goalWeightController.text.trim());

                        /// Step 2 result contract returned to Step 1 (CreatePlanScreen).
                        ///
                        /// Each setting has its own checkbox, so values can be null.
                        /// This is intentional: null means "user disabled this field".
                        ///
                        /// Keys returned (types):
                        /// - `goal`: String?
                        /// - `deadline`: DateTime?
                        /// - `durationWeeks`: int? (derived from deadline)
                        /// - `currentWeight`: double?
                        /// - `goalWeight`: double?
                        ///
                        /// BACKEND mapping (CreatePlanScreen -> /auth/save-plan):
                        /// - goal -> `goal`
                        /// - deadline -> `deadline` (ISO 8601 string)
                        /// - durationWeeks -> `duration_weeks`
                        /// - currentWeight -> `current_weight`
                        /// - goalWeight -> `goal_weight`
                        Navigator.pop(context, {
                          'goal': _goalEnabled ? _goal : null,
                          'deadline': _deadlineEnabled ? _deadline : null,
                          'durationWeeks': _deadlineEnabled ? computedWeeks : null,
                          'currentWeight': _currentWeightEnabled ? currentWeight : null,
                          'goalWeight': _goalWeightEnabled ? goalWeight : null,
                        });
                      },
                      backgroundColor: ColorConstants.primaryColor,
                      isWhiteText: true,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
