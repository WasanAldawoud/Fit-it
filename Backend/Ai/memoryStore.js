const conversations = new Map();
const conversationStates = new Map();

/**
 * Conversation states:
 * - 'welcome': Initial state, needs to greet user
 * - 'gathering_info': Collecting goal, workout style, days
 * - 'generating_plan': Creating workout plan
 * - 'awaiting_approval': Plan generated, waiting for user approval
 * - 'approved': Plan approved and saved
 * - 'chat': General conversation mode
 */

export function getConversation(userId) {
  return conversations.get(userId) || [];
}

export function saveConversation(userId, messages) {
  conversations.set(userId, messages.slice(-20)); // limit memory
}

export function getConversationState(userId) {
  if (!conversationStates.has(userId)) {
    return {
      state: 'welcome',
      gatheredInfo: {
        goal: null,
        workoutStyle: null,
        days: null
      },
      generatedPlan: null,
      isFirstMessage: true
    };
  }
  return conversationStates.get(userId);
}

export function updateConversationState(userId, updates) {
  const currentState = getConversationState(userId);
  const newState = { ...currentState, ...updates };
  conversationStates.set(userId, newState);
  return newState;
}

export function resetConversationState(userId) {
  conversationStates.delete(userId);
  conversations.delete(userId);
}

export function updateGatheredInfo(userId, info) {
  const state = getConversationState(userId);
  state.gatheredInfo = { ...state.gatheredInfo, ...info };
  conversationStates.set(userId, state);
  return state;
}

export function isInfoComplete(userId) {
  const state = getConversationState(userId);
  const { goal, workoutStyle, days } = state.gatheredInfo;
  return goal !== null && workoutStyle !== null && days !== null;
}

export function saveGeneratedPlan(userId, plan) {
  const state = getConversationState(userId);
  state.generatedPlan = plan;
  state.state = 'awaiting_approval';
  conversationStates.set(userId, state);
}

export function getGeneratedPlan(userId) {
  const state = getConversationState(userId);
  return state.generatedPlan;
}
