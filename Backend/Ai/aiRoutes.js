import express from "express";
import passport from "passport";
import db from "../config/db.js";
import { generateFitnessChat, approvePlan } from "./aiController.js";

const router = express.Router();

/* ======================================================
   AUTH MIDDLEWARE
====================================================== */
const requireAuth = (req, res, next) => {
  if (req.user) {
    return next();
  }
  return res.status(401).json({ error: "Authentication required" });
};

/* ======================================================
   AI CHAT + APPROVAL ROUTES (AUTH REQUIRED)
====================================================== */

// Chat with AI fitness coach
router.post(
  "/fitness-chat",
  passport.authenticate("session"),
  requireAuth,
  generateFitnessChat
);

// Approve generated plan
router.post(
  "/approve-plan",
  passport.authenticate("session"),
  requireAuth,
  approvePlan
);

/* ======================================================
   GET ACTIVE PLAN
====================================================== */
router.get(
  "/active-plan",
  passport.authenticate("session"),
  requireAuth,
  async (req, res) => {
    const userId =
      req.user?.userid || req.user?.userId || req.user?.id;

    if (!userId) {
      return res.status(401).json({ error: "Authentication required" });
    }

    try {
      const result = await db.query(
        `
        SELECT p.*,
               COALESCE(
                 json_agg(e.*) FILTER (WHERE e.exercise_id IS NOT NULL),
                 '[]'
               ) AS exercises
        FROM user_plans p
        LEFT JOIN plan_exercises e ON p.plan_id = e.plan_id
        WHERE p.user_id = $1
          AND p.is_active = true
        GROUP BY p.plan_id
        ORDER BY p.created_at DESC
        LIMIT 1
        `,
        [userId]
      );

      res.json(result.rows[0] || null);
    } catch (err) {
      console.error("Active plan fetch error:", err);
      res.status(500).json({ error: "Database error" });
    }
  }
);

export default router;
