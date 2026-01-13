import db from "../config/db.js";
// Imports your database pool configuration to allow SQL execution.
// This is the bridge between your Node.js logic and your PostgreSQL data.

export const saveUserPlan = async (req, res) => {
  // An 'async' function that handles the request to save a workout plan.
  // 'req' contains the data sent from Flutter; 'res' is used to send the status back.

  const { plan_name, exercises } = req.body;
  // This 'unpacks' or 'destructures' the JSON object sent from the frontend.
  // It expects a 'plan_name' (string) and 'exercises' (an array of objects).

  // 1. Double check the ID from the session
  // This looks into the 'req.user' object which Passport.js created during login.
  // It checks multiple property names (userid, userId, id) because different 
  // database drivers or Passport setups might name the primary key differently.
  const userId = req.user?.userid || req.user?.userId || req.user?.id;
  
  // A debug log to help you see in the terminal which user is trying to save a plan.
  // If this prints 'undefined', it means the session cookie isn't being sent correctly.
  console.log("Saving plan for user:", userId); 

  if (!userId) {
    // If no ID is found, the user is not logged in or the session has expired.
    // We stop the function immediately with a 401 (Unauthorized) status.
    return res.status(401).json({ error: "Unauthorized. Please log in." });
  }

  try {
    // Starts a SQL Transaction. 
    // This ensures that if the server crashes halfway through, no partial data is saved.
    // It's an "all or nothing" approach for database integrity.
    await db.query('BEGIN');

    // 2. Insert into user_plans
    // This query creates the "Parent" record in the user_plans table.
    // It takes the userId from the session and the plan_name from the request body.
    const planResult = await db.query(
      "INSERT INTO user_plans (user_id, plan_name) VALUES ($1, $2) RETURNING plan_id",
      [userId, plan_name || 'My Workout Plan']
      // If 'plan_name' is empty, it defaults to 'My Workout Plan'.
      // 'RETURNING plan_id' asks PostgreSQL to send back the ID of the row it just created.
    );
    
    // We grab the new Plan ID so we can link the following exercises to this specific plan.
    const planId = planResult.rows[0].plan_id;

    // 3. Insert exercises
    // We use a 'for...of' loop because it handles 'await' correctly.
    // This loops through every exercise object sent in the 'exercises' array from Flutter.
    for (const ex of exercises) {
      // This query creates the "Child" records in the plan_exercises table.
      // Each exercise is linked to the 'planId' we generated in Step 2.
      await db.query(
        "INSERT INTO plan_exercises (plan_id, category, exercise_name, duration, days) VALUES ($1, $2, $3, $4, $5)",
        [
          planId,          // Links this exercise to the main plan.
          ex.category,     // The type of exercise (e.g., 'Legs', 'Cardio').
          ex.name,         // The specific name (e.g., 'Squats').
          ex.duration,     // How long the exercise lasts.
          ex.days          // An array like ['Mon', 'Wed']—PostgreSQL stores this as an 'ARRAY' type.
        ]
      );
    }

    // If all code above finished without errors, we 'COMMIT' the transaction.
    // This is the moment the data is actually permanently written to the database.
    await db.query('COMMIT');

    // Send a 201 (Created) status back to the Flutter app along with the new Plan ID.
    res.status(201).json({ message: "Plan saved successfully!", planId });

  } catch (err) {
    // If ANY error happens inside the 'try' block, we 'ROLLBACK'.
    // This deletes the 'user_plans' entry we made so we don't have "orphan" plans with no exercises.
    await db.query('ROLLBACK');

    // Logs the exact error message to your server console. 
    // This is the most important log for fixing bugs in your SQL or logic.
    console.error("❌ DATABASE ERROR DETAILS:", err.message); 

    // Sends the error message back to Flutter so the developer can see what went wrong.
    res.status(500).json({ error: "Database error: " + err.message });
  }
};