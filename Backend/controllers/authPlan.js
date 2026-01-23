import db from "../config/db.js";

// --- 1. SAVE USER PLAN ---
// Creates the plan metadata and links the specific exercises to it.
// --- REFACTORED SAVE/UPDATE PLAN ---
export const saveUserPlan = async (req, res) => {
    // 1. Destructure plan_id from the body
    const { plan_id, plan_name, exercises, goal, duration_weeks, deadline, current_weight, goal_weight } = req.body;
    const userId = req.user?.userid || req.user?.userId || req.user?.id;
    
    if (!userId) {
        return res.status(401).json({ error: "Unauthorized. Please log in." });
    }

    try {
        await db.query('BEGIN');

        let finalPlanId = plan_id;

        if (plan_id) {
            // --- UPDATE EXISTING PLAN ---
            await db.query(
                `UPDATE user_plans 
                 SET plan_name = $1, goal = $2, duration_weeks = $3, deadline = $4, current_weight = $5, goal_weight = $6
                 WHERE plan_id = $7 AND user_id = $8`,
                [plan_name, goal, duration_weeks, deadline, current_weight, goal_weight, plan_id, userId]
            );

            // Clear old exercises to replace them with the updated list
            await db.query("DELETE FROM plan_exercises WHERE plan_id = $1", [plan_id]);
        } else {
            // --- CREATE NEW PLAN ---
            const planResult = await db.query(
                `INSERT INTO user_plans (user_id, plan_name, goal, duration_weeks, deadline, current_weight, goal_weight) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING plan_id`,
                [userId, plan_name || 'My Workout Plan', goal, duration_weeks, deadline, current_weight, goal_weight]
            );
            finalPlanId = planResult.rows[0].plan_id;
        }

        // --- SAVE EXERCISES (Used for both New and Update) ---
        for (const ex of exercises) {
            await db.query(
                "INSERT INTO plan_exercises (plan_id, category, exercise_name, duration, days) VALUES ($1, $2, $3, $4, $5)",
                [finalPlanId, ex.category, ex.name || ex.exercise_name, ex.duration, ex.days]
            );
        }

        await db.query('COMMIT');
        res.status(plan_id ? 200 : 201).json({ 
            message: plan_id ? "Plan updated!" : "Plan saved!", 
            planId: finalPlanId 
        });

    } catch (err) {
        await db.query('ROLLBACK');
        console.error("Error in saveUserPlan:", err.message);
        res.status(500).json({ error: "Database error: " + err.message });
    }
};
export const getAllUserPlans = async (req, res) => {
    const userId = req.user?.userid || req.user?.userId || req.user?.id;
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    try {
        const plansResult = await db.query(
            `SELECT p.*, 
            (SELECT COUNT(*) FROM plan_exercises WHERE plan_id = p.plan_id) as total_exercises,
            (SELECT COUNT(*)::int FROM exercise_completions WHERE plan_id = p.plan_id AND completed_at::date = CURRENT_DATE) as completed_today
            FROM user_plans p 
            WHERE p.user_id = $1 
            ORDER BY p.created_at DESC`,
            [userId]
        );

        let plans = plansResult.rows;

        for (let plan of plans) {
            const exercisesResult = await db.query(
                `SELECT ex.exercise_id, ex.exercise_name, ex.duration, ex.days,
                EXISTS (
                    SELECT 1 FROM exercise_completions ec 
                    WHERE ec.exercise_id = ex.exercise_id 
                    AND ec.completed_at::date = CURRENT_DATE
                ) as is_done
                FROM plan_exercises ex WHERE ex.plan_id = $1`,
                [plan.plan_id]
            );
            plan.exercises = exercisesResult.rows;
        }

        res.status(200).json(plans);
    } catch (err) {
        console.error("Error in getAllUserPlans:", err.message);
        res.status(500).json({ error: "Database error" });
    }
};
// --- 3. MARK EXERCISE COMPLETE ---
// Inserts a record into 'exercise_completions'. This is what makes the progress bar move.
export const markExerciseComplete = async (req, res) => {
    const { plan_id, exercise_name } = req.body;
    const userId = req.user?.userid || req.user?.userId;
  
    if (!userId) return res.status(401).json({ error: "Unauthorized" });
  
    try {
      // 1. Get exercise_id
      const exResult = await db.query(
        `SELECT pe.exercise_id FROM plan_exercises pe
         JOIN user_plans up ON pe.plan_id = up.plan_id
         WHERE pe.plan_id = $1 AND pe.exercise_name = $2 AND up.user_id = $3`,
        [plan_id, exercise_name, userId]
      );
  
      if (exResult.rows.length === 0) {
        return res.status(404).json({ error: "Exercise not found or unauthorized" });
      }
  
      const exerciseId = exResult.rows[0].exercise_id;
  
      // 2. Insert completion
      await db.query(
        `INSERT INTO exercise_completions 
         (user_id, plan_id, exercise_id, exercise_name) 
         VALUES ($1, $2, $3, $4)`,
        [userId, plan_id, exerciseId, exercise_name]
      );
  
      res.status(200).json({ message: "Progress updated!" });
    } catch (err) {
      console.error("Error in markExerciseComplete:", err.message);
      res.status(500).json({ error: "Server error" });
    }
  };
  
