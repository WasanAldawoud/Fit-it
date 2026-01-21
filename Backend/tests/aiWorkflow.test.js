import { jest } from '@jest/globals';

// Mock the OpenAI client
jest.mock('../Ai/openaiClient.js', () => ({
  default: {
    chat: {
      completions: {
        create: jest.fn()
      }
    }
  }
}));

// Mock database
jest.mock('../config/db.js', () => ({
  query: jest.fn(),
  connect: jest.fn()
}));

import client from '../Ai/openaiClient.js';
import db from '../config/db.js';
import { generateFitnessChat, approvePlan } from '../Ai/aiController.js';
import {
  parsePlanFromResponse,
  validatePlan,
  formatPlanForDatabase,
  extractPlanMetadata
} from '../Ai/planParser.js';
import {
  getConversationState,
  updateConversationState,
  updateGatheredInfo,
  isInfoComplete,
  saveGeneratedPlan,
  getGeneratedPlan,
  resetConversationState
} from '../Ai/memoryStore.js';
import { extractInformationFromMessage } from '../Ai/aiController.js';

describe('AI Workflow Tests', () => {
  const mockUserId = 'test_user_123';
  const mockUserProfile = {
    height: 170,
    weight: 90,
    equipment: false,
    gender: 'male',
    birthdate: '1990-01-01'
  };

  beforeEach(() => {
    jest.clearAllMocks();
    resetConversationState(mockUserId);
  });

  describe('Information Extraction', () => {
    test('extracts goal from message', () => {
      const message = 'I want to lose weight';
      const result = extractInformationFromMessage(message);
      expect(result.goal).toBe('weight loss');
    });

    test('extracts workout style from message', () => {
      const message = 'I like cardio and yoga';
      const result = extractInformationFromMessage(message);
      expect(result.workoutStyle).toBe('Mixed');
    });

    test('extracts days from message', () => {
      const message = 'I can work out 3 days a week';
      const result = extractInformationFromMessage(message);
      expect(result.days).toBe(3);
    });

    test('extracts all info from single message', () => {
      const message = 'I want to build muscle, I like strength training, and I can work out 4 days per week';
      const result = extractInformationFromMessage(message);
      expect(result.goal).toBe('muscle gain');
      expect(result.workoutStyle).toBe('Strength Training');
      expect(result.days).toBe(4);
    });
  });

  describe('Conversation State Management', () => {
    test('initial state is welcome', () => {
      const state = getConversationState(mockUserId);
      expect(state.state).toBe('welcome');
      expect(state.isFirstMessage).toBe(true);
    });

    test('transitions from welcome to gathering_info', () => {
      const initialState = getConversationState(mockUserId);
      const updatedState = updateConversationState(mockUserId, { state: 'gathering_info' });
      expect(updatedState.state).toBe('gathering_info');
    });

    test('tracks gathered information', () => {
      updateGatheredInfo(mockUserId, { goal: 'weight loss' });
      const state = getConversationState(mockUserId);
      expect(state.gatheredInfo.goal).toBe('weight loss');
    });

    test('detects when information is complete', () => {
      updateGatheredInfo(mockUserId, {
        goal: 'weight loss',
        workoutStyle: 'Cardio',
        days: 3
      });
      expect(isInfoComplete(mockUserId)).toBe(true);
    });

    test('detects when information is incomplete', () => {
      updateGatheredInfo(mockUserId, { goal: 'weight loss' });
      expect(isInfoComplete(mockUserId)).toBe(false);
    });
  });

  describe('Plan Parsing', () => {
    test('parses valid workout plan', () => {
      const aiResponse = `
## Your Personalized Workout Plan

**Monday:**
- Cardio: Brisk Walking - 30 mins
- Stretching: Hamstring Stretch - 10 mins

**Wednesday:**
- Strength Training: Squats - 3 sets of 12 reps
- Core Exercises: Plank - 3 sets of 30 seconds
      `;

      const plan = parsePlanFromResponse(aiResponse);
      expect(plan).not.toBeNull();
      expect(plan.exercises).toHaveLength(4);
      expect(plan.exercises[0].category).toBe('Cardio');
      expect(plan.exercises[0].name).toBe('Brisk Walking');
    });

    test('validates plan structure', () => {
      const validPlan = {
        exercises: [
          {
            category: 'Cardio',
            name: 'Running',
            duration: '30 mins',
            days: ['Monday']
          }
        ]
      };

      expect(validatePlan(validPlan)).toBe(true);
    });

    test('rejects invalid plan', () => {
      const invalidPlan = {
        exercises: []
      };

      expect(validatePlan(invalidPlan)).toBe(false);
    });

    test('formats plan for database', () => {
      const plan = {
        exercises: [
          {
            category: 'Cardio',
            name: 'Running',
            duration: '30 mins',
            days: ['Monday']
          }
        ]
      };

      const userInfo = {
        goal: 'weight loss',
        duration_weeks: 4,
        current_weight: 90
      };

      const dbPlan = formatPlanForDatabase(plan, userInfo);
      expect(dbPlan.plan_name).toBe('AI Generated Workout Plan');
      expect(dbPlan.exercises).toHaveLength(1);
      expect(dbPlan.goal).toBe('weight loss');
    });
  });

  describe('API Endpoints', () => {
    let mockReq, mockRes;

    beforeEach(() => {
      mockReq = {
        body: {
          userId: mockUserId,
          message: 'I want to lose weight',
          userProfile: mockUserProfile
        }
      };

      mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
    });

    test('handles chat request successfully', async () => {
      // Mock OpenAI response
      client.chat.completions.create.mockResolvedValue({
        choices: [{
          message: {
            content: 'Great! Let\'s create your plan. What type of workouts do you prefer?'
          }
        }]
      });

      await generateFitnessChat(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          reply: expect.any(String),
          conversationState: expect.any(String),
          planGenerated: expect.any(Boolean),
          awaitingApproval: expect.any(Boolean)
        })
      );
    });

    test('handles approval request', async () => {
      // Set up state with a generated plan
      const mockPlan = {
        exercises: [{
          category: 'Cardio',
          name: 'Running',
          duration: '30 mins',
          days: ['Monday']
        }]
      };

      saveGeneratedPlan(mockUserId, mockPlan);

      // Mock database
      db.query.mockResolvedValueOnce({ rows: [{ plan_id: 123 }] });
      db.query.mockResolvedValue({});

      const approveReq = {
        body: {
          userId: mockUserId,
          userProfile: mockUserProfile
        }
      };

      await approvePlan(approveReq, mockRes);

      expect(db.query).toHaveBeenCalledTimes(3); // BEGIN, INSERT, COMMIT
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: expect.stringContaining('approved'),
          planId: 123
        })
      );
    });

    test('handles invalid request', async () => {
      const invalidReq = {
        body: {} // Missing required fields
      };

      await generateFitnessChat(invalidReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: expect.any(String)
        })
      );
    });
  });

  describe('Error Handling', () => {
    test('handles OpenAI API errors', async () => {
      client.chat.completions.create.mockRejectedValue(new Error('API Error'));

      const mockReq = {
        body: {
          userId: mockUserId,
          message: 'Hello',
          userProfile: mockUserProfile
        }
      };

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };

      await generateFitnessChat(mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Internal server error'
        })
      );
    });

    test('handles database errors during plan approval', async () => {
      const mockPlan = {
        exercises: [{
          category: 'Cardio',
          name: 'Running',
          duration: '30 mins',
          days: ['Monday']
        }]
      };

      saveGeneratedPlan(mockUserId, mockPlan);

      // Mock database error
      db.query.mockRejectedValue(new Error('Database connection failed'));

      const approveReq = {
        body: {
          userId: mockUserId,
          userProfile: mockUserProfile
        }
      };

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };

      await approvePlan(approveReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Failed to save plan'
        })
      );
    });
  });

  describe('Conversation Flow Integration', () => {
    test('complete happy path flow', async () => {
      // Mock OpenAI responses for each state
      client.chat.completions.create
        .mockResolvedValueOnce({
          choices: [{ message: { content: 'Welcome! What\'s your goal?' } }]
        })
        .mockResolvedValueOnce({
          choices: [{ message: { content: 'Great! Now workout style?' } }]
        })
        .mockResolvedValueOnce({
          choices: [{ message: { content: 'Perfect! Now days?' } }]
        })
        .mockResolvedValueOnce({
          choices: [{
            message: {
              content: `## Your Plan
**Monday:**
- Cardio: Running - 30 mins

Would you like to approve this plan?`
            }
          }]
        });

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };

      // Step 1: Welcome
      let req = {
        body: {
          userId: mockUserId,
          message: 'Hello',
          userProfile: mockUserProfile
        }
      };

      await generateFitnessChat(req, mockRes);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({ conversationState: 'gathering_info' })
      );

      // Step 2: Provide goal
      req.body.message = 'I want to lose weight';
      await generateFitnessChat(req, mockRes);

      // Step 3: Provide style
      req.body.message = 'I like cardio';
      await generateFitnessChat(req, mockRes);

      // Step 4: Provide days
      req.body.message = '3 days a week';
      await generateFitnessChat(req, mockRes);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({ conversationState: 'awaiting_approval' })
      );
    });
  });
});
