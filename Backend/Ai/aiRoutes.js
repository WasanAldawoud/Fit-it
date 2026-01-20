import express from "express";
import { generateFitnessChat, approvePlan } from "./aiController.js";
import passport from "passport";

const router = express.Router();

// Middleware to ensure user is authenticated
const requireAuth = (req, res, next) => {
  if (req.user) {
    return next();
  } else {
    return res.status(401).json({ error: "Authentication required" });
  }
};

// Temporarily disable auth for testing
router.post("/fitness-chat", generateFitnessChat);
router.post("/approve-plan", approvePlan);

export default router;
