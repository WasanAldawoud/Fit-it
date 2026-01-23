import express from 'express';
import { 
    signUp, 
    signIn, 
    getProfile, 
    googleCallback, 
    updateProfile, 
    logout 
} from '../controllers/authController.js';

import { 
    saveUserPlan, 
    getAllUserPlans, 
    markExerciseComplete, 
    renamePlan,
    deletePlan,             // <--- NEW
    updatePlanExercises     // <--- NEW
} from '../controllers/authPlan.js';

import passport from 'passport';

const router = express.Router();

// ==========================================
// STANDARD AUTHENTICATION ROUTES
// ==========================================
router.post('/signup', signUp);
router.post('/signin', signIn);
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.get('/logout', logout);

// ==========================================
// WORKOUT PLAN MANAGEMENT ROUTES
// ==========================================

// Create a new plan
router.post('/save-plan', saveUserPlan);

// Fetch all plans for the logged-in user
router.get("/get-plan", getAllUserPlans);

// Rename an existing plan
router.post('/rename-plan', renamePlan);

// Update exercises inside a plan (used by PlanDetailScreen)
router.post('/update-plan-exercises', updatePlanExercises); // <--- NEW
// Middleware to check if the user is logged in via Passport session
const authenticateToken = (req, res, next) => {
    if (req.isAuthenticated()) {
        return next();
    }
    res.status(401).json({ error: "Unauthorized. Please log in." });
};

// Delete a plan using its ID as a URL parameter
router.delete('/delete-plan/:planId', authenticateToken, deletePlan); // <--- NEW

// Progress Tracking
router.post("/mark-exercise-complete", markExerciseComplete);

// ==========================================
// GOOGLE OAUTH ROUTES
// ==========================================
router.get('/google', passport.authenticate('google', {
    scope: ['profile', 'email']
}));

router.get('/google/callback', 
    passport.authenticate('google', { failureRedirect: '/auth/signin' }),
    googleCallback
);

export default router;
