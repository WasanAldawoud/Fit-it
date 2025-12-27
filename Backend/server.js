//Sets up express-session and passport.session(). This is the infrastructure that starts the session.
import express from 'express';
import session from 'express-session';
import pgSimple from 'connect-pg-simple';
import cors from 'cors';
import passport from 'passport';
import dotenv from 'dotenv';

// Import your Database connection
import db from './config/db.js';

// Import Passport Logic. 
// ⚠️ IMPORTANT: Importing this file makes the code inside it RUN immediately.
// This is how the server learns "How to log people in".
import './config/passport.js'; 

import authRoutes from './routes/authRoutes.js';

// Load secret keys from .env file
dotenv.config();

const app = express();
const PgSession = pgSimple(session);

// --- 1. Middleware (The Doormen) ---
// CORS: Lets your Flutter app talk to this server even though they are on different ports.
//Allows the server to accept requests from different origins (like Flutter app running on a different port/IP)
app.use(cors()); 

// Body Parsers: These allow the server to read the JSON data sent inside req.body.
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- 2. Session Setup (The Memory) ---
// This tells the server: "When a user logs in, save their info in the 'sessions' table".
app.use(session({
  store: new PgSession({
    pool: db,                // Use our DB connection
    tableName: 'sessions'    // Save to this specific SQL table
  }),
  secret: process.env.SESSION_SECRET, // Encrypts the cookie ID
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 30 * 24 * 60 * 60 * 1000 } // Cookie lasts 30 days
}));

// --- 3. Passport Init (The ID Check) ---
// These two lines must come AFTER the session setup.
app.use(passport.initialize());
app.use(passport.session()); // This checks the cookie on every request to see who the user is.

// --- 4. Routes (The Hallway) ---
// "If anyone asks for /auth/signup, send them to the authRoutes file."
//Tells Express that all routes defined in authRoutes.js (like /signup) should be accessed under the /auth prefix. The full path is now /auth/signup.
app.use('/auth', authRoutes);

// --- 5. Start (The Switch) ---
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});