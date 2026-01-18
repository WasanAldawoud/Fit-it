import express from "express";
import { generateFitnessChat, approvePlan } from "./aiController.js";

const router = express.Router();

router.post("/fitness-chat", generateFitnessChat);
router.post("/approve-plan", approvePlan);

export default router;
