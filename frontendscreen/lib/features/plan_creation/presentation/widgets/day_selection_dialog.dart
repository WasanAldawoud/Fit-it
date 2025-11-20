import 'package:flutter/material.dart';


/// A dialog that allows the user to select days of the week.
///
/// This dialog provides two modes for selection:
/// - 'All Days': Selects every day of the week.
/// - 'Custom': Allows the user to pick specific days using checkboxes.
///
/// The dialog returns a `Set<String>` of the selected days when the user
/// confirms their selection.
class DaySelectionDialog extends StatefulWidget {
  /// The set of days that are initially selected when the dialog is opened.
  final Set<String> initialSelectedDays ;

  /// Creates a new instance of [DaySelectionDialog].
  ///
  /// The [initialSelectedDays] defaults to an empty set.
  const DaySelectionDialog({super.key, this.initialSelectedDays= const {}});

  @override
  DaySelectionDialogState createState() => DaySelectionDialogState();
}

/// The state for the [DaySelectionDialog].
class DaySelectionDialogState extends State<DaySelectionDialog> {

  /// The current selection mode, either 'All Days' or 'Custom'.
  String selectionType = 'All Days';

  /// The set of days selected when in 'Custom' mode.
  late Set<String> customSelectedDays;

  /// The list of available selection options.
  final List<String> selectionOptions = ['All Days', 'Custom'];

  /// A list of all days of the week.
  final List<String> allDays =
  ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  /// The set of currently selected days, which will be returned on confirmation.
  late Set<String> selectedDays;


  @override
  void initState() {
    super.initState();

    // Initialize the state based on the initial selected days from the widget.
    selectedDays = widget.initialSelectedDays.toSet();
    customSelectedDays = widget.initialSelectedDays.toSet();

    // Determine the initial selection type based on the number of selected days.
    if (selectedDays.length == 7) {
      selectionType = 'All Days';
    } else {
      selectionType = 'Custom';
    }

    // If no days were initially selected, default to 'All Days'.
    if (widget.initialSelectedDays.isEmpty)
      {
        selectedDays = allDays.toSet();
        selectionType = 'All Days';
      }

  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Workout Days'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio buttons to switch between 'All Days' and 'Custom' selection.
            Column(
              children: selectionOptions.map((option)
              {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectionType,
                  onChanged: (String? value)
                  {
                    if(value != null)
                    {
                      setState(() {
                        selectionType = value;
                      });

                      // Update the selected days based on the chosen selection type.
                      if (value == 'All Days') {
                        selectedDays = allDays.toSet();
                      }
                      else {
                        selectedDays = customSelectedDays;
                      }

                    }
                  },
                );
              }).toList(),
            ),



            // Animated cross-fade to show or hide the custom day checkboxes.
            AnimatedCrossFade(

              firstChild: Column(
                children: allDays.map((day) {
                  return CheckboxListTile(
                    title: Text(day),
                    value: selectedDays.contains(day),
                    onChanged: (bool? isChecked) {

                      setState(() {
                        if (isChecked == true) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              secondChild: Container(),

              crossFadeState: selectionType == 'Custom' ?
              CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () =>
              Navigator.of(context).pop(), // Return null on cancel
        ),
        TextButton(
          child: const Text('Confirm'),
          onPressed: () {
            // Return the final set of selected days.
            Navigator.of(context).pop(selectedDays);
          },
        ),
      ],
    );
  }
}
