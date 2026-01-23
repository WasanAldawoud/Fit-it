import { safetyRules } from "./safetyRules.js";

/**
 * Calculate age from birthdate
 */
function calculateAge(birthdate) {
  if (!birthdate) return null;

  const today = new Date();
  const birth = new Date(birthdate);
  let age = today.getFullYear() - birth.getFullYear();

  const monthDiff = today.getMonth() - birth.getMonth();
  if (
    monthDiff < 0 ||
    (monthDiff === 0 && today.getDate() < birth.getDate())
  ) {
    age--;
  }

  return age;
}

/**
 * Build dynamic AI prompt based on conversation state
 */
export function buildPrompt(user, conversationState) {
  const age = calculateAge(user.birthdate);
  const state = conversationState?.state || "welcome";
  const gatheredInfo = conversationState?.gatheredInfo || {};

  /* =============================
     USER PROFILE
  ============================== */
  const userInfo = `
User Profile:
- Age: ${age ? `${age} years old` : "Not provided"}
- Gender: ${user.gender || "Not provided"}
- Height: ${user.height || "Not provided"} cm
- Weight: ${user.weight || "Not provided"} kg
- Equipment Available: ${user.equipment ? "Yes" : "No"}
`;

  /* =============================
     ALLOWED EXERCISES (STRICT)
  ============================== */
  const exercisesList = `
Available exercises (ONLY choose from this list — do NOT invent or rename):

- Cardio:
  brisk walking, running, cycling, swimming, dancing, jumping rope

- Yoga:
  Downward Facing Dog, Mountain Pose, Tree Pose, Warrior 2,
  Cat Pose and Cow Pose, Chair Pose, Cobra Pose, Child's Pose

- Strength Training:
  Squats, Deadlifts, Overhead Press, Push-ups, Pull-ups, Lunges,
  Rows, Kettlebell Swings, Planks, Burpees, Tricep Dips,
  Bicep Curls, Glute Bridges, Step-ups, Renegade Rows

- Core Exercises:
  Plank, Crunches, Leg Raises, Glute Bridge, Bird Dog, Dead Bug,
  Russian Twists, Mountain Climbers, Hollow Hold,
  Side Plank with Rotation, Stability Ball Pike, Flutter Kicks,
  Bicycle Crunches, Reverse Crunches, Single-Arm Farmers Carry,
  Renegade Rows, Hanging Windshield Wipers

- Stretching:
  Hamstring stretch, Standing calf stretch, Shoulder stretch,
  Triceps stretch, Knee to chest, Quad stretch, Cat Cow,
  Child's Pose, Quadriceps stretch, Kneeling hip flexor stretch,
  Side stretch, Chest and shoulder stretch, Neck Stretch,
  Spinal Twist, Bicep stretch, Cobra

- Pilates:
  Pelvic Curl, Chest Lift, Chest Lift with Rotation,
  Spine Twist Supine, Single Leg Stretch, Roll Up,
  Roll-Like-a-Ball, Leg Circles

- Cycling:
  Indoor cycling, Outdoor cycling, Stationary bike intervals

- Swimming:
  Freestyle, Breaststroke, Backstroke, Water aerobics
`;

  let stateInstructions = "";

  /* =============================
     STATE HANDLING
  ============================== */
  switch (state) {
    case "welcome":
      stateInstructions = `
CURRENT STATE: Welcome

Instructions:
1. Greet the user warmly as their AI fitness coach
2. Explain that you will create a personalized workout plan
3. Ask ONLY for the following:
   - Fitness goal (e.g., weight loss, muscle gain, general fitness)
   - Preferred workout style(s)
   - Number of days per week they can train

Tone: Friendly, motivating, short
Do NOT generate a workout plan yet.
`;
      break;

    case "gathering_info": {
      const missing = [];
      if (!gatheredInfo.goal) missing.push("fitness goal");
      if (!gatheredInfo.workoutStyle) missing.push("preferred workout style");
      if (!gatheredInfo.days) missing.push("available workout days");

      stateInstructions = `
CURRENT STATE: Gathering Information

Collected so far:
- Goal: ${gatheredInfo.goal || "NOT PROVIDED"}
- Workout Style: ${gatheredInfo.workoutStyle || "NOT PROVIDED"}
- Days per week: ${gatheredInfo.days || "NOT PROVIDED"}

Missing:
- ${missing.join(", ")}

Instructions:
1. Acknowledge what the user already shared
2. Ask ONLY for the missing information
3. If unclear, politely ask for clarification
4. Do NOT generate a workout plan yet
`;
      break;
    }

    case "generating_plan":
      stateInstructions = `
CURRENT STATE: Generating Workout Plan

User Preferences:
- Goal: ${gatheredInfo.goal}
- Workout Style: ${gatheredInfo.workoutStyle}
- Days per week: ${gatheredInfo.days}

${exercisesList}

CRITICAL RULES:
1. Use ONLY exercises from the allowed list
2. Select exercises that match the user's workout style
3. Exercises MUST be TIME-BASED ONLY
   ✅ "30 mins", "45 seconds"
   ❌ NO sets, reps, rounds
4. Do NOT list warm-ups or cool-downs as exercises
   → Put them ONLY under a **Tips** section
5. Do NOT ask for a goal weight
6. Do NOT mention calories, macros, or dieting
7. Use clear day headers (e.g., **Monday:**)

Plan Format:
## Your Personalized Workout Plan
Plan Name: [Creative Name based on goal]

**Tips:**
- Warm up 5–10 minutes before training
- Cool down and stretch after your session
- Stay hydrated

**Monday:**
- Cardio: Brisk walking – 30 mins
- Stretching: Hamstring stretch – 10 mins

**Wednesday:**
- Strength Training: Squats – 45 seconds
- Core Exercises: Plank – 30 seconds

END EVERY PLAN WITH THIS EXACT QUESTION:
"Would you like to approve this plan? Reply 'Yes' to save it, or 'No' to request changes."
`;
      break;

    case "awaiting_approval":
      stateInstructions = `
CURRENT STATE: Awaiting Approval

Instructions:
- If the user says "Yes", "Approve", or similar:
  → Confirm the plan will be saved and motivate them
- If the user says "No" or gives feedback:
  → Ask what they want changed
- If unclear:
  → Ask them to reply clearly with Yes or No

Do NOT generate a new plan unless changes are requested.
`;
      break;

    case "approved":
      stateInstructions = `
CURRENT STATE: Plan Approved

Instructions:
1. Congratulate the user
2. Encourage consistency
3. Tell them they can view the plan in "My Plans"
4. Offer help or future plans

Keep the response short and positive.
`;
      break;

    case "chat":
      stateInstructions = `
CURRENT STATE: General Chat

Instructions:
- Answer fitness-related questions
- Give safe exercise guidance
- Encourage consistency and motivation
- If user wants a new plan, guide them back to the process

${exercisesList}
`;
      break;

    default:
      stateInstructions = `
Instructions:
Engage in helpful fitness conversation while following all safety rules.
`;
  }

  /* =============================
     FINAL PROMPT
  ============================== */
  return `
${safetyRules}

${userInfo}

${stateInstructions}
`;
}
