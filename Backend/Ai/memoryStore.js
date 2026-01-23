// memoryStore.js

const conversations = new Map();
const conversationStates = new Map();

/**
 * Conversation states:
 * - 'welcome': Initial greeting
 * - 'gathering_info': Collecting goal, workout style, days
 * - 'generating_plan': AI is generating the plan
 * - 'awaiting_approval': Plan generated, waiting for approval
 * - 'approved': Plan approved & saved
 * - 'chat': Normal chat mode
 */

/* -----------------------------
   Conversation Messages
------------------------------ */

export function getConversation(userId) {
  return conversations.get(userId) || [];
}

export function saveConversation(userId, messages) {
  // Keep only last 20 messages to avoid memory overflow
  conversations.set(userId, messages.slice(-20));
}

/* -----------------------------
   Conversation State
------------------------------ */

export function getConversationState(userId) {
  if (!conversationStates.has(userId)) {
    const initialState = {
      state: "welcome",
      gatheredInfo: {
        goal: null,
        workoutStyle: null,
        days: null,
      },
      generatedPlan: null,
      isFirstMessage: true,
    };

    conversationStates.set(userId, initialState);
    return initialState;
  }

  return conversationStates.get(userId);
}

export function updateConversationState(userId, updates) {
  const currentState = getConversationState(userId);

  const newState = {
    ...currentState,
    ...updates,
  };

  conversationStates.set(userId, newState);
  return newState;
}

export function resetConversationState(userId) {
  conversationStates.delete(userId);
  conversations.delete(userId);
}

/* -----------------------------
   Gathered Info Helpers
------------------------------ */

export function updateGatheredInfo(userId, info) {
  const state = getConversationState(userId);

  state.gatheredInfo = {
    ...state.gatheredInfo,
    ...info,
  };

  conversationStates.set(userId, state);
  return state;
}

export function isInfoComplete(userId) {
  const state = getConversationState(userId);
  const { goal, workoutStyle, days } = state.gatheredInfo;

  return (
    goal !== null &&
    workoutStyle !== null &&
    days !== null
  );
}

/* -----------------------------
   Generated Plan Helpers
------------------------------ */

export function saveGeneratedPlan(userId, plan) {
  const state = getConversationState(userId);

  state.generatedPlan = plan;
  state.state = "awaiting_approval";

  conversationStates.set(userId, state);
}

export function getGeneratedPlan(userId) {
  const state = getConversationState(userId);
  return state.generatedPlan;
}

export function markPlanApproved(userId) {
  const state = getConversationState(userId);

  state.state = "approved";

  conversationStates.set(userId, state);
}
