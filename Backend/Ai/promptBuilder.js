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
  const state = conversationState.state;
  const gatheredInfo = conversationState.gatheredInfo || {};

  /* =============================
     USER PROFILE
  ============================== */
  const userInfo = `
User Profile:
- Age: ${age ? age + " years old" : "Not provided"}
- Gender: ${user.gender || "Not provided"}
- Height: ${user.height} cm
- Weight: ${user.weight} kg
- Equipment: ${user.equipment ? "Yes" : "No"}
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
1. Greet the user warmly and introduce yourself as their AI fitness coach
2. Explain that you'll help create a personalized workout plan
3. Ask the user to provide:
   - Fitness goal (e.g., weight loss, muscle gain, general fitness, endurance, flexibility)
   - Preferred workout style (Cardio, Yoga, Strength Training, Core Exercises, Stretching, Pilates, Cycling, Swimming, or a mix)
   - Days per week they can commit
   - Deadline or timeframe (e.g., "by 2026-03-01" or "in 8 weeks")

Keep it friendly, encouraging, and concise.
`;
      break;

    case "gathering_info": {
      const missingInfo = [];
      if (!gatheredInfo.goal) missingInfo.push("fitness goal");
      if (!gatheredInfo.workoutStyle) missingInfo.push("preferred workout style");
      if (!gatheredInfo.days) missingInfo.push("available days per week");
      if (!gatheredInfo.deadline && !gatheredInfo.durationWeeks) missingInfo.push("deadline or timeframe");

      stateInstructions = `
CURRENT STATE: Gathering Information

Information collected so far:
- Goal: ${gatheredInfo.goal || "NOT PROVIDED"}
- Workout Style: ${gatheredInfo.workoutStyle || "NOT PROVIDED"}
- Days per week: ${gatheredInfo.days || "NOT PROVIDED"}
- Deadline (date): ${gatheredInfo.deadline || "NOT PROVIDED"}
- Timeframe (weeks): ${gatheredInfo.durationWeeks || "NOT PROVIDED"}

Missing information: ${missingInfo.join(", ")}

Instructions:
1. Acknowledge what the user has provided
2. Ask for the missing information in a friendly, conversational way
3. Accept a timeframe (e.g., "in 8 weeks") OR a date (e.g., "2026-03-01")
4. Once ALL information is collected, confirm and say you will generate the plan

Do NOT generate a plan yet. Only gather information.
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
- Deadline (date): ${gatheredInfo.deadline || "NOT PROVIDED"}
- Timeframe (weeks): ${gatheredInfo.durationWeeks || "NOT PROVIDED"}

${exercisesList}

Instructions:
1. Create a personalized weekly workout plan based on the user's goal, preferred workout style, and available days
2. Ensure exercises on the same day are compatible and "go well together"
3. Use ONLY exercises from the available list above
4. Start the plan with:
   "Plan Name: <short name aligned with goal + exercise combo>"
5. Format the plan with day headers (e.g., **Monday:**) and bullet exercises
6. Include warm-up and cool-down recommendations
7. After presenting the plan, ALWAYS end with:
   "Would you like to approve this plan? Reply 'Yes' to save it, or 'No' to request changes."
`;
      break;

    case "awaiting_approval":
      stateInstructions = `
CURRENT STATE: Awaiting Plan Approval

Instructions:
- If user approves, confirm it will be saved and encourage them.
- If user requests changes, ask what to change.
- If unclear, ask them to reply Yes or No.
`;
      break;

    case "approved":
      stateInstructions = `
CURRENT STATE: Plan Approved and Saved

Instructions:
- Congratulate them and encourage consistency.
- Offer to answer questions.
`;
      break;

    case "chat":
      stateInstructions = `
CURRENT STATE: General Chat

Instructions:
- Answer fitness-related questions within safety rules.
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