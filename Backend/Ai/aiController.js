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
  getGeneratedPlan,
} from "./memoryStore.js";
import {
  parsePlanFromResponse,
  validatePlan,
  formatPlanForDatabase,
  extractPlanMetadata,
} from "./planParser.js";
import db from "../config/db.js";

/* -----------------------------
   Deadline helpers (RESTORED)
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

function computeSafeDeadline({ providedDeadline, providedWeeks, fallbackWeeks = 4 }) {
  const safeWeeks = clampWeeks(providedWeeks ?? fallbackWeeks, 4, 52) ?? 4;

  if (providedDeadline) {
    const parsed = new Date(providedDeadline);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  return addWeeks(new Date(), safeWeeks);
}

function extractDeadlineFromMessage(message) {
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

/* ======================================================
   MAIN CHAT HANDLER
====================================================== */
export async function generateFitnessChat(req, res) {
  try {
    const { message, userProfile } = req.body;

    const userId =
      req.user?.userid ||
      req.user?.userId ||
      req.user?.id ||
      parseInt(req.body.userId);

    if (!userId || isNaN(userId)) {
      return res.status(400).json({ error: "Missing or invalid userId" });
    }

    if (!message || !userProfile) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    if (!client) {
      return res.status(503).json({ error: "AI service not configured" });
    }

    let history = getConversation(userId);
    let conversationState = getConversationState(userId);

    history.push({ role: "user", content: message });

    // ✅ Restore deadline extraction
    const deadlineInfo = extractDeadlineFromMessage(message);
    if (deadlineInfo.deadline || deadlineInfo.durationWeeks) {
      updateGatheredInfo(userId, deadlineInfo);
      conversationState = getConversationState(userId);
    }

    conversationState = await processUserMessage(
      userId,
      message,
      conversationState,
      userProfile
    );

    const systemPrompt = buildPrompt(userProfile, conversationState);

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "system", content: systemPrompt }, ...history],
      temperature: 0.7,
      max_tokens: 1000,
    });

    const aiMessage = response.choices[0].message.content;

    history.push({ role: "assistant", content: aiMessage });
    saveConversation(userId, history);

    const postProcessResult = await postProcessResponse(
      userId,
      aiMessage,
      conversationState,
      userProfile
    );

    // 🔥 CRITICAL FIX: persist state
    updateConversationState(userId, { state: postProcessResult.state });

    res.json({
      reply: aiMessage,
      conversationState: postProcessResult.state,
      planGenerated: postProcessResult.planGenerated,
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

  if (currentState === "welcome") {
    const info = extractInformationFromMessage(message);
    if (Object.keys(info).length) updateGatheredInfo(userId, info);
    return updateConversationState(userId, { state: "gathering_info" });
  }

  if (currentState === "gathering_info") {
    const info = extractInformationFromMessage(message);
    if (Object.keys(info).length) updateGatheredInfo(userId, info);

    if (isInfoComplete(userId)) {
      return updateConversationState(userId, { state: "generating_plan" });
    }
    return conversationState;
  }

  if (currentState === "awaiting_approval") {
    const isApproval =
      /^(yes|approve|looks good|perfect|great|ok|okay|sure|accept|save|confirm)/i.test(
        lowerMessage
      );
    const isRejection =
      /^(no|reject|change|modify|different|revise|but)/i.test(lowerMessage);

    if (isRejection) {
      const info = extractInformationFromMessage(message);
      if (Object.keys(info).length) updateGatheredInfo(userId, info);

      return updateConversationState(userId, {
        state: "gathering_info",
        generatedPlan: null,
      });
    }

    if (isApproval) {
      const plan = getGeneratedPlan(userId);
      if (plan) {
        await savePlanToDatabase(userId, plan, userProfile);
        return updateConversationState(userId, { state: "approved" });
      }
    }

    return conversationState;
  }

  if (currentState === "approved" || currentState === "chat") {
    const wantsNew = /new plan|another plan|start over/i.test(lowerMessage);
    if (wantsNew) {
      return updateConversationState(userId, {
        state: "welcome",
        gatheredInfo: {
          goal: null,
          workoutStyle: null,
          days: null,
          deadline: null,
          durationWeeks: null,
        },
        generatedPlan: null,
      });
    }
    return updateConversationState(userId, { state: "chat" });
  }

  return conversationState;
}

/* ======================================================
   POST-PROCESS AI RESPONSE
====================================================== */
async function postProcessResponse(userId, aiMessage, conversationState, userProfile) {
  if (conversationState.state === "generating_plan") {
    const parsedPlan = parsePlanFromResponse(aiMessage);

    if (parsedPlan && validatePlan(parsedPlan)) {
      const metadata = extractPlanMetadata(aiMessage);
      const gatheredInfo = conversationState.gatheredInfo || {};

      const duration_weeks =
        clampWeeks(gatheredInfo.durationWeeks ?? metadata.duration_weeks ?? 4, 4, 52) ??
        4;

      const deadlineDate = computeSafeDeadline({
        providedDeadline: gatheredInfo.deadline,
        providedWeeks: duration_weeks,
      });

      const planData = {
        ...parsedPlan,
        goal: gatheredInfo.goal || metadata.goal,
        duration_weeks,
        deadline: deadlineDate.toISOString(),
        current_weight: userProfile.weight,
        goal_weight: metadata.goal_weight || null,
      };

      saveGeneratedPlan(userId, planData);

      return {
        state: "awaiting_approval",
        planGenerated: true,
        awaitingApproval: true,
      };
    }
  }

  return {
    state: conversationState.state,
    planGenerated: false,
    awaitingApproval: conversationState.state === "awaiting_approval",
  };
}

/* ======================================================
   INFO EXTRACTION
====================================================== */
function extractInformationFromMessage(message) {
  const info = {};
  const lower = (message || "").toLowerCase();

  const goals = {
    "weight loss": ["lose weight", "weight loss", "fat loss"],
    "muscle gain": ["build muscle", "muscle gain", "bulk up"],
    "general fitness": ["general fitness", "stay fit", "get fit"],
  };

  for (const [goal, keys] of Object.entries(goals)) {
    if (keys.some((k) => lower.includes(k))) info.goal = goal;
  }

  const styles = {
    Cardio: ["cardio", "running"],
    Yoga: ["yoga"],
    "Strength Training": ["strength", "weights"],
    Stretching: ["stretch"],
    Pilates: ["pilates"],
    Cycling: ["cycling", "bike"],
    Swimming: ["swimming"],
  };

  for (const [style, keys] of Object.entries(styles)) {
    if (keys.some((k) => lower.includes(k))) info.workoutStyle = style;
  }

  const daysMatch = message.match(/(\d+)\s*(day|days)/i);
  if (daysMatch) info.days = parseInt(daysMatch[1]);

  return info;
}

/* ======================================================
   DATABASE SAVE
====================================================== */
async function savePlanToDatabase(userId, planData, userProfile) {
  try {
    const dbPlan = formatPlanForDatabase(planData, {
      goal: planData.goal,
      duration_weeks: planData.duration_weeks,
      deadline: planData.deadline,
      current_weight: userProfile.weight,
      goal_weight: planData.goal_weight,
    });

    await db.query("BEGIN");

    // ✅ deactivate old plans
    await db.query(
      "UPDATE user_plans SET is_active = false WHERE user_id = $1",
      [userId]
    );

    const result = await db.query(
      `INSERT INTO user_plans
       (user_id, plan_name, goal, duration_weeks, deadline, current_weight, goal_weight, is_active)
       VALUES ($1,$2,$3,$4,$5,$6,$7,true)
       RETURNING plan_id`,
      [
        userId,
        dbPlan.plan_name,
        dbPlan.goal,
        dbPlan.duration_weeks,
        dbPlan.deadline,
        dbPlan.current_weight,
        dbPlan.goal_weight,
      ]
    );

    const planId = result.rows[0].plan_id;

    for (const ex of dbPlan.exercises) {
      await db.query(
        `INSERT INTO plan_exercises
         (plan_id, category, exercise_name, duration, days)
         VALUES ($1,$2,$3,$4,$5)`,
        [planId, ex.category, ex.name, ex.duration, ex.days]
      );
    }

    await db.query("COMMIT");
    return planId;
  } catch (err) {
    await db.query("ROLLBACK");
    throw err;
  }
}

/* ======================================================
   APPROVAL ENDPOINT
====================================================== */
export async function approvePlan(req, res) {
  try {
    const userId =
      req.user?.userid ||
      req.user?.userId ||
      req.user?.id ||
      parseInt(req.body.userId);

    if (!userId || isNaN(userId)) {
      return res.status(400).json({ error: "Invalid user" });
    }

    const userProfile = req.body.userProfile || {};
    const state = getConversationState(userId);

    if (state.state !== "awaiting_approval") {
      return res.status(400).json({ error: "No plan awaiting approval" });
    }

    const plan = getGeneratedPlan(userId);
    if (!plan) return res.status(404).json({ error: "No plan found" });

    const planId = await savePlanToDatabase(userId, plan, userProfile);

    updateConversationState(userId, { state: "approved" });

    res.json({ message: "Plan approved and saved", planId });
  } catch (err) {
    res.status(500).json({ error: "Failed to approve plan" });
  }
}
