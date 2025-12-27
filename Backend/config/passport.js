//Defines the steps to verify a password hash against the stored hash.
//serializeUser writes the minimal info (ID) to the cookie. deserializeUser reads the ID from the cookie to fetch the full user from the DB on every request.
import passport from "passport";
import { Strategy as LocalStrategy } from "passport-local";
import bcrypt from "bcryptjs";
import db from "./db.js"; 
import env from "dotenv";

env.config();

// 1. SERIALIZE (Write ID to Cookie)
passport.serializeUser((user, cb) => {
  // Use whatever ID comes back from your DB (usually userid in lowercase for PG)
  const id = user.userid || user.userId || user.id;
  console.log("🔹 DEBUG: Serializing User ID:", id);
  cb(null, id);
});

// 2. DESERIALIZE (Read ID from Cookie and find User)
passport.deserializeUser(async (id, cb) => {
  try {
    console.log("🔹 DEBUG: Deserializing ID:", id);
    // Be careful: In your SQL 'Create Table', you used 'userId' 
    // but standard PG returns lowercase 'userid' unless quoted.
    const result = await db.query("SELECT * FROM users WHERE userid = $1", [id]);
    
    if (result.rows.length > 0) {
      cb(null, result.rows[0]);
    } else {
      cb(null, false);
    }
  } catch (err) {
    console.error("❌ Deserialization Error:", err);
    cb(err);
  }
});

// 3. LOGIN STRATEGY
passport.use(
  "local",
  new LocalStrategy(
    { usernameField: "username", passwordField: "password" }, 
    async (username, password, cb) => { 
      try {
        const result = await db.query("SELECT * FROM users WHERE username = $1", [username]); 
        
        if (result.rows.length > 0) {
          const user = result.rows[0];
          const valid = await bcrypt.compare(password, user.password_hash);
          
          if (valid) {
            return cb(null, user); 
          } else {
            return cb(null, false, { message: "Incorrect password" });
          }
        } else {
          return cb(null, false, { message: "Username not registered" }); 
        }
      } catch (err) {
        return cb(err);
      }
    }
  )
);

export default passport;