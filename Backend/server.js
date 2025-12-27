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
// 2. Configure it properly
app.use(cors({
  origin: function (origin, callback) {
    // This allows any origin that sends a request, which is perfect for dev
    if (!origin || origin.startsWith('http://localhost')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true, //Allows cookies to be sent from Flutter
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
// Body Parsers: These allow the server to read the JSON data sent inside req.body.
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- 2. Session Setup (The Memory) ---
// This tells the server: "When a user logs in, save their info in the 'sessions' table".
app.use(session({
  store: new PgSession({
    pool: db,
    tableName: process.env.SESSION_TABLE
  }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { 
    maxAge: 30 * 24 * 60 * 60 * 1000,
    httpOnly: true, // Recommended for security
    secure: false,  // MUST be false because you we are using http://localhost (not https)
    sameSite: 'lax' // Allows the cookie to be sent across different ports on localhost
  }
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
app.listen(PORT,'0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});