//Handles the request, checks password (with bcrypt), and writes the new user to the DB (via db.js).

import bcrypt from "bcryptjs";
import db from "../config/db.js";
// ⚠️ NEW: Import 'passport' for the sign-in route
import passport from "passport";
export const signUp = async (req, res) => {
  // 1. Unpack the box (req.body) sent from Flutter
  const { username, email, password } = req.body;

  try {
    // 2. Validation: Fail immediately if data is missing
    if (!username || !email || !password) {
      return res.status(400).json({ error: "All fields are required" });
    }

    // 3. Duplicate Check: Ask DB "Do we have this email?"
    const userExist = await db.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);

    // If DB returns a row, stop here.
    if (userExist.rows.length > 0) {
      return res.status(409).json({ error: "User already exists" });
    }

    // 4. Hashing: Scramble the password so it's safe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 5. Save: Insert the new user into the database
    // RETURNING * gives us back the new 'userId' immediately
    const newUser = await db.query(
      "INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING *",
      [username, email, hashedPassword]
    );

    const user = newUser.rows[0];

    // 6. THE HANDOVER: This is the magic link to Passport.js
    // We call req.login() to manually tell Passport: "This user just signed up, log them in now!"
    req.login(user, (err) => {
      if (err) {
        return res.status(500).json({ error: "Signup successful, but login failed" });
      }

      // 7. Success: Send 201 code so Flutter navigates to ChoosingScreen
      return res.status(201).json({
        message: "User registered successfully",
        user: user,
      });
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

// ⚠️ NEW FUNCTION FOR SIGN IN
// ----------------------------------------------------
export const signIn = (req, res, next) => {
     // Passport's 'authenticate' middleware runs the 'local' strategy
     passport.authenticate('local', (err, user, info) => {
     // 1. Handle server/DB errors
     if (err) {
     console.error("Passport Auth Error:", err);
     return res.status(500).json({ error: "Server error during authentication" });
     }
    
     // 2. Handle failed authentication (e.g., wrong password, user not found)
     if (!user) {
     // 'info' contains the message from passport.js (e.g., "Incorrect password")
     return res.status(401).json({ error: info.message || "Authentication failed" });
     }
    
     // 3. Log the user in (creates the session cookie)
     req.login(user, (err) => {
     if (err) {
      console.error("req.login error:", err);
       return res.status(500).json({ error: "Login failed after authentication" });
     }
    
     // 4. Success: Send 200 code and user data
     return res.status(200).json({
       message: "User logged in successfully",
       user: {
             userId: user.userid || user.userId, 
             username: user.username,
             email: user.email,
             }
       });
     });
     })(req, res, next);
    };
    
