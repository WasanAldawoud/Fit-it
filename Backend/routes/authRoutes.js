import express from 'express';
import { signUp, signIn } from '../controllers/authController.js';
import { saveUserPlan } from '../controllers/authPlan.js';
const router = express.Router();


router.post('/signup', signUp);

router.post('/signin', signIn);

router.post('/save-plan', saveUserPlan);


export default router;