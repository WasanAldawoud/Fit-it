import { jest } from "@jest/globals";

// Mock the OpenAI client
jest.mock("../Ai/openaiClient.js", () => ({
  default: {
    chat: {
      completions: {
        create: jest.fn(),
      },
    },
  },
}));

// Mock database
jest.mock("../config/db.js", () => ({
  query: jest.fn(),
  connect: jest.fn(),
}));

import client from "../Ai/openaiClient.js";
import db from "../config/db.js";
import { approvePlan, extractInformationFromMessage, generateFitnessChat } from "../Ai/aiController.js";
import {
  extractPlanMetadata,
  formatPlanForDatabase,
  parsePlanFromResponse,
  validatePlan,
} from "../Ai/planParser.js";
import {
  getConversationState,
  getGeneratedPlan,
  isInfoComplete,
  resetConversationState,
  saveGeneratedPlan,
  updateConversationState,
  updateGatheredInfo,
} from "../Ai/memoryStore.js";

describe("AI Workflow Tests", () => {
  const mockUserId = "test_user_123";
  const mockUserProfile = {
    height: 170,
    weight: 90,
    equipment: false,
    gender: "male",
    birthdate: "1990-01-01",
  };

  beforeEach(() => {
    jest.clearAllMocks();
    resetConversationState(mockUserId);
  });

  describe("Information Extraction", () => {
    test("extracts goal from message", () => {
      const message = "I want to lose weight";
      const result = extractInformationFromMessage(message);
      expect(result.goal).toBe("weight loss");
    });

    test("extracts workout style from message", () => {
      const message = "I like cardio and yoga";
      const result = extractInformationFromMessage(message);
      expect(result.workoutStyle).toBe("Mixed");
    });

    test("extracts days from message", () => {
      const message = "I can work out 3 days a week";
      const result = extractInformationFromMessage(message);
      expect(result.days).toBe(3);
    });

    test("extracts all info from single message", () => {
      const message =
        "I want to build muscle, I like strength training, and I can work out 4 days per week";
      const result = extractInformationFromMessage(message);
      expect(result.goal).toBe("muscle gain");
      expect(result.workoutStyle).toBe("Strength Training");
      expect(result.days).toBe(4);
    });
  });

  describe("Conversation State Management", () => {
    test("initial state is welcome", () => {
      const state = getConversationState(mockUserId);
      expect(state.state).toBe("welcome");
      expect(state.isFirstMessage).toBe(true);
    });

    test("transitions from welcome to gathering_info", () => {
      const updatedState = updateConversationState(mockUserId, { state: "gathering_info" });
      expect(updatedState.state).toBe("gathering_info");
    });

    test("tracks gathered information", () => {
      updateGatheredInfo(mockUserId, { goal: "weight loss" });
      const state = getConversationState(mockUserId);
      expect(state.gatheredInfo.goal).toBe("weight loss");
    });

    test("detects when information is complete", () => {
      updateGatheredInfo(mockUserId, {
        goal: "weight loss",
        workoutStyle: "Cardio",
        days: 3,
      });
      expect(isInfoComplete(mockUserId)).toBe(true);
    });

    test("detects when information is incomplete", () => {
      updateGatheredInfo(mockUserId, { goal: "weight loss" });
      expect(isInfoComplete(mockUserId)).toBe(false);
    });
  });

  describe("Plan Parsing", () => {
    test("parses valid workout plan", () => {
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
      expect(plan.exercises[0].category).toBe("Cardio");
      expect(plan.exercises[0].name).toBe("Brisk Walking");
    });

    test("validates plan structure", () => {
      const validPlan = {
        exercises: [
          {
            category: "Cardio",
            name: "Running",
            duration: "30 mins",
            days: ["Monday"],
          },
        ],
      };

      expect(validatePlan(validPlan)).toBe(true);
    });

    test("rejects invalid plan", () => {
      const invalidPlan = {
        exercises: [],
      };

      expect(validatePlan(invalidPlan)).toBe(false);
    });

    test("formats plan for database", () => {
      const plan = {
        exercises: [
          {
            category: "Cardio",
            name: "Running",
            duration: "30 mins",
            days: ["Monday"],
          },
        ],
      };

      const userInfo = {
        goal: "weight loss",
        duration_weeks: 4,
        current_weight: 90,
      };

      const dbPlan = formatPlanForDatabase(plan, userInfo);
      expect(dbPlan.plan_name).toBe("AI Generated Workout Plan");
      expect(dbPlan.exercises).toHaveLength(1);
      expect(dbPlan.goal).toBe("weight loss");
    });

    test("extracts plan metadata", () => {
      const aiResponse = `
Goal: weight loss
Duration: 4 weeks

**Monday:**
- Cardio: Running - 30 mins
      `;

      const meta = extractPlanMetadata(aiResponse);
      expect(meta).toBeDefined();
    });
  });

  describe("API Endpoints", () => {
    let mockReq, mockRes;

    beforeEach(() => {
      mockReq = {
        // ✅ required: controller reads userId from session
        user: { userid: mockUserId },
        body: {
          userId: mockUserId, // ignored by controller (kept only to match old callers)
          message: "I want to lose weight",
          userProfile: mockUserProfile,
        },
      };

      mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };
    });

    test("handles chat request successfully", async () => {
      client.chat.completions.create.mockResolvedValue({
        choices: [
          {
            message: {
              content: "Great! Let's create your plan. What type of workouts do you prefer?",
            },
          },
        ],
      });

      await generateFitnessChat(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          reply: expect.any(String),
          conversationState: expect.any(String),
          planGenerated: expect.any(Boolean),
          awaitingApproval: expect.any(Boolean),
        }),
      );
    });

    test("rejects unauthenticated chat request", async () => {
      const req = {
        body: {
          message: "Hello",
          userProfile: mockUserProfile,
        },
      };

      await generateFitnessChat(req, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(401);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: "Authentication required",
        }),
      );
    });

    test("handles approval request", async () => {
      // Ensure a plan exists and state is awaiting_approval
      const mockPlan = {
        exercises: [
          {
            category: "Cardio",
            name: "Running",
            duration: "30 mins",
            days: ["Monday"],
          },
        ],
      };
      saveGeneratedPlan(mockUserId, mockPlan);

      // Mock db transaction calls:
      // BEGIN, INSERT (RETURNING plan_id), INSERT exercise, COMMIT
      db.query
        .mockResolvedValueOnce({}) // BEGIN
        .mockResolvedValueOnce({ rows: [{ plan_id: 123 }] }) // INSERT plan
        .mockResolvedValueOnce({}) // INSERT exercise
        .mockResolvedValueOnce({}); // COMMIT

      const approveReq = {
        user: { userid: mockUserId },
        body: { userProfile: mockUserProfile },
      };

      await approvePlan(approveReq, mockRes);

      expect(db.query).toHaveBeenCalled();
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: expect.stringContaining("approved"),
          planId: 123,
        }),
      );
    });

    test("returns 400 when no plan awaiting approval", async () => {
      // initial state is welcome
      const approveReq = {
        user: { userid: mockUserId },
        body: { userProfile: mockUserProfile },
      };

      await approvePlan(approveReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: "No plan awaiting approval",
        }),
      );
    });

    test("handles invalid request (missing fields)", async () => {
      const invalidReq = {
        user: { userid: mockUserId }, // authenticated so we test validation
        body: {},
      };

      await generateFitnessChat(invalidReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: expect.any(String),
        }),
      );
    });
  });

  describe("Error Handling", () => {
    test("handles OpenAI API errors", async () => {
      client.chat.completions.create.mockRejectedValue(new Error("API Error"));

      const mockReq = {
        user: { userid: mockUserId },
        body: {
          message: "Hello",
          userProfile: mockUserProfile,
        },
      };

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await generateFitnessChat(mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: "Internal server error",
        }),
      );
    });

    test("handles database errors during plan approval", async () => {
      const mockPlan = {
        exercises: [
          {
            category: "Cardio",
            name: "Running",
            duration: "30 mins",
            days: ["Monday"],
          },
        ],
      };
      saveGeneratedPlan(mockUserId, mockPlan);

      // Any db call fails -> controller should return 500
      db.query.mockRejectedValue(new Error("Database connection failed"));

      const approveReq = {
        user: { userid: mockUserId },
        body: {
          userProfile: mockUserProfile,
        },
      };

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      await approvePlan(approveReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: "Failed to save plan",
        }),
      );
    });
  });

  describe("Conversation Flow Integration", () => {
    test("complete happy path flow reaches awaiting_approval", async () => {
      client.chat.completions.create
        .mockResolvedValueOnce({
          choices: [{ message: { content: "Welcome! What's your goal?" } }],
        })
        .mockResolvedValueOnce({
          choices: [{ message: { content: "Great! Now workout style?" } }],
        })
        .mockResolvedValueOnce({
          choices: [{ message: { content: "Perfect! Now days?" } }],
        })
        .mockResolvedValueOnce({
          choices: [
            {
              message: {
                content: `## Your Plan
**Monday:**
- Cardio: Running - 30 mins

Would you like to approve this plan?`,
              },
            },
          ],
        });

      const mockRes = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn(),
      };

      // Step 1: Hello
      let req = {
        user: { userid: mockUserId },
        body: {
          message: "Hello",
          userProfile: mockUserProfile,
        },
      };

      await generateFitnessChat(req, mockRes);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({ conversationState: "gathering_info" }),
      );

      // Step 2: goal
      req.body.message = "I want to lose weight";
      await generateFitnessChat(req, mockRes);

      // Step 3: style
      req.body.message = "I like cardio";
      await generateFitnessChat(req, mockRes);

      // Step 4: days -> triggers generating plan -> postProcess -> awaiting_approval
      req.body.message = "3 days a week";
      await generateFitnessChat(req, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({ conversationState: "awaiting_approval" }),
      );

      // And ensure the plan is actually stored in memory
      const storedPlan = getGeneratedPlan(mockUserId);
      expect(storedPlan).toBeTruthy();
    });
  });
});