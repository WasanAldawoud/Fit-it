/**
 * planParser.js
 * Parses AI-generated workout plans into structured database format
 * Validates plan structure and extracts exercises
 */

export function parsePlanFromResponse(aiResponse) {
  try {
    const hasPlanMarkers =
      aiResponse.toLowerCase().includes("workout plan") ||
      aiResponse.toLowerCase().includes("weekly plan") ||
      aiResponse.toLowerCase().includes("exercise plan") ||
      aiResponse.toLowerCase().includes("your plan") ||
      aiResponse.toLowerCase().includes("personalized plan");

    if (!hasPlanMarkers) {
      return null;
    }

    const exercises = [];
    const lines = aiResponse.split("\n");

    // ✅ Extract plan name if present (Plan Name: ...)
    let planName = "AI Generated Workout Plan";
    const planNameLine = lines.find((l) => l.trim().toLowerCase().startsWith("plan name:"));
    if (planNameLine) {
      const name = planNameLine.split(":").slice(1).join(":").trim();
      if (name.length >= 3) planName = name;
    }

    let currentCategory = null;
    let currentDay = null;
    let extractedPlanName = "AI Generated Workout Plan";

    const categories = [
      "cardio",
      "yoga",
      "strength training",
      "core exercises",
      "stretching",
      "pilates",
      "cycling",
      "swimming",
      "cardio",
      "yoga",
      "strength training",
      "core exercises",
      "stretching",
      "pilates",
      "cycling",
      "swimming",
    ];

    const daysOfWeek = [
      "monday","tuesday","wednesday","thursday","friday","saturday","sunday",
    ];

    for (let line of lines) {
      const lowerLine = line.toLowerCase().trim();
      if (!lowerLine) continue;

      const detectedCategory = categories.find((cat) => lowerLine.includes(cat));
      if (detectedCategory) {
        currentCategory =
          detectedCategory.charAt(0).toUpperCase() +
          detectedCategory.slice(1);
        continue;
      }

      const detectedDay = daysOfWeek.find((day) => lowerLine.includes(day));
      if (detectedDay) {
        currentDay =
          detectedDay.charAt(0).toUpperCase() +
          detectedDay.slice(1);
        continue;
      }

      if (
        (lowerLine.startsWith("-") || lowerLine.startsWith("•") || /^\d+\./.test(lowerLine)) &&
        currentCategory
      ) {
        let exerciseLine = line.replace(/^[-•]\s*/, "").replace(/^\d+\.\s*/, "").trim();

        const durationMatch = exerciseLine.match(/(\d+)\s*(min|mins|minutes|seconds|secs|reps|sets)/i);
        let duration = durationMatch ? `${durationMatch[1]} ${durationMatch[2].toLowerCase()}` : "30 mins";

        let exerciseName = exerciseLine
          .replace(/\(.*?\)/g, "")
          .replace(/\d+\s*(min|mins|minutes|seconds|secs|reps|sets).*/i, "")
          .replace(/[-–—:]/g, "")
          .trim();

        if (exerciseName && exerciseName.length > 2) {
          const existingExercise = exercises.find(
            (ex) =>
              ex.name.toLowerCase() === exerciseName.toLowerCase() && ex.category === currentCategory,
          );

          if (existingExercise) {
            if (currentDay && !existingExercise.days.includes(currentDay)) {
              existingExercise.days.push(currentDay);
            }
          } else {
            exercises.push({
              category: currentCategory,
              name: exerciseName,
              duration: duration,
              days: currentDay ? [currentDay] : [],
            });
          }
        }
      }
    }

    if (exercises.length === 0) {
      return null;
    }

    const exercisesWithoutDays = exercises.filter((ex) => ex.days.length === 0);
    if (exercisesWithoutDays.length > 0) {
      const defaultDays = ["Monday", "Wednesday", "Friday"];
      exercisesWithoutDays.forEach((ex, index) => {
        ex.days = [defaultDays[index % defaultDays.length]];
      }
    });

    return {
      exercises: exercises,
      planName: planName,
      isValid: true,
    };
  } catch (error) {
    console.error("Error parsing plan:", error);
    console.error("Error parsing plan:", error);
    return null;
  }
}

export function validatePlan(plan) {
  if (!plan || !plan.exercises || !Array.isArray(plan.exercises)) return false;
  if (plan.exercises.length === 0) return false;

  for (const exercise of plan.exercises) {
    if (!exercise.category || !exercise.name || !exercise.duration || !exercise.days) return false;
    if (!Array.isArray(exercise.days) || exercise.days.length === 0) return false;
  }
  return true;
}

export function formatPlanForDatabase(plan, userInfo = {}) {
  return {
    plan_name: plan.planName || "AI Generated Workout Plan",
    exercises: plan.exercises.map((ex) => ({
    plan_name: plan.planName || "AI Generated Workout Plan",
    exercises: plan.exercises.map((ex) => ({
      category: ex.category,
      name: ex.name,
      duration: ex.duration,
      days: ex.days,
      days: ex.days,
    })),
    goal: userInfo.goal || null,
    duration_weeks: userInfo.duration_weeks || null,
    deadline: userInfo.deadline || null,
    current_weight: userInfo.current_weight || null,
    goal_weight: userInfo.goal_weight || null,
    goal_weight: userInfo.goal_weight || null,
  };
}

export function extractPlanMetadata(text) {
  const metadata = {};

  const goalKeywords = {
    "weight loss": ["lose weight", "weight loss", "fat loss", "slim down", "get lean"],
    "muscle gain": ["build muscle", "muscle gain", "bulk up", "get bigger", "gain mass"],
    "general fitness": ["stay fit", "general fitness", "maintain fitness", "stay healthy", "get fit"],
    endurance: ["endurance", "stamina", "cardio fitness"],
    flexibility: ["flexibility", "stretching", "mobility"],
  };

  const lowerText = text.toLowerCase();
  for (const [goal, keywords] of Object.entries(goalKeywords)) {
    if (keywords.some((keyword) => lowerText.includes(keyword))) {
      metadata.goal = goal;
      break;
    }
  }

  const durationMatch = text.match(/(\d+)\s*(week|weeks|wk|wks)/i);
  if (durationMatch) {
    metadata.duration_weeks = parseInt(durationMatch[1], 10);
  }

  const weightMatch = text.match(
    /(?:goal|target|reach)\s*:?\s*(\d+(\.\d+)?)\s*(kg|kgs|lb|lbs)/i,
  );
  if (weightMatch) {
    metadata.goal_weight = parseFloat(weightMatch[1]);
  }

  return metadata;
}