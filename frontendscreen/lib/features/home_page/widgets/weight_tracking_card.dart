import 'package:flutter/material.dart';
import '../../../app_styles/color_constants.dart';
import '../../common/plan_controller.dart';

class WeightTrackingCard extends StatefulWidget {
  final Plan plan;

  const WeightTrackingCard({
    super.key,
    required this.plan,
  });

  @override
  State<WeightTrackingCard> createState() => _WeightTrackingCardState();
}

class _WeightTrackingCardState extends State<WeightTrackingCard> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.plan.currentWeight?.toString() ?? '');
  }

  @override
  void didUpdateWidget(WeightTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.plan.currentWeight != oldWidget.plan.currentWeight) {
      _controller.text = widget.plan.currentWeight?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveWeight() {
    final double? newWeight = double.tryParse(_controller.text);
    if (newWeight != null) {
      widget.plan.currentWeight = newWeight;
      widget.plan.weightLog.add(WeightEntry(date: DateTime.now(), weight: newWeight));
      
      // Notify the controller that the plan has changed
      PlanController.instance.notifyCurrentPlanChanged();
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_weight,
                  color: ColorConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Weight Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _controller.text = widget.plan.currentWeight?.toString() ?? '';
                    });
                  },
                )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Weight',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isEditing
                          ? TextField(
                              controller: _controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.primaryColor,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                suffixText: 'kg',
                              ),
                            )
                          : Text(
                              widget.plan.currentWeight != null
                                  ? '${widget.plan.currentWeight!.toStringAsFixed(1)} kg'
                                  : 'Not recorded',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.plan.currentWeight != null
                                    ? ColorConstants.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                ElevatedButton.icon(
                  onPressed: _isEditing ? _saveWeight : () => setState(() => _isEditing = true),
                  icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 16),
                  label: Text(_isEditing ? 'Save' : 'Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
