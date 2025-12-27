// NEW: Save User Plan and Exercises
import db from "../config/db.js";
export const saveUserPlan = async (req, res) => {
    const { plan_name, exercises } = req.body;
    
    // 1. Double check the ID from the session
    // Since your DB uses userId (camelCase), Passport might store it as such.
    const userId = req.user?.userid || req.user?.userId || req.user?.id;
     console.log("Saving plan for user:", userId); // Add this to debug
  
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized. Please log in." });
    }
  
    try {
      await db.query('BEGIN');
  
      // 2. Insert into user_plans
      // Ensure the column in your DB is 'user_id' and not 'userid'
      const planResult = await db.query(
        "INSERT INTO user_plans (user_id, plan_name) VALUES ($1, $2) RETURNING plan_id",
        [userId, plan_name || 'My Workout Plan']
      );
      
      const planId = planResult.rows[0].plan_id;
  
      // 3. Insert exercises
      // We use a for...of loop for better error catching inside transactions
      for (const ex of exercises) {
        await db.query(
          "INSERT INTO plan_exercises (plan_id, category, exercise_name, duration, days) VALUES ($1, $2, $3, $4, $5)",
          [
            planId, 
            ex.category, 
            ex.name, 
            ex.duration, 
            ex.days // This MUST be an array from Flutter [ "Mon", "Tue" ]
          ]
        );
      }
  
      await db.query('COMMIT');
      res.status(201).json({ message: "Plan saved successfully!", planId });

    } catch (err) {
      await db.query('ROLLBACK');
      // THIS LOG IS CRITICAL: Check your terminal after it fails
      console.error("❌ DATABASE ERROR DETAILS:", err.message); 
      res.status(500).json({ error: "Database error: " + err.message });
    }
};

