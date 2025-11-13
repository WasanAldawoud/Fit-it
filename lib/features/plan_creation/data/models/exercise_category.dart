/// Represents a category of exercises.
///
/// Each category has a [name], a list of associated [icons],
/// and a list of [exercises] that belong to it.
class ExerciseCategory {
  /// The name of the exercise category (e.g., "Cardio", "Strength").
  final String name;

  /// A list of icon paths associated with the category.
  final List<String> icons;

  /// A list of exercise names within this category.
  final List<String> exercises;

  /// Creates a new instance of [ExerciseCategory].
  ///
  /// All parameters are required.
  const ExerciseCategory({
    required this.name,
    required this.icons,
    required this.exercises,
  });
}