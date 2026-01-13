import express from 'express';
// Imports the Express framework.
// We use its 'Router' class to organize our URLs into a separate file.

import { signUp, signIn, getProfile, googleCallback, updateProfile } from '../controllers/authController.js';
// Imports the logic functions from your Auth Controller.
// These functions handle account creation, login, and profile management.

import { saveUserPlan } from '../controllers/authPlan.js';
// Imports the specific function designed to save workout plans.
// Keeping this in a separate file helps keep your code organized as the app grows.

import passport from 'passport';
// Imports Passport.js to handle the heavy lifting for Google authentication.
// It manages the communication between your server and Google's login servers.

const router = express.Router();
// Initializes a new Router instance.
// This allows you to group these routes under a prefix (like '/auth') in your main server file.

// ==========================================
// STANDARD AUTHENTICATION ROUTES
// ==========================================

router.post('/signup', signUp);
// Listens for POST requests to your-api.com/signup.
// It passes the user's registration data (email, password, etc.) to the 'signUp' function.

router.post('/signin', signIn);
// Listens for POST requests to your-api.com/signin.
// Used when the user types their credentials into the Flutter login screen.

router.post('/save-plan', saveUserPlan);
// Listens for POST requests to your-api.com/save-plan.
// This is the endpoint Flutter calls when the user finishes creating their workout schedule.

router.get('/profile', getProfile);
// Listens for GET requests to your-api.com/profile.
// Used by the Flutter app to fetch the logged-in user's data (name, weight, height) to show on the UI.

router.put('/profile', updateProfile);
// Listens for PUT requests to your-api.com/profile.
// 'PUT' is the standard HTTP method for updating existing data in a database.

// ==========================================
// GOOGLE OAUTH ROUTES
// ==========================================

// Step 1: Redirect to Google
router.get('/google', passport.authenticate('google', {
    scope: ['profile', 'email']
  }));
  // This is the URL your Flutter app opens in a browser or webview to start Google Login.
  // 'passport.authenticate' sends the user to Google's actual login page.
  // 'scope' tells Google exactly what data we want permission to see (their name and email).

// Step 2: Google sends user back here
router.get('/google/callback', 
    passport.authenticate('google', { failureRedirect: '/auth/signin' }),
    googleCallback
  );
  // After the user logs in on Google's site, Google sends them back to this specific URL.
  // If the login fails (e.g., the user cancels), they are redirected back to the sign-in page.
  // If it succeeds, the 'googleCallback' function runs to send the user back to your Flutter app.

export default router;
// Exports the router so it can be imported in your main 'index.js' or 'app.js' file.
// Usually, you would use it there like this: app.use('/auth', authRoutes);