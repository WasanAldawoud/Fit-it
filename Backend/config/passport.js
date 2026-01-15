import passport from "passport"; 
// Imports the main Passport library which handles the authentication middleware logic.
// It acts as a manager for different "strategies" (ways of logging in).

import { Strategy as LocalStrategy } from "passport-local"; 
// Imports the specific logic for "Local" authentication (email/username and password).
// Renaming it to 'LocalStrategy' makes it more readable in the code below.

import bcrypt from "bcryptjs"; 
// Imports a library used to securely hash passwords so we don't store plain text.
// It is used here to compare the user's typed password with the hashed version in the DB.

import db from "./db.js"; 
// Imports your custom database connection instance (likely using 'pg' for PostgreSQL).
// This allows the auth code to run SQL queries against your 'users' table.

import env from "dotenv"; 
// Imports the dotenv library to manage sensitive information like API keys.
// This prevents hardcoding secrets like Google Client IDs into your source code.

import { Strategy as GoogleStrategy } from "passport-google-oauth20"; 
// Imports the OAuth 2.0 strategy specifically for Google's login system.
// This handles the complex "handshake" between your app and Google's servers.

env.config(); 
// Executes the configuration function that reads the .env file.
// It populates 'process.env' so variables like process.env.GOOGLE_CLIENT_ID are available.


// 1. SERIALIZE (Saving the user to the session)
/**
 * 1. SERIALIZATION
 * When a user logs in, Passport takes the user object and "serializes" it.
 * This means it picks one unique piece of data (the ID) to save into the session cookie.
 */
passport.serializeUser((user, cb) => {
  // This function runs only ONCE when the user successfully logs in.
  // Its job is to determine which small piece of information should be stored in the session cookie.

  const id = user.userid || user.userid || user.id;
  // Accesses the unique identifier from the user object returned by the DB or Google.
  // Checking multiple casings ensures the code doesn't crash if the DB returns 'userid' vs 'id'.

  console.log("🔹 STEP 1: Saving User ID to Session:", id);
  // Logs the ID being saved so you can debug the login process in the terminal.

  cb(null, id);
  // Calls the callback function. 'null' means no error occurred.
  // 'id' is the data that Passport will now encrypt into the user's browser cookie.
});

// 2. DESERIALIZE (Retrieving the user from the session)
/**
 * 2. DESERIALIZATION
 * On every single request (e.g., when the user refreshes the page), Passport sees the cookie.
 * It takes the ID from that cookie and runs this function to "find" the full user in your DB.
 */
passport.deserializeUser(async (id, cb) => {
  // This function runs on EVERY subsequent request the user makes to your server.
  // It takes the ID found in the cookie and looks for the full user profile.

  try {
    console.log("🔹 STEP 2: Looking up user by ID:", id);
    // Debug log to show which user is currently trying to access a protected route.

    const result = await db.query("SELECT * FROM users WHERE userid = $1", [id]);
    // Uses the ID from the cookie to ask the database for all columns for this specific user.
    // '$1' is a placeholder used to prevent SQL injection attacks.

    if (result.rows.length > 0) {
      // Checks if the database actually returned a user record.
      
      cb(null, result.rows[0]); 
      // Successful lookup! The full user object is passed to Passport.
      // Passport now attaches this object to 'req.user', making it available in your routes.
    } else { 
      console.log("❌ STEP 2 ERROR: User ID not found in database.");
      // Triggers if a cookie exists for an ID that was deleted from the database.

      cb(null, false);
      // Tells Passport that the session is invalid because the user doesn't exist anymore.
    }
  } catch (err) {
    console.error("❌ STEP 2 CRASH:", err);
    // Catches database connection errors or syntax errors.

    cb(err); 
    // Passes the error back to Express so the app can show an error page or log.
  }
});

// 3. LOGIN STRATEGY (Checking the password)
/**
 * 3. LOCAL STRATEGY (Login with Username/Password)
 */
