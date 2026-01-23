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
    if (!aiResponse || typeof aiResponse !== "string") return null;

    const lowerResponse = aiResponse.toLowerCase();

    // ✅ Strong plan detection
    const hasPlanMarkers =
      lowerResponse.includes("workout plan") ||
      lowerResponse.includes("weekly plan") ||
      lowerResponse.includes("exercise plan") ||
      lowerResponse.includes("your plan") ||
      lowerResponse.includes("personalized plan");

    if (!hasPlanMarkers) return null;

    const exercises = [];
    const lines = aiResponse.split("\n");

    let currentCategory = null;
    let currentDay = null;
    let extractedPlanName = "AI Generated Workout Plan";

    /* -----------------------------
       Allowed Categories (STRICT)
    ------------------------------ */
    const categories = [
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
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
      "sunday",
    ];

    for (let line of lines) {
      const trimmed = line.trim();
      const lowerLine = trimmed.toLowerCase();

      if (!lowerLine) continue;

      /* -----------------------------
         Extract Plan Name
      ------------------------------ */
      if (lowerLine.includes("plan name:")) {
        extractedPlanName = line.substring(line.toLowerCase().indexOf("plan name:") + 10).trim().replace(/[*_#"]/g, "");
        continue;
      }

      /* -----------------------------
         Stop parsing on tips / notes
      ------------------------------ */
      if (
        lowerLine.includes("tips:") ||
        lowerLine.includes("notes:") ||
        lowerLine.includes("recommendations:")
      ) {
        currentCategory = null;
        continue;
      }

      /* -----------------------------
         Detect category headers
      ------------------------------ */
      const detectedCategory = categories.find((cat) =>
        lowerLine.includes(cat),
      );

      if (detectedCategory) {
        currentCategory =
          detectedCategory.charAt(0).toUpperCase() +
          detectedCategory.slice(1);
        continue;
      }

      /* -----------------------------
         Detect day headers
      ------------------------------ */
      const detectedDay = daysOfWeek.find((day) =>
        lowerLine.includes(day),
      );

      if (detectedDay) {
        currentDay =
          detectedDay.charAt(0).toUpperCase() +
          detectedDay.slice(1);
        continue;
      }

      /* -----------------------------
         Detect exercise lines
      ------------------------------ */
      const isBullet =
        lowerLine.startsWith("-") ||
        lowerLine.startsWith("•") ||
        /^\d+\./.test(lowerLine);

      if (!isBullet || !currentCategory) continue;

      let exerciseLine = trimmed
        .replace(/^[-•]\s*/, "")
        .replace(/^\d+\.\s*/, "")
        .trim();

      /* -----------------------------
         Duration (TIME ONLY)
      ------------------------------ */
      const durationMatch = exerciseLine.match(
        /(\d+)\s*(min|mins|minutes|sec|secs|seconds|hr|hrs|hours)/i,
      );

      const duration = durationMatch
        ? durationMatch[0].toLowerCase()
        : "30 mins";

      /* -----------------------------
         Clean exercise name
      ------------------------------ */
      let exerciseName = exerciseLine
        .replace(/\(.*?\)/g, "")
        .replace(durationMatch ? durationMatch[0] : "", "")
        .replace(/\d+\s*(sets|reps|rounds)/gi, "") // 🛡️ safety
        .replace(/[-–—:]/g, "")
        .trim();

      if (exerciseName.length < 3) continue;

      /* -----------------------------
         Merge duplicates safely
      ------------------------------ */
      const existing = exercises.find(
        (ex) =>
          ex.name.toLowerCase() === exerciseName.toLowerCase() &&
          ex.category === currentCategory &&
          ex.duration === duration,
      );

      if (existing) {
        if (currentDay && !existing.days.includes(currentDay)) {
          existing.days.push(currentDay);
        }
      } else {
        exercises.push({
          category: currentCategory,
          name: exerciseName,
          duration,
          days: currentDay ? [currentDay] : [],
        });
      }
    }

    if (exercises.length === 0) return null;

    /* -----------------------------
       Assign default days if missing
    ------------------------------ */
    const defaultDays = ["Monday", "Wednesday", "Friday"];
    exercises.forEach((ex, index) => {
      if (!ex.days.length) {
        ex.days = [defaultDays[index % defaultDays.length]];
      }
    });

    return {
      planName: extractedPlanName,
      exercises,
      isValid: true,
    };
  } catch (error) {
    console.error("Error parsing plan:", error);
    return null;
  }
}

/* =============================
   VALIDATION
============================= */

export function validatePlan(plan) {
  if (!plan || !Array.isArray(plan.exercises)) return false;
  if (plan.exercises.length === 0) return false;

  return plan.exercises.every(
    (ex) =>
      ex.category &&
      ex.name &&
      ex.duration &&
      Array.isArray(ex.days) &&
      ex.days.length > 0,
  );
}

/* =============================
   DATABASE FORMAT
============================= */

export function formatPlanForDatabase(plan, userInfo = {}) {
  return {
    plan_name: plan.planName || "AI Generated Workout Plan",
    exercises: plan.exercises.map((ex) => ({
      category: ex.category,
      name: ex.name,
      duration: ex.duration,
      days: ex.days,
    })),
    goal: userInfo.goal || null,
    duration_weeks: userInfo.duration_weeks || null,
    deadline: userInfo.deadline || null,
    current_weight: userInfo.current_weight || null,
    goal_weight: userInfo.goal_weight || null,
  };
}

/* =============================
   METADATA EXTRACTION
============================= */

export function extractPlanMetadata(text) {
  const metadata = {};
  if (!text) return metadata;

  const lowerText = text.toLowerCase();

  const goalKeywords = {
    "weight loss": [
      "lose weight",
      "weight loss",
      "fat loss",
      "slim down",
      "get lean",
    ],
    "muscle gain": [
      "build muscle",
      "muscle gain",
      "bulk up",
      "gain mass",
    ],
    "maintain weight": [
      "maintain weight",
      "keep weight",
      "stay same weight",
    ],
    "general fitness": [
      "general fitness",
      "stay fit",
      "stay healthy",
      "get fit",
    ],
    endurance: ["endurance", "stamina", "cardio fitness"],
    flexibility: ["flexibility", "mobility", "stretching"],
  };

  for (const [goal, keywords] of Object.entries(goalKeywords)) {
    if (keywords.some((k) => lowerText.includes(k))) {
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
