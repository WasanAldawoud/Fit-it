import client from "./openaiClient.js";
import { buildPrompt } from "./promptBuilder.js";
import {
  getConversation,
import {
  getConversation,
  saveConversation,
  getConversationState,
  updateConversationState,
  updateGatheredInfo,
  isInfoComplete,
  saveGeneratedPlan,
  getGeneratedPlan,
  getGeneratedPlan,
} from "./memoryStore.js";
import {
  parsePlanFromResponse,
  validatePlan,
import {
  parsePlanFromResponse,
  validatePlan,
  formatPlanForDatabase,
  extractPlanMetadata,
  extractPlanMetadata,
} from "./planParser.js";
import db from "../config/db.js";

/* -----------------------------
   Deadline helpers (safe defaults)
------------------------------ */
function clampWeeks(n, min, max) {
  const x = parseInt(n);
  if (Number.isNaN(x)) return null;
  return Math.min(max, Math.max(min, x));
}

function addWeeks(date, weeks) {
  const d = new Date(date);
  d.setDate(d.getDate() + weeks * 7);
  return d;
}

// Accepts either:
// - providedDeadline: "YYYY-MM-DD" or ISO string
// - providedWeeks: integer
function computeSafeDeadline({ providedDeadline, providedWeeks, fallbackWeeks = 4 }) {
  const safeWeeks = clampWeeks(providedWeeks ?? fallbackWeeks, 4, 52) ?? 4;

  if (providedDeadline) {
    const parsed = new Date(providedDeadline);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  return addWeeks(new Date(), safeWeeks);
}

// Extract timeframe/deadline from a user message.
// Supported:
// - "in 8 weeks"
// - "8 weeks"
// - "2026-03-01"
export function extractDeadlineFromMessage(message) {
  const text = (message || "").toLowerCase();

  const weeksMatch = text.match(/(?:in\s*)?(\d{1,2})\s*(week|weeks|wk|wks)\b/i);
  if (weeksMatch) {
    return { durationWeeks: parseInt(weeksMatch[1]), deadline: null };
  }

  const isoDateMatch = text.match(/\b(20\d{2}-\d{2}-\d{2})\b/);
  if (isoDateMatch) {
    return { deadline: isoDateMatch[1], durationWeeks: null };
  }

  return { deadline: null, durationWeeks: null };
}

/**
 * Main chat handler with guided questioning and approval workflow
 */
export async function generateFitnessChat(req, res) {
  try {
    const { message, userProfile } = req.body;

    // ✅ userId must come from the authenticated session
    const userId = req.user?.userid || req.user?.userId;
    if (!userId || isNaN(parseInt(userId))) {
      return res.status(401).json({ error: "Authentication required" });
    }

    // Input validation
    if (!message || !userProfile) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    if (!client) {
      return res.status(503).json({
        error: "AI service is not configured. Please set OPENAI_API_KEY environment variable.",
      });
    }

    let history = getConversation(userId);
    let conversationState = getConversationState(userId);

    history.push({ role: "user", content: message });

    // ✅ Extract deadline/timeframe from the message and store it (if present)
    const deadlineInfo = extractDeadlineFromMessage(message);
    if (deadlineInfo.deadline || deadlineInfo.durationWeeks) {
      updateGatheredInfo(userId, deadlineInfo);
      conversationState = getConversationState(userId);
    }

    // Process user message based on current state (this persists state via updateConversationState)
    conversationState = await processUserMessage(userId, message, conversationState, userProfile);

    // Build dynamic prompt based on state
    const systemPrompt = buildPrompt(userProfile, conversationState);

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "system", content: systemPrompt }, ...history],
      messages: [{ role: "system", content: systemPrompt }, ...history],
      temperature: 0.7,
      max_tokens: 1000,
      max_tokens: 1000,
    });

    const aiMessage = response.choices[0].message.content;

    history.push({ role: "assistant", content: aiMessage });
    saveConversation(userId, history);

    // Post-process AI response (may detect a plan + compute next state)
    const postProcessResult = await postProcessResponse(userId, aiMessage, conversationState, userProfile);

    // ✅ Persist post-processed state so memory matches what we return
    updateConversationState(userId, { state: postProcessResult.state });

    // Return response with metadata
    res.json({
      reply: aiMessage,
      conversationState: postProcessResult.state,
      planGenerated: postProcessResult.planGenerated,
      awaitingApproval: postProcessResult.awaitingApproval,
      awaitingApproval: postProcessResult.awaitingApproval,
    });
  } catch (error) {
    console.error("AI Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
}

/* ======================================================
   STATE MACHINE
====================================================== */
async function processUserMessage(userId, message, conversationState, userProfile) {
  const lowerMessage = message.toLowerCase().trim();
  const currentState = conversationState.state;

  if (conversationState.isFirstMessage) {
    conversationState.isFirstMessage = false;
    updateConversationState(userId, conversationState);
    return conversationState;
  }

  // State: Welcome -> Gathering Info
  if (currentState === "welcome") {
    const extractedInfo = extractInformationFromMessage(message);
    if (Object.keys(extractedInfo).length > 0) {
      updateGatheredInfo(userId, extractedInfo);
    }

    conversationState = updateConversationState(userId, { state: "gathering_info" });
    return conversationState;
  }

  // State: Gathering Info
  if (currentState === "gathering_info") {
    const extractedInfo = extractInformationFromMessage(message);
    if (Object.keys(extractedInfo).length > 0) {
      updateGatheredInfo(userId, extractedInfo);
    }

    // ✅ if info is complete (including deadline OR durationWeeks), advance to generating_plan
    if (isInfoComplete(userId)) {
      conversationState = updateConversationState(userId, { state: "generating_plan" });
    }

    return conversationState;
  }

  // State: Generating Plan
  if (currentState === "generating_plan") {
    return conversationState;
  }

  // State: Awaiting Approval
  if (currentState === "awaiting_approval") {
    const isApproval =
      /^(yes|approve|looks good|perfect|great|ok|okay|sure|accept|save it|save|confirm)/i.test(lowerMessage);
    const isRejection = /^(no|reject|change|modify|different|not good|revise)/i.test(lowerMessage);

    if (isApproval) {
      const plan = getGeneratedPlan(userId);
      if (plan) {
        await savePlanToDatabase(userId, plan, userProfile);
        conversationState = updateConversationState(userId, { state: "approved" });
      }
    } else if (isRejection) {
      conversationState = updateConversationState(userId, {
        state: "gathering_info",
        generatedPlan: null,
      });
    }


    return conversationState;
  }

  // State: Approved or Chat
  if (currentState === "approved" || currentState === "chat") {
    const wantsNewPlan = /new plan|another plan|create plan|different plan|start over/i.test(lowerMessage);
    if (wantsNewPlan) {
      conversationState = updateConversationState(userId, {
        state: "welcome",
        gatheredInfo: { goal: null, workoutStyle: null, days: null, deadline: null, durationWeeks: null },
        generatedPlan: null,
      });
    } else {
      conversationState = updateConversationState(userId, { state: "chat" });
    }

    return conversationState;
  }

  return conversationState;
}

/**
 * Post-process AI response to detect plan generation and compute deadline/name metadata
 */
async function postProcessResponse(userId, aiMessage, conversationState, userProfile) {
  const currentState = conversationState.state;

  if (currentState === "generating_plan") {
    const parsedPlan = parsePlanFromResponse(aiMessage);


    if (parsedPlan && validatePlan(parsedPlan)) {
      const metadata = extractPlanMetadata(aiMessage);
      const gatheredInfo = conversationState.gatheredInfo || {};

      const duration_weeks =
        clampWeeks(gatheredInfo.durationWeeks ?? metadata.duration_weeks ?? 4, 4, 52) ?? 4;

      const deadlineDate = computeSafeDeadline({
        providedDeadline: gatheredInfo.deadline,
        providedWeeks: duration_weeks,
        fallbackWeeks: 4,
      });

      const planData = {
        ...parsedPlan, // includes planName
        goal: gatheredInfo.goal || metadata.goal,
        duration_weeks,
        deadline: deadlineDate.toISOString(),
        duration_weeks,
        deadline: deadlineDate.toISOString(),
        current_weight: userProfile.weight,
        goal_weight: null,
      };

      saveGeneratedPlan(userId, planData);


      return {
        state: "awaiting_approval",
        state: "awaiting_approval",
        planGenerated: true,
        awaitingApproval: true,
        awaitingApproval: true,
      };
    }
  }

  return {
    state: conversationState.state,
    planGenerated: false,
    awaitingApproval: currentState === "awaiting_approval",
  };
}

/**
 * Extract fitness information from user message
 * Exported for tests
 */
export function extractInformationFromMessage(message) {
  const info = {};
  const lowerMessage = (message || "").toLowerCase();

  // Extract goal
  const goalKeywords = {
    "weight loss": ["lose weight", "weight loss", "fat loss", "slim down", "get lean", "lose fat"],
    "muscle gain": ["build muscle", "muscle gain", "bulk up", "get bigger", "gain mass", "gain muscle"],
    "general fitness": ["stay fit", "general fitness", "maintain fitness", "stay healthy", "get fit", "fitness"],
    endurance: ["endurance", "stamina", "cardio fitness", "improve endurance"],
    flexibility: ["flexibility", "stretching", "mobility", "flexible"],
  };

  for (const [goal, keywords] of Object.entries(goalKeywords)) {
    if (keywords.some((keyword) => lowerMessage.includes(keyword))) {
      info.goal = goal;
      break;
    }
  }

  // Extract workout style
  const styleKeywords = {
    Cardio: ["cardio", "running", "walking", "jogging", "aerobic"],
    Yoga: ["yoga", "meditation", "mindfulness"],
    "Strength Training": ["strength", "weights", "lifting", "resistance", "gym"],
    "Core Exercises": ["core", "abs", "abdominal", "plank"],
    Stretching: ["stretch", "flexibility", "mobility"],
    Pilates: ["pilates"],
    Cycling: ["cycling", "bike", "biking"],
    Swimming: ["swim", "swimming", "pool"],
    Mixed: ["mix", "combination", "variety", "different", "various"],
  };

  const detectedStyles = [];
  for (const [style, keywords] of Object.entries(styleKeywords)) {
    if (keywords.some((keyword) => lowerMessage.includes(keyword))) {
      detectedStyles.push(style);
    }
  }

  if (detectedStyles.length > 0) {
    info.workoutStyle = detectedStyles.length > 1 ? "Mixed" : detectedStyles[0];
  }

  // Extract days per week
  const daysMatch = (message || "").match(/(\d+)\s*(day|days|time|times)/i);
  if (daysMatch) {
    const numDays = parseInt(daysMatch[1]);
    if (numDays >= 1 && numDays <= 7) {
      info.days = numDays;
    }
  }

  const dayKeywords = ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"];
  const mentionedDays = dayKeywords.filter((day) => lowerMessage.includes(day));
  if (mentionedDays.length > 0 && !info.days) {
    info.days = mentionedDays.length;
  }

  return info;
}

/**
 * Save approved plan to database (includes deadline + AI plan name)
 */
async function savePlanToDatabase(userId, planData, userProfile) {
  try {
    const dbPlan = formatPlanForDatabase(planData, {
      goal: planData.goal,
      duration_weeks: planData.duration_weeks || 4,
      deadline: planData.deadline || null,
      current_weight: userProfile.weight,
      goal_weight: planData.goal_weight,
      goal_weight: planData.goal_weight,
    });

    await db.query("BEGIN");

    const planResult = await db.query(
      `INSERT INTO user_plans (user_id, plan_name, goal, duration_weeks, deadline, current_weight, goal_weight)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING plan_id`,
      [
        userId,
        dbPlan.plan_name,
        dbPlan.goal,
        dbPlan.duration_weeks,
        dbPlan.deadline,
        dbPlan.current_weight,
        dbPlan.goal_weight,
      ],
    );

    const planId = result.rows[0].plan_id;

    for (const exercise of dbPlan.exercises) {
      await db.query(
        `INSERT INTO plan_exercises (plan_id, category, exercise_name, duration, days)
         VALUES ($1, $2, $3, $4, $5)`,
        [planId, exercise.category, exercise.name, exercise.duration, exercise.days],
      );
    }

    await db.query("COMMIT");

    console.log(`✅ Plan saved successfully for user ${userId}, plan_id: ${planId}`);
    return planId;
  } catch (error) {
    await db.query("ROLLBACK");
    console.error("Error saving plan to database:", error);
    throw error;
  }
}

/**
 * Endpoint to handle plan approval explicitly (for an Approve button)
 */
export async function approvePlan(req, res) {
  try {
    const userId = req.user?.userid || req.user?.userId;

    if (!userId || isNaN(parseInt(userId))) {
      return res.status(401).json({ error: "Authentication required" });
    }


    const userProfile = req.body.userProfile || {};
    const conversationState = getConversationState(userId);

    if (conversationState.state !== "awaiting_approval") {
      return res.status(400).json({ error: "No plan awaiting approval" });
    }

    const plan = getGeneratedPlan(userId);
    if (!plan) {
      return res.status(404).json({ error: "No plan found" });
    }

    const planId = await savePlanToDatabase(userId, plan, userProfile);

    updateConversationState(userId, { state: "approved" });
    updateConversationState(userId, { state: "approved" });

    res.json({
      message: "Plan approved and saved successfully!",
      planId: planId,
    });
  } catch (error) {
    console.error("Error approving plan:", error);
    res.status(500).json({ error: "Failed to save plan" });
  }
}