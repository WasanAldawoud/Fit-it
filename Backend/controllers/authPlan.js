import db from "../config/db.js";

// --- 1. SAVE USER PLAN ---
// Creates the plan metadata and links the specific exercises to it.
export const saveUserPlan = async (req, res) => {
    const { plan_name, exercises, goal, duration_weeks, deadline, current_weight, goal_weight } = req.body;
    const userId = req.user?.userid || req.user?.userId || req.user?.id;
    
    if (!userId) {
        return res.status(401).json({ error: "Unauthorized. Please log in." });
    }

    try {
        await db.query('BEGIN'); // Start transaction for data safety

        const planResult = await db.query(
            `INSERT INTO user_plans (user_id, plan_name, goal, duration_weeks, deadline, current_weight, goal_weight) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING plan_id`,
            [userId, plan_name || 'My Workout Plan', goal, duration_weeks, deadline, current_weight, goal_weight]
        );
        
        const planId = planResult.rows[0].plan_id;

        // Loop through exercises and link to the new planId
        for (const ex of exercises) {
            await db.query(
                "INSERT INTO plan_exercises (plan_id, category, exercise_name, duration, days) VALUES ($1, $2, $3, $4, $5)",
                [planId, ex.category, ex.name, ex.duration, ex.days]
            );
        }

        await db.query('COMMIT'); // Save changes
        res.status(201).json({ message: "Plan saved successfully!", planId });
    } catch (err) {
        await db.query('ROLLBACK'); // Cancel if any insert fails
        console.error("Error in saveUserPlan:", err.message);
        res.status(500).json({ error: "Database error: " + err.message });
    }
};

// --- 2. GET ALL USER PLANS ---
// Calculates today's progress by counting records in exercise_completions for CURRENT_DATE.
// --- 2. GET ALL USER PLANS ---
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
                "SELECT exercise_id, exercise_name, duration, days FROM plan_exercises WHERE plan_id = $1",
                [plan.plan_id]
            );
            // Ensure the key is 'exercises' to match Flutter syncFromBackend
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
    const userId = req.user?.userid || req.user?.userId || req.user?.id;
  
    if (!userId) return res.status(401).json({ error: "Unauthorized" });
  
    try {
      // 1. Get exercise_id
      const exResult = await db.query(
        `SELECT exercise_id FROM plan_exercises 
         WHERE plan_id = $1 AND exercise_name = $2`,
        [plan_id, exercise_name]
      );
  
      if (exResult.rows.length === 0) {
        return res.status(404).json({ error: "Exercise not found" });
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
  
// Weightlog table is deleted; logic is removed. Metadata is stored in user_plans columns.