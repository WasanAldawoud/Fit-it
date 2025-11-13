import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/exercise_category.dart';


/// A card widget that represents an exercise category.
///
/// This card displays the category's name and icons. It has a distinct visual
/// style when it is selected, including a border and a checkmark icon.
/// The card responds to taps to allow for selection.
class CategoryCard extends StatelessWidget {
  /// The exercise category to display.
  final ExerciseCategory category;

  /// Whether the card is currently selected.
  final bool isSelected;

  /// A callback function that is invoked when the card is tapped.
  final VoidCallback onTap;

  /// Creates a new instance of [CategoryCard].
  ///
  /// All parameters are required.
  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });



  @override
  Widget build(BuildContext context) {

    // The inner content of the card, including icons and text.
    final cardContent = Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  // First Icon
                  SvgPicture.asset(
                    category.icons[0], // Access the first icon
                    width: 50.0,
                    height: 50.0,
                    colorFilter: ColorFilter.mode(
                      (isSelected ? const Color(0xFFFFAE00) : Color(0xFF00AEEF)),
                      BlendMode.srcIn,
                    ),
                  ),


                  // Second Icon
                  SvgPicture.asset(
                    category.icons[1], // Access the second icon
                    width: 50.0,
                    height: 50.0,
                    colorFilter: ColorFilter.mode(
                      ((isSelected && (category.icons[1] == 'assets/icons/cardio2.svg')) ?
                      const Color(0xFFFF0000):
                      isSelected ?
                      const Color(0xFF0073E6) :
                      Color(0xFF00AEEF)),
                      BlendMode.srcIn,
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 12.0),
              Text(
                category.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isSelected)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00B2FF),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: isSelected ?

      // If selected, display a double-border design.
      Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF00B2FF),
              width: 1.5,
            ),

            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA1E2FF),
                blurRadius: 17.0,
              ),
            ]
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF00B2FF),
              width: 2.0,
            ),
            color: const Color(0xFFF7F7F7), // A light inner color for contrast
            borderRadius: BorderRadius.circular(16.0),
          ),

          child: cardContent,

        ),
      ) :



      // If not selected, display with a "fog" or neumorphic effect.
      Container(
        decoration: BoxDecoration(

          // Box Color
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16.0),

          // Shadow
          boxShadow: [
            // Bottom-right "dark" shadow
            BoxShadow(
              color: Colors.grey.shade500,
              offset: const Offset(4, 4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            // Top-left "light" shadow
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),

        child: cardContent,

      ),
    );
  }
}