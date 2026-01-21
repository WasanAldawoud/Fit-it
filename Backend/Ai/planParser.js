/**
 * planParser.js
 * Parses AI-generated workout plans into structured database format
 * Validates plan structure and extracts exercises
 */

/**
 * Parses AI response to extract structured plan data
 * @param {string} aiResponse - The AI's response text
 * @returns {Object|null} Parsed plan object or null if not a valid plan
 */
export function parsePlanFromResponse(aiResponse) {
  try {
    // Check if response contains plan markers
    const hasPlanMarkers =
      aiResponse.toLowerCase().includes('workout plan') ||
      aiResponse.toLowerCase().includes('weekly plan') ||
      aiResponse.toLowerCase().includes('exercise plan') ||
      aiResponse.toLowerCase().includes('your plan') ||
      aiResponse.toLowerCase().includes('personalized plan');
    
    if (!hasPlanMarkers) {
      return null; // Not a plan response
    }

    const exercises = [];
    const lines = aiResponse.split('\n');
    
    let currentCategory = null;
    let currentDay = null;

    // Exercise categories from the system
    const categories = [
      'cardio', 'yoga', 'strength training', 'core exercises', 
      'stretching', 'pilates', 'cycling', 'swimming'
    ];

    // Days of the week
    const daysOfWeek = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    for (let line of lines) {
      const lowerLine = line.toLowerCase().trim();
      
      // Skip empty lines
      if (!lowerLine) continue;

      // Detect category headers
      const detectedCategory = categories.find(cat => lowerLine.includes(cat));
      if (detectedCategory) {
        currentCategory = detectedCategory.charAt(0).toUpperCase() + detectedCategory.slice(1);
        continue;
      }

      // Detect day headers (e.g., "Monday:", "Day 1:", "Week 1 - Monday")
      const detectedDay = daysOfWeek.find(day => lowerLine.includes(day));
      if (detectedDay) {
        currentDay = detectedDay.charAt(0).toUpperCase() + detectedDay.slice(1);
        continue;
      }

      // Extract exercise details (looking for bullet points or numbered lists)
      if ((lowerLine.startsWith('-') || lowerLine.startsWith('•') || /^\d+\./.test(lowerLine)) && currentCategory) {
        // Remove bullet points and numbers
        let exerciseLine = line.replace(/^[-•]\s*/, '').replace(/^\d+\.\s*/, '').trim();
        
        // Extract exercise name and duration
        const durationMatch = exerciseLine.match(/(\d+)\s*(min|mins|minutes|seconds|secs|reps|sets)/i);
        let duration = durationMatch ? `${durationMatch[1]} ${durationMatch[2].toLowerCase()}` : '30 mins';
        
        // Extract exercise name (text before duration or parentheses)
        let exerciseName = exerciseLine
          .replace(/\(.*?\)/g, '') // Remove parentheses content
          .replace(/\d+\s*(min|mins|minutes|seconds|secs|reps|sets).*/i, '') // Remove duration
          .replace(/[-–—:]/g, '') // Remove separators
          .trim();

        if (exerciseName && exerciseName.length > 2) {
          // Check if this exercise already exists
          const existingExercise = exercises.find(
            ex => ex.name.toLowerCase() === exerciseName.toLowerCase() && ex.category === currentCategory
          );

          if (existingExercise) {
            // Add day to existing exercise
            if (currentDay && !existingExercise.days.includes(currentDay)) {
              existingExercise.days.push(currentDay);
            }
          } else {
            // Create new exercise entry
            exercises.push({
              category: currentCategory,
              name: exerciseName,
              duration: duration,
              days: currentDay ? [currentDay] : []
            });
          }
        }
      }
    }

    // If no exercises found, return null
    if (exercises.length === 0) {
      return null;
    }

    // If no days were assigned, distribute exercises across available days
    const exercisesWithoutDays = exercises.filter(ex => ex.days.length === 0);
    if (exercisesWithoutDays.length > 0) {
      // Assign to Monday, Wednesday, Friday by default
      const defaultDays = ['Monday', 'Wednesday', 'Friday'];
      exercisesWithoutDays.forEach((ex, index) => {
        ex.days = [defaultDays[index % defaultDays.length]];
      });
    }

    return {
      exercises: exercises,
      planName: 'AI Generated Workout Plan',
      isValid: true
    };

  } catch (error) {
    console.error('Error parsing plan:', error);
    return null;
  }
}

/**
 * Validates if a plan has the minimum required structure
 * @param {Object} plan - Parsed plan object
 * @returns {boolean} True if valid
 */
export function validatePlan(plan) {
  if (!plan || !plan.exercises || !Array.isArray(plan.exercises)) {
    return false;
  }

  if (plan.exercises.length === 0) {
    return false;
  }

  // Check each exercise has required fields
  for (const exercise of plan.exercises) {
    if (!exercise.category || !exercise.name || !exercise.duration || !exercise.days) {
      return false;
    }
    if (!Array.isArray(exercise.days) || exercise.days.length === 0) {
      return false;
    }
  }

  return true;
}

/**
 * Formats plan for database insertion
 * @param {Object} plan - Parsed plan object
 * @param {Object} userInfo - User information (goal, duration, weights)
 * @returns {Object} Database-ready plan object
 */
export function formatPlanForDatabase(plan, userInfo = {}) {
  return {
    plan_name: plan.planName || 'AI Generated Workout Plan',
    exercises: plan.exercises.map(ex => ({
      category: ex.category,
      name: ex.name,
      duration: ex.duration,
      days: ex.days
    })),
    goal: userInfo.goal || null,
    duration_weeks: userInfo.duration_weeks || null,
    deadline: userInfo.deadline || null,
    current_weight: userInfo.current_weight || null,
    goal_weight: userInfo.goal_weight || null
  };
}

/**
 * Extracts goal and duration information from conversation
 * @param {string} text - User's message or AI response
 * @returns {Object} Extracted information
 */
export function extractPlanMetadata(text) {
  const metadata = {};
  
  // Extract goal
  const goalKeywords = {
    'weight loss': ['lose weight', 'weight loss', 'fat loss', 'slim down', 'get lean'],
    'muscle gain': ['build muscle', 'muscle gain', 'bulk up', 'get bigger', 'gain mass'],
    'general fitness': ['stay fit', 'general fitness', 'maintain fitness', 'stay healthy', 'get fit'],
    'endurance': ['endurance', 'stamina', 'cardio fitness'],
    'flexibility': ['flexibility', 'stretching', 'mobility']
  };

  const lowerText = text.toLowerCase();
  for (const [goal, keywords] of Object.entries(goalKeywords)) {
    if (keywords.some(keyword => lowerText.includes(keyword))) {
      metadata.goal = goal;
      break;
    }
  }

  // Extract duration in weeks
  const durationMatch = text.match(/(\d+)\s*(week|weeks|wk|wks)/i);
  if (durationMatch) {
    metadata.duration_weeks = parseInt(durationMatch[1]);
  }

  return metadata;
}
