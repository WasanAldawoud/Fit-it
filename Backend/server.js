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
import aiRoutes from './Ai/aiRoutes.js';

// Load secret keys from .env file
dotenv.config();

const app = express();
const PgSession = pgSimple(session);

// --- 1. Middleware (The Doormen) ---
// CORS: Lets your Flutter app talk to this server even though they are on different ports.
app.use(cors({
  origin: [
    'http://localhost:5000', // Flutter Web
    'http://localhost:3000', 
    'http://10.0.2.2:3000',  // Android Emulator
    'http://26.35.223.225:3000' // Your Physical Device IP
  ], // Allow all origins for testing
  credentials: true,               // 🔹 Allows cookies to be stored
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
// Body Parsers: These allow the server to read the JSON data sent inside req.body.
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- 2. Session Setup (The Memory) ---
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
    httpOnly: true,
    secure: false,     // 🔹 MUST be false for http://localhost
    sameSite: 'lax'    // 🔹 OK for same-site localhost (different ports)
   
  }
}));

// --- 3. Passport Init (The ID Check) ---
app.use(passport.initialize());
app.use(passport.session());
// Change this block in your server.js
app.get('/auth/profile', (req, res, next) => {
  if (!req.user) {
    // Return 200 with a clear 'authenticated: false' flag 
    // instead of 401 to prevent console "errors"
    return res.status(200).json({ authenticated: false }); 
  }
  next();
});

// --- 4. Routes (The Hallway) ---
app.use('/auth', authRoutes);
app.use('/ai', aiRoutes);

// --- 5. Start (The Switch) ---
const PORT = process.env.PORT || 3000;
app.listen(PORT,'0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});



