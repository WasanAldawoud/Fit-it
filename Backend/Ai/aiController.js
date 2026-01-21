import client from "./openaiClient.js";
import { buildPrompt } from "./promptBuilder.js";
import { 
  getConversation, 
  saveConversation,
  getConversationState,
  updateConversationState,
  updateGatheredInfo,
  isInfoComplete,
  saveGeneratedPlan,
  getGeneratedPlan
} from "./memoryStore.js";
import { 
  parsePlanFromResponse, 
  validatePlan, 
  formatPlanForDatabase,
  extractPlanMetadata 
} from "./planParser.js";
import db from "../config/db.js";

/**
 * Main chat handler with guided questioning and approval workflow
 */
export async function generateFitnessChat(req, res) {
  try {
    const { message, userProfile } = req.body;

    // Temporarily allow userId from body for testing
    const userId = req.user ? req.user.userid : parseInt(req.body.userId);

    if (!userId || isNaN(userId)) {
      return res.status(400).json({ error: "Missing or invalid userId" });
    }

    // Log user profile data for debugging
    console.log(`👤 User ${userId} profile:`, JSON.stringify(userProfile, null, 2));

    // Input validation
    if (!message || !userProfile) {
      return res.status(400).json({ error: "Missing required fields: message, userProfile" });
    }

    // Check if OpenAI client is available
    if (!client) {
      return res.status(503).json({ error: "AI service is not configured. Please set OPENAI_API_KEY environment variable." });
    }

    // Get conversation history and state
    let history = getConversation(userId);
    let conversationState = getConversationState(userId);

    // Add user message to history
    history.push({ role: "user", content: message });

    // Process user message based on current state
    const processedState = await processUserMessage(userId, message, conversationState, userProfile);
    conversationState = processedState;

    // Build dynamic prompt based on state
    const systemPrompt = buildPrompt(userProfile, conversationState);

    // Call OpenAI API
    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        ...history
      ],
      temperature: 0.7,
      max_tokens: 1000
    });

    const aiMessage = response.choices[0].message.content;

    // Add AI response to history
    history.push({ role: "assistant", content: aiMessage });
    saveConversation(userId, history);

    // Post-process AI response
    const postProcessResult = await postProcessResponse(userId, aiMessage, conversationState, userProfile);

    // Return response with metadata
    res.json({ 
      reply: aiMessage,
      conversationState: postProcessResult.state,
      planGenerated: postProcessResult.planGenerated,
      awaitingApproval: postProcessResult.awaitingApproval
    });

  } catch (error) {
    console.error("AI Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

/**
 * Process user message and update conversation state
 */
async function processUserMessage(userId, message, conversationState, userProfile) {
  const lowerMessage = message.toLowerCase().trim();
  const currentState = conversationState.state;

  // Handle first message - transition to welcome
  if (conversationState.isFirstMessage) {
    conversationState.isFirstMessage = false;
    updateConversationState(userId, conversationState);
    return conversationState;
  }

  // State: Welcome -> Gathering Info
  if (currentState === 'welcome') {
    // Extract any information from the first message
    const extractedInfo = extractInformationFromMessage(message);
    if (Object.keys(extractedInfo).length > 0) {
      updateGatheredInfo(userId, extractedInfo);
    }
    
    conversationState = updateConversationState(userId, { state: 'gathering_info' });
    return conversationState;
  }

  // State: Gathering Info
  if (currentState === 'gathering_info') {
    // Extract information from user message
    const extractedInfo = extractInformationFromMessage(message);
    if (Object.keys(extractedInfo).length > 0) {
      updateGatheredInfo(userId, extractedInfo);
    }

    // Check if all information is collected
    if (isInfoComplete(userId)) {
      conversationState = updateConversationState(userId, { state: 'generating_plan' });
    }
    
    return conversationState;
  }

  // State: Generating Plan
  if (currentState === 'generating_plan') {
    // Stay in this state - AI will generate the plan
    return conversationState;
  }

  // State: Awaiting Approval
  if (currentState === 'awaiting_approval') {
    // Check for approval or rejection
    const isApproval = /^(yes|approve|looks good|perfect|great|ok|okay|sure|accept|save it|save|confirm)/i.test(lowerMessage);
    const isRejection = /^(no|reject|change|modify|different|not good|revise)/i.test(lowerMessage);

    if (isApproval) {
      // User approved - save the plan
      const plan = getGeneratedPlan(userId);
      if (plan) {
        await savePlanToDatabase(userId, plan, userProfile);
        conversationState = updateConversationState(userId, { state: 'approved' });
      }
    } else if (isRejection) {
      // User wants changes - go back to gathering info
      conversationState = updateConversationState(userId, { 
        state: 'gathering_info',
        generatedPlan: null 
      });
    }
    
    return conversationState;
  }

  // State: Approved or Chat
  if (currentState === 'approved' || currentState === 'chat') {
    // Check if user wants to create a new plan
    const wantsNewPlan = /new plan|another plan|create plan|different plan|start over/i.test(lowerMessage);
    if (wantsNewPlan) {
      conversationState = updateConversationState(userId, { 
        state: 'welcome',
        gatheredInfo: { goal: null, workoutStyle: null, days: null },
        generatedPlan: null
      });
    } else {
      conversationState = updateConversationState(userId, { state: 'chat' });
    }
    
    return conversationState;
  }

  return conversationState;
}

/**
 * Post-process AI response to detect plan generation and update state
 */
async function postProcessResponse(userId, aiMessage, conversationState, userProfile) {
  const currentState = conversationState.state;

  // If in generating_plan state, try to parse the plan
  if (currentState === 'generating_plan') {
    const parsedPlan = parsePlanFromResponse(aiMessage);
    
    if (parsedPlan && validatePlan(parsedPlan)) {
      // Extract metadata from conversation
      const metadata = extractPlanMetadata(aiMessage);
      const gatheredInfo = conversationState.gatheredInfo;
      
      // Combine gathered info with metadata
      const planData = {
        ...parsedPlan,
        goal: gatheredInfo.goal || metadata.goal,
        duration_weeks: metadata.duration_weeks || 4,
        current_weight: userProfile.weight,
        goal_weight: null // Can be calculated based on goal
      };

      // Save plan to state
      saveGeneratedPlan(userId, planData);
      
      return {
        state: 'awaiting_approval',
        planGenerated: true,
        awaitingApproval: true
      };
    }
  }

  return {
    state: currentState,
    planGenerated: false,
    awaitingApproval: currentState === 'awaiting_approval'
  };
}

/**
 * Extract fitness information from user message
 */
function extractInformationFromMessage(message) {
  const info = {};
  const lowerMessage = message.toLowerCase();

  // Extract goal
  const goalKeywords = {
    'weight loss': ['lose weight', 'weight loss', 'fat loss', 'slim down', 'get lean', 'lose fat'],
    'muscle gain': ['build muscle', 'muscle gain', 'bulk up', 'get bigger', 'gain mass', 'gain muscle'],
    'general fitness': ['stay fit', 'general fitness', 'maintain fitness', 'stay healthy', 'get fit', 'fitness'],
    'endurance': ['endurance', 'stamina', 'cardio fitness', 'improve endurance'],
    'flexibility': ['flexibility', 'stretching', 'mobility', 'flexible']
  };

  for (const [goal, keywords] of Object.entries(goalKeywords)) {
    if (keywords.some(keyword => lowerMessage.includes(keyword))) {
      info.goal = goal;
      break;
    }
  }

  // Extract workout style
  const styleKeywords = {
    'Cardio': ['cardio', 'running', 'walking', 'jogging', 'aerobic'],
    'Yoga': ['yoga', 'meditation', 'mindfulness'],
    'Strength Training': ['strength', 'weights', 'lifting', 'resistance', 'gym'],
    'Core Exercises': ['core', 'abs', 'abdominal', 'plank'],
    'Stretching': ['stretch', 'flexibility', 'mobility'],
    'Pilates': ['pilates'],
    'Cycling': ['cycling', 'bike', 'biking'],
    'Swimming': ['swim', 'swimming', 'pool'],
    'Mixed': ['mix', 'combination', 'variety', 'different', 'various']
  };

  const detectedStyles = [];
  for (const [style, keywords] of Object.entries(styleKeywords)) {
    if (keywords.some(keyword => lowerMessage.includes(keyword))) {
      detectedStyles.push(style);
    }
  }

  if (detectedStyles.length > 0) {
    info.workoutStyle = detectedStyles.length > 1 ? 'Mixed' : detectedStyles[0];
  }

  // Extract days per week
  const daysMatch = message.match(/(\d+)\s*(day|days|time|times)/i);
  if (daysMatch) {
    const numDays = parseInt(daysMatch[1]);
    if (numDays >= 1 && numDays <= 7) {
      info.days = numDays;
    }
  }

  // Also check for specific day mentions
  const dayKeywords = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  const mentionedDays = dayKeywords.filter(day => lowerMessage.includes(day));
  if (mentionedDays.length > 0 && !info.days) {
    info.days = mentionedDays.length;
  }

  return info;
}

/**
 * Save approved plan to database
 */
async function savePlanToDatabase(userId, planData, userProfile) {
  try {
    // Format plan for database
    const dbPlan = formatPlanForDatabase(planData, {
      goal: planData.goal,
      duration_weeks: planData.duration_weeks || 4,
      current_weight: userProfile.weight,
      goal_weight: planData.goal_weight
    });

    // Start transaction
    await db.query('BEGIN');

    // Insert plan metadata
    const planResult = await db.query(
      `INSERT INTO user_plans (user_id, plan_name, goal, duration_weeks, current_weight, goal_weight) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING plan_id`,
      [
        userId, 
        dbPlan.plan_name, 
        dbPlan.goal, 
        dbPlan.duration_weeks, 
        dbPlan.current_weight, 
        dbPlan.goal_weight
      ]
    );

    const planId = planResult.rows[0].plan_id;

    // Insert exercises
    for (const exercise of dbPlan.exercises) {
      await db.query(
        `INSERT INTO plan_exercises (plan_id, category, exercise_name, duration, days) 
         VALUES ($1, $2, $3, $4, $5)`,
        [planId, exercise.category, exercise.name, exercise.duration, exercise.days]
      );
    }

    // Commit transaction
    await db.query('COMMIT');

    console.log(`✅ Plan saved successfully for user ${userId}, plan_id: ${planId}`);
    return planId;

  } catch (error) {
    // Rollback on error
    await db.query('ROLLBACK');
    console.error('Error saving plan to database:', error);
    throw error;
  }
}

/**
 * Endpoint to handle plan approval explicitly
 */
export async function approvePlan(req, res) {
  try {
    // Temporarily allow userId from body for testing
    const userId = req.user ? req.user.userid : parseInt(req.body.userId);

    if (!userId || isNaN(userId)) {
      return res.status(400).json({ error: "Missing or invalid userId" });
    }
    const userProfile = req.body.userProfile || {};

    const conversationState = getConversationState(userId);
    
    if (conversationState.state !== 'awaiting_approval') {
      return res.status(400).json({ error: "No plan awaiting approval" });
    }

    const plan = getGeneratedPlan(userId);
    
    if (!plan) {
      return res.status(404).json({ error: "No plan found" });
    }

    // Save to database
    const planId = await savePlanToDatabase(userId, plan, userProfile);

    // Update state
    updateConversationState(userId, { state: 'approved' });

    res.json({ 
      message: "Plan approved and saved successfully!",
      planId: planId
    });

  } catch (error) {
    console.error("Error approving plan:", error);
    res.status(500).json({ error: "Failed to save plan" });
  }
}
