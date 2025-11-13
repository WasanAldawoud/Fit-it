/// A widget that displays a row for picking days of the week.
///
/// This widget shows the currently selected days and opens a [DaySelectionDialog]
/// when tapped to allow the user to modify the selection.
import 'package:flutter/material.dart';
import 'day_selection_dialog.dart';



class DayPickerRow extends StatelessWidget {
  /// The set of currently selected days (e.g., {"Monday", "Wednesday"}).
  final Set<String> selectedDays;
  /// A callback that is invoked when the user selects a new set of days.
  final ValueChanged<Set<String>> onDaysSelected;

  const DayPickerRow({
    super.key,
    required this.selectedDays,
    required this.onDaysSelected,
  });

  /// Formats the set of selected days into a display string.
  ///
  /// For example, `{"Monday", "Wednesday"}` becomes `"Mon Wed"`.
  /// If no days are selected, it returns "Select Days".
  String formatSelectedDays() {
    if (selectedDays.isEmpty) {
      return 'Select Days';
    }


    const dayForm = {
      'Sunday': 'Sun', 'Monday': 'Mon', 'Tuesday': 'Tue', 'Wednesday': 'Wed',
      'Thursday': 'Thu', 'Friday': 'Fri', 'Saturday': 'Sat'
    };


    final sortedDays = selectedDays.toList()
      ..sort((a, b) => dayForm.keys.toList().indexOf(a).compareTo(dayForm.keys.toList().indexOf(b)));

    return sortedDays.map((day) => dayForm[day]).join(' ');
  }


  /// Shows the [DaySelectionDialog] to allow the user to pick days.
  ///
  /// When the dialog is closed, the `onDaysSelected` callback is invoked
  /// with the new set of selected days.
  void showDaySelectionDialog(BuildContext context) async {
    final Set<String>? result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => DaySelectionDialog(initialSelectedDays: selectedDays),
    );

    if (result != null) {
      onDaysSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDaySelectionDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Days \t', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  formatSelectedDays(),
                  style: TextStyle(color: selectedDays.isEmpty ? Colors.grey : Colors.black ),
                  textAlign : TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
      ),
    );
  }
}
