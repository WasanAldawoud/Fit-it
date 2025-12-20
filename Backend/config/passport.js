//Defines the steps to verify a password hash against the stored hash.
//serializeUser writes the minimal info (ID) to the cookie. deserializeUser reads the ID from the cookie to fetch the full user from the DB on every request.
import passport from "passport";
import { Strategy as LocalStrategy } from "passport-local";
import bcrypt from "bcryptjs";
import db from "./db.js"; 
import env from "dotenv";

env.config();

// 1. SERIALIZE (Write to Cookie)
// This runs when req.login() is called in the Controller.
// It decides what piece of info to save in the browser/app cookie.
passport.serializeUser((user, cb) => {
  console.log("🔹 DEBUG: Serializing User:", user);

  // We look for userId. If it's missing, we log an error.
  const id = user.userId || user.userid || user.id;

  if (!id) {
    console.error("❌ ERROR: No ID found on user object");
    return cb(new Error("User ID is missing"), null);
  }

  // Save ONLY the ID to the session (keeps it fast)
  console.log("🔹 DEBUG: Saving ID to session:", id);
  cb(null, id);
});

// 2. DESERIALIZE (Read from Cookie)
// This runs on every subsequent request from the mobile app.
// It takes the ID from the cookie and finds the full user in the DB.
passport.deserializeUser(async (id, cb) => {
  try {
    // We look up the user using the ID we saved earlier.
    const result = await db.query("SELECT * FROM users WHERE userId = $1", [id]);
    cb(null, result.rows[0]);
  } catch (err) {
    cb(err);
  }
});

// 3. LOGIN STRATEGY (Used for Login Screen later)
passport.use(
     "local",
    new LocalStrategy(
     // ⚠️ CHANGE 1: Set usernameField to "username" to match the input from Flutter
    { usernameField: "username", passwordField: "password" }, 
     // ⚠️ CHANGE 2: The first argument is now the username
    async (username, password, cb) => { 
   try {
  // Step A: Find user by USERNAME
     // ⚠️ CHANGE 3: Update SQL query to search for 'username'
    const result = await db.query("SELECT * FROM users WHERE username = $1", [username]); 
   
    if (result.rows.length > 0) {
    const user = result.rows[0];
     // Step B: Check password
    const valid = await bcrypt.compare(password, user.password_hash);
    
     if (valid) {
    return cb(null, user); // Success
     } else {
     return cb(null, false, { message: "Incorrect password" });
     }
     } else {
   // ⚠️ CHANGE 4: Update error message
   return cb(null, false, { message: "Username not registered" }); 
     }
     } catch (err) {
     return cb(err);
     }
     }
     )
    );

export default passport;