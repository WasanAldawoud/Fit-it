import express from "express";
import { generateFitnessChat, approvePlan } from "./aiController.js";

const router = express.Router();

/* ======================================================
   AUTH MIDDLEWARE
====================================================== */
const requireAuth = (req, res, next) => {
  if (req.user) {
    return next();
  } else {
    return res.status(401).json({ error: "Authentication required" });
  }
};

//  Require authentication for both chat + approval
router.post("/fitness-chat", requireAuth, generateFitnessChat);
router.post("/approve-plan", requireAuth, approvePlan);
// aiRoutes.js
router.get("/active-plan", requireAuth, async (req, res) => {
  const userId = req.user.userid;
  const result = await db.query(`
    SELECT p.*, 
      json_agg(e.*) as exercises 
    FROM user_plans p 
    LEFT JOIN plan_exercises e ON p.plan_id = e.plan_id 
    WHERE p.user_id = $1 AND p.is_active = true 
    GROUP BY p.plan_id 
    ORDER BY p.created_at DESC LIMIT 1`, [userId]);
    
  res.json(result.rows[0] || null);
});
export default router;