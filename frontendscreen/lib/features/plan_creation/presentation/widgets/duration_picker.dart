import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';




/// Shows a bottom sheet with a duration picker.
///
/// This picker allows the user to select a duration in hours, minutes, and seconds.
/// It includes quick preset options for common durations.
/// The selected duration is returned as a [Duration] object.
Future<Duration?> showHMSDurationPicker(BuildContext context ,{Duration? initialDuration}) async {


  final Duration init = initialDuration ?? const Duration(minutes: 1);
  Duration temp = init;

  return await showModalBottomSheet<Duration>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick presets for common durations.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {'label':'30s', 'dur': const Duration(seconds: 30)},
                  {'label':'1m',  'dur': const Duration(minutes: 1)},
                  {'label':'5m',  'dur': const Duration(minutes: 5)},
                  {'label':'10m', 'dur': const Duration(minutes: 10)},
                  {'label':'30m', 'dur': const Duration(minutes: 30)},
                  {'label':'1h', 'dur': const Duration(minutes: 60)},
                ].map((p) {
                  return ActionChip(
                    label: Text(p['label'] as String),
                    onPressed: () => Navigator.of(ctx).pop(p['dur'] as Duration),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // A wheel-based picker for hours, minutes, and seconds.
              SizedBox(
                height: 180,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: init,
                  minuteInterval: 1,
                  secondInterval: 1,
                  onTimerDurationChanged: (d) => temp = d,
                ),
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    child: const Text('Set'),
                    onPressed: () {
                      if (temp.inSeconds == 0) {
                        // Prevent setting a duration of 0.
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duration must be greater than 0')),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop(temp);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