// --- 4. RENAME PLAN ---
export const renamePlan = async (req, res) => {
    const { plan_id, new_name } = req.body;
    const userId = req.user?.userid || req.user?.userId;

    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    try {
        const result = await db.query(
            "UPDATE user_plans SET plan_name = $1 WHERE plan_id = $2 AND user_id = $3 RETURNING *",
            [new_name, plan_id, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Plan not found or unauthorized" });
        }

        res.status(200).json({ message: "Plan renamed successfully", plan: result.rows[0] });
    } catch (err) {
        console.error("Error in renamePlan:", err.message);
        res.status(500).json({ error: "Database error" });
    }
};

// authPlan.js - Add this route
export const updatePlanExercises = async (req, res) => {
    const { plan_id, exercises } = req.body;
    const userId = req.user?.id; // Use your existing session/token logic

    try {
        await db.query('BEGIN'); // Start transaction

        // 1. Clear old exercises for this specific plan
        await db.query(
            "DELETE FROM plan_exercises WHERE plan_id = $1", 
            [plan_id]
        );

        // 2. Insert the new exercise list
        for (const ex of exercises) {
            await db.query(
                "INSERT INTO plan_exercises (plan_id, exercise_name, duration, days) VALUES ($1, $2, $3, $4)",
                [plan_id, ex.name, ex.duration, ex.days]
            );
        }

        await db.query('COMMIT'); // Success
        res.status(200).json({ message: "Plan updated successfully" });
    } catch (err) {
        await db.query('ROLLBACK'); // Cancel everything on error
        console.error("Update Plan Error:", err.message);
        res.status(500).json({ error: "Failed to update plan" });
    }
};


// Add this to your Node.js authPlan controller
export const deletePlan = async (req, res) => {
    const { planId } = req.params;
    const userId = req.user?.id || req.user?.userId || req.user?.userid;

    try {
        await db.query('BEGIN');

        // 1. Delete completion history first
        await db.query("DELETE FROM exercise_completions WHERE plan_id = $1", [planId]);

        // 2. Delete the exercises belonging to the plan
        await db.query("DELETE FROM plan_exercises WHERE plan_id = $1", [planId]);

        // 3. Delete the plan itself
        const result = await db.query(
            "DELETE FROM user_plans WHERE plan_id = $1 AND user_id = $2", 
            [planId, userId]
        );

        await db.query('COMMIT');
        res.status(200).json({ message: "Plan deleted successfully" });
    } catch (err) {
        await db.query('ROLLBACK');
        console.error("Delete Plan Error:", err.message);
        res.status(500).json({ error: "Server error: " + err.message });
    }
};
