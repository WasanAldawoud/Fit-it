//Handles the request, checks password (with bcrypt), and writes the new user to the DB (via db.js).

import bcrypt from "bcryptjs";
import db from "../config/db.js";
// ⚠️ NEW: Import 'passport' for the sign-in route
import passport from "passport";

export const signUp = async (req, res) => {
  // 1. Unpack the box (req.body) sent from Flutter
  const { username, email, password, gender, birthdate, weight, height } = req.body;
  // This uses "destructuring" to pull specific variables out of the JSON object sent by Flutter.
  // req.body represents the raw data the user typed into the sign-up form.

  try {
    // 2. Validation: Fail immediately if data is missing
    if (!username || !email || !password || !gender || !birthdate || !weight || !height) {
      // This checks if any of these variables are undefined, null, or empty strings.
      return res.status(400).json({ error: "All fields are required" });
      // Status 400 (Bad Request) tells the app that it didn't send the right information.
    }

    // 3. Duplicate Check: Ask DB "Do we have this email?"
    const userExist = await db.query("SELECT * FROM users WHERE email = $1", [email]);
    // We search the 'users' table specifically for the email provided.
    // Using [email] as a separate array prevents SQL injection.

    if (userExist.rows.length > 0) {
      // If result.rows is not empty, it means that email is already in our system.
      return res.status(409).json({ error: "User already exists" });
      // Status 409 (Conflict) is the standard code for duplicate data.
    }

    // 4. Hashing: Scramble the password so it's safe
    const salt = await bcrypt.genSalt(10);
    // Generates a "salt," which is a random string added to the password to make it harder to crack.
    const hashedPassword = await bcrypt.hash(password, salt);
    // Turns the plain password (e.g., "12345") into a long, unreadable string.

    // 5. Save: Insert the new user into the database
    const newUser = await db.query(
      "INSERT INTO users (username, email, password_hash, gender, birthdate, weight, height) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *",
      // RETURNING * tells PostgreSQL to give us back the full record it just created.
      [username, email, hashedPassword, gender, birthdate, weight, height]
      // We save the HASHED password, never the plain one.
    );

    const user = newUser.rows[0];
    // Extracts the single user record from the array returned by the DB.

    // 6. THE HANDOVER: This is the magic link to Passport.js
    req.login(user, (err) => {
      // Normally, sign-up just saves data. req.login() forces the user to be "logged in" immediately.
      // This creates the session cookie so they don't have to log in manually after signing up.
      if (err) {
        return res.status(500).json({ error: "Signup successful, but login failed" });
        // This triggers if the serialization process fails.
      }

      // Force session save to ensure cookie works immediately
      req.session.save((err) => {
        if (err) return res.status(500).json({ error: "Session save failed" });

        // 7. Success: Send 201 code
        return res.status(201).json({
          message: "User registered successfully",
          user: {
            userId: user.userid || user.userId,
            username: user.username,
            email: user.email,
            gender: user.gender,
            birthdate: user.birthdate,
            weight: user.weight,
            height: user.height
          },
        });
      });
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
    // This is the "Safety Net" for database crashes or unexpected code errors.
  }
};


export const signIn = (req, res, next) => {
  passport.authenticate('local', (err, user, info) => {
    // passport.authenticate triggers the 'local' strategy logic we wrote in the passport config.
    // The (err, user, info) parameters are the results passed back from 'cb(null, user)'.

    if (err) {
      // Triggers if there was a database error during the strategy execution.
      console.error("❌ Passport Auth Error:", err);
      return res.status(500).json({ error: "Server error during authentication" });
    }

    if (!user) {
      // Triggers if the password was wrong or the username wasn't found.
      console.log("❌ Login failed:", info?.message);
      return res.status(401).json({ error: info?.message || "Authentication failed" });
      // info.message usually contains "Incorrect password" or "Username not registered".
    }

    // 3. Log the user in (creates the session cookie)
    req.login(user, (err) => {
      // This actually attaches the user to the session and sets the cookie header.
      if (err) {
        return res.status(500).json({ error: "Login failed after authentication" });
      }

      req.session.save((err) => {
        if (err) return res.status(500).json({ error: "Session save failed" });
        console.log("✅ User logged in successfully:", user.username);

        // 4. Success: Send 200 code and user data
        return res.status(200).json({
          message: "User logged in successfully",
          user: {
            userId: user.userid || user.userId,
            username: user.username,
            email: user.email,
          }
          // We only send back the necessary data, not the password hash!
        });
      });
    });
  })(req, res, next); 
  // This trailing part (req, res, next) is required because passport.authenticate 
  // returns a function that needs to be called with the current request objects.
};

export const getProfile = (req, res) => {
  if (req.user) {
    // req.user is only available if the user has a valid session cookie.
    // Passport automatically populates this via the 'deserializeUser' function.
    res.status(200).json({
      user: {
        userId: req.user.userid || req.user.userId,
        username: req.user.username,
        email: req.user.email,
        gender: req.user.gender,
        birthdate: req.user.birthdate,
        weight: req.user.weight || 0,
        height: req.user.height || 0
      }
    });
  } else {
    // If there is no cookie or the session expired:
    res.status(401).json({ error: "Not authenticated" });
  }
};



export const updateProfile = async (req, res) => {
  const { username, gender, birthdate, weight, height } = req.body;
  
  // Allow session OR explicit userId from body
  const userId = req.user?.userid || req.user?.userId || req.body.userId;

  if (!userId) return res.status(401).json({ error: "Not authenticated" });

  try {
    const result = await db.query(
      "UPDATE users SET username = $1, gender = $2, birthdate = $3, weight = $4, height = $5 WHERE userid = $6 RETURNING *",
      // Updates the specific columns for the logged-in user.
      [username, gender, birthdate, weight, height, userId]
    );

    res.status(200).json({ message: "Profile updated", user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database update failed" });
  }
};

export const logout = (req, res) => {
  req.logout((err) => {
    if (err) {
      console.error("❌ Logout error:", err);
      return res.status(500).json({ error: "Logout failed" });
    }

    req.session.destroy(() => {
      res.clearCookie("connect.sid"); // 🔑 VERY IMPORTANT
      return res.status(200).json({ message: "Logged out successfully" });
    });
  });
};

    
export const googleCallback = (req, res) => {
  const webAppUrl = "http://localhost:5000/#/home"; 
  // The URL of your Flutter web build.

  res.send(`
    <html>
      <body>
        <script>
          // This script runs in the user's browser immediately after Google redirects them back.
          const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
          
          if (isMobile) {
            // Deep Linking: If on a phone, it tells the browser to open your Flutter app.
            // "fititapp://" must be configured in your AndroidManifest.xml and Info.plist.
            window.location.href = "fititapp://login-success";
          } else {
            // If on a computer, it simply redirects the browser tab to your Flutter web home page.
            window.location.href = "${webAppUrl}";
          }
        </script>
        <p>Redirecting to app...</p>
      </body>
    </html>
  `);
  // This HTML is a "bridge." It detects the device type and sends the user to the right place.
};


