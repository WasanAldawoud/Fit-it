/// Represents the state of an exercise within a dialog.
///
/// This class holds the information about an exercise that is being
/// created or edited in a dialog, including its [name], [duration],
/// and the selected [days].
class DialogExerciseState {
  /// The name of the exercise.
  String name;

  /// The duration of the exercise. Can be null if not yet set.
  Duration? duration; // nullable for it can be not set yet

  /// The set of days on which the exercise should be performed.
  Set<String> days = {}; // Starts as an empty set of selected days

  /// Creates a new instance of [DialogExerciseState].
  ///
  /// The [name] is required. The [duration] is optional.
  DialogExerciseState({required this.name, this.duration});
}