passport.use(
  "local", // Names this strategy 'local' so you can call it using passport.authenticate('local').
  new LocalStrategy(
    { usernameField: "username", passwordField: "password" }, 
    // Tells Passport which fields in your HTML/JSON login form to look for.
    // It maps 'req.body.username' and 'req.body.password' to the variables in the function below.

    async (username, password, cb) => { 
      // The main logic for checking if credentials are correct.
      try {
        console.log("🔹 STEP 3: Attempting login for username:", username);
        // Debug log to track which user is attempting a login.

        const result = await db.query("SELECT * FROM users WHERE LOWER(username) = LOWER($1)", [username]); 
        // Queries the DB to see if the username provided exists.

        if (result.rows.length > 0) {
          const user = result.rows[0];
          // Stores the found user record in a temporary 'user' variable.

          if (!user.password_hash) {
            // Safety check: ensure the database column name matches what you wrote here.
            console.error("❌ STEP 3 ERROR: Column 'password_hash' not found!");
            return cb(null, false, { message: "Database error" });
          }

          const valid = await bcrypt.compare(password, user.password_hash);
          // bcrypt.compare takes the "plain" password from the user and hashes it.
          // It then checks if that new hash matches the one stored in the DB.

          if (valid) {
            console.log("✅ STEP 3 SUCCESS: Password matches!");
            return cb(null, user); 
            // Success! We pass the 'user' object forward to the Serialization step.
          } else {
            console.log("❌ STEP 3 FAIL: Wrong password.");
            return cb(null, false, { message: "Incorrect password" });
            // 'false' tells Passport the login failed. The message can be shown to the user.
          }
        } else {
          console.log("❌ STEP 3 FAIL: Username not found in DB.");
          return cb(null, false, { message: "Username not registered" }); 
          // Triggers if the SELECT query returns 0 rows.
        }
      } catch (err) {
        console.error("❌ STEP 3 CRASH:", err);
        return cb(err);
        // Handles technical failures like the DB being offline.
      }
    }
  )
);
passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID, // Your app's unique ID from Google Cloud Console.
      clientSecret: process.env.GOOGLE_CLIENT_SECRET, // Your secret key to prove it's your app.
      callbackURL: "/auth/google/callback", // Where Google sends the user after they click "Allow".
      userProfileURL: "https://www.googleapis.com/oauth2/v3/userinfo", // The endpoint used to fetch user details.
    },
    async (accessToken, refreshToken, profile, cb) => {
      // This function runs after the user logs into Google successfully.
      // 'profile' contains the user's Google name, email, and ID.
      try {
        const email = profile.emails[0].value; // Extracts the primary email.
        const username = profile.displayName; // Extracts the user's full name.
        const googleId = profile.id; // Extracts the unique, permanent Google ID.

        const result = await db.query("SELECT * FROM users WHERE email = $1", [email]);
        // Checks if this person has logged in before using this email.

        if (result.rows.length > 0) {
          // If the user already exists in our DB:
          return cb(null, result.rows[0]); // Log them in immediately.
        } else {
          // If this is a brand new user:
          const newUser = await db.query(
            "INSERT INTO users (username, email, password_hash, gender, weight, height, birthdate) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *",
            // We use RETURNING * to get the newly created user object (including its new ID).
            [username, email, `google_${googleId}`, 'Other', 0, 0, '2000-01-01'] 
            // We save the Google ID in the password field since they don't have a local password.
            // We provide default values for health data so the DB row can be created successfully.
          );
          return cb(null, newUser.rows[0]); // Log in the newly created user.
        }
      } catch (err) {
        console.error("❌ Google Auth Error:", err);
        return cb(err); // Handles errors during the database insert or lookup.
      }
    }
  )
);

export default passport; 
// Exports the configured Passport instance so it can be imported in your main 'index.js' or 'app.js'.