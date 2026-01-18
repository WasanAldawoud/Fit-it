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
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
}

/**
 * Build dynamic prompt based on conversation state
 */
export function buildPrompt(user, conversationState) {
  const age = calculateAge(user.birthdate);
  const state = conversationState.state;
  const gatheredInfo = conversationState.gatheredInfo;

  // Base user information
  const userInfo = `
User Profile:
- Age: ${age ? age + ' years old' : 'Not provided'}
- Gender: ${user.gender || 'Not provided'}
- Height: ${user.height} cm
- Weight: ${user.weight} kg
- Equipment: ${user.equipment ? "Yes" : "No"}
`;

  // Available exercises list
  const exercisesList = `
Available exercises (only suggest from this list):
- Cardio: brisk walking, running, cycling, swimming, dancing, Jumping rope
- Yoga: Downward Facing Dog, Mountain Pose, Tree Pose, Warrior 2, Cat Pose and Cow Pose, Chair Pose, Cobra Pose, Child's Pose
- Strength Training: Squats, Deadlifts, Overhead Press, Push-ups, Pull-ups, Lunges, Rows, Kettlebell Swings, Planks, Burpees, Tricep Dips, Bicep Curls, Glute Bridges, Step-ups, Renegade Rows
- Core Exercises: Plank, Crunches, Leg Raises, Glute Bridge, Bird Dog, Dead Bug, Russian Twists, Mountain Climbers, Hollow Hold, Side Plank with Rotation, Stability Ball Pike, Flutter Kicks, Bicycle Crunches, Reverse Crunches, Single-Arm Farmers Carry, Renegade Rows, Hanging Windshield Wipers
- Stretching: Hamstring stretch, Standing calf stretch, Shoulder stretch, Triceps stretch, Knee to chest, Quad stretch, Cat Cow, Child's Pose, Quadriceps stretch, Kneeling hip flexor stretch, Side stretch, Chest and shoulder stretch, Neck Stretch, Spinal Twist, Bicep stretch, Cobra
- Pilates: Pelvic Curl, Chest Lift, Chest Lift with Rotation, Spine Twist Supine, Single Leg Stretch, Roll Up, Roll-Like-a-Ball, Leg Circles
- Cycling: Indoor cycling, Outdoor cycling, Stationary bike intervals
- Swimming: Freestyle, Breaststroke, Backstroke, Water aerobics
`;

  // State-specific instructions
  let stateInstructions = '';

  switch (state) {
    case 'welcome':
      stateInstructions = `
CURRENT STATE: Welcome Message

Instructions:
1. Greet the user warmly and introduce yourself as their AI fitness coach
2. Explain that you'll help create a personalized workout plan
3. Ask the user to provide the following information:
   - Their fitness goal (e.g., weight loss, muscle gain, general fitness, endurance, flexibility)
   - Their preferred workout style (e.g., Cardio, Yoga, Strength Training, Core Exercises, Stretching, Pilates, Cycling, Swimming, or a combination)
   - How many days per week they can commit to working out

Example welcome message:
"Hello! 👋 I'm your AI fitness coach, here to help you achieve your fitness goals!

To create the perfect workout plan for you, I need to know:
1. **Your fitness goal** - What would you like to achieve? (e.g., weight loss, muscle gain, general fitness)
2. **Your preferred workout style** - What type of exercises do you enjoy? (e.g., Cardio, Yoga, Strength Training, or a mix)
3. **Your availability** - How many days per week can you work out?

Please share this information, and I'll create a personalized plan just for you!"

Keep it friendly, encouraging, and concise.
`;
      break;

    case 'gathering_info':
      const missingInfo = [];
      if (!gatheredInfo.goal) missingInfo.push('fitness goal');
      if (!gatheredInfo.workoutStyle) missingInfo.push('preferred workout style');
      if (!gatheredInfo.days) missingInfo.push('available days per week');

      stateInstructions = `
CURRENT STATE: Gathering Information

Information collected so far:
- Goal: ${gatheredInfo.goal || 'NOT PROVIDED'}
- Workout Style: ${gatheredInfo.workoutStyle || 'NOT PROVIDED'}
- Days per week: ${gatheredInfo.days || 'NOT PROVIDED'}

Missing information: ${missingInfo.join(', ')}

Instructions:
1. Acknowledge what the user has provided
2. Ask for the missing information in a friendly, conversational way
3. If the user's response is unclear, ask clarifying questions
4. Once ALL information is collected, confirm with the user and let them know you'll generate their plan

Do NOT generate a plan yet. Only gather information.
`;
      break;

    case 'generating_plan':
      stateInstructions = `
CURRENT STATE: Generating Workout Plan

Collected Information:
- Goal: ${gatheredInfo.goal}
- Workout Style: ${gatheredInfo.workoutStyle}
- Days per week: ${gatheredInfo.days}

${exercisesList}

Instructions:
1. Create a personalized weekly workout plan based on the user's goal, preferred workout style, and available days
2. Select 1-2 exercise types from the available list that match their workout style preference
3. Distribute exercises across their available days
4. Consider their age (${age || 'unknown'}) and gender (${user.gender || 'unknown'}) for appropriate intensity
5. Use ONLY exercises from the available list above
6. Format the plan clearly with:
   - Day headers (e.g., **Monday:**, **Wednesday:**)
   - Exercise category and name
   - Duration for each exercise
7. Keep exercises beginner-friendly if no equipment is available
8. Include warm-up and cool-down recommendations
9. After presenting the plan, ALWAYS end with:
   "Would you like to approve this plan? Reply 'Yes' to save it, or 'No' to request changes."

Example format:
## Your Personalized Workout Plan

**Monday:**
- Cardio: Brisk Walking - 30 mins
- Stretching: Hamstring Stretch - 10 mins

**Wednesday:**
- Strength Training: Squats - 3 sets of 12 reps
- Core Exercises: Plank - 3 sets of 30 seconds

**Friday:**
- Yoga: Downward Facing Dog - 5 mins
- Stretching: Full Body Stretch - 15 mins

**Tips:**
- Always warm up for 5-10 minutes before starting
- Stay hydrated throughout your workout
- Rest for at least one day between intense sessions

Would you like to approve this plan? Reply 'Yes' to save it, or 'No' to request changes.
`;
      break;

    case 'awaiting_approval':
      stateInstructions = `
CURRENT STATE: Awaiting Plan Approval

The user has been presented with a workout plan and needs to approve or reject it.

Instructions:
1. If the user says "Yes", "Approve", "Looks good", or similar positive response:
   - Confirm that the plan will be saved
   - Encourage them to start their fitness journey
   - Offer to answer any questions about the exercises

2. If the user says "No", "Change", "Modify", or provides feedback:
   - Ask what specific changes they'd like
   - Acknowledge their feedback
   - Prepare to regenerate the plan with their modifications

3. If the user's response is unclear:
   - Politely ask them to confirm with "Yes" to approve or "No" to request changes

Do NOT generate a new plan unless they explicitly request changes.
`;
      break;

    case 'approved':
      stateInstructions = `
CURRENT STATE: Plan Approved and Saved

The user's workout plan has been saved to their account.

Instructions:
1. Congratulate them on taking this step
2. Provide motivational encouragement
3. Remind them they can view their plan in the "My Plans" section
4. Offer to answer questions about exercises or create additional plans
5. Keep responses brief and encouraging

You can now engage in general fitness conversation or help with other requests.
`;
      break;

    case 'chat':
      stateInstructions = `
CURRENT STATE: General Conversation

Instructions:
1. Answer fitness-related questions
2. Provide exercise tips and guidance
3. Offer motivation and support
4. If the user wants to create a new plan, guide them through the process again
5. Stay within your role as a fitness assistant

${exercisesList}
`;
      break;

    default:
      stateInstructions = `
Instructions:
Engage in helpful fitness conversation while following all safety rules.
`;
  }

  return `
${safetyRules}

${userInfo}

${stateInstructions}
`;
}
