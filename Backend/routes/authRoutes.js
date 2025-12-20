import express from 'express';
import { signUp, signIn } from '../controllers/authController.js';

const router = express.Router();

// It says: "When a POST request comes to /signup, run the signUp function."
router.post('/signup', signUp);

router.post('/signin', signIn);

export default router;