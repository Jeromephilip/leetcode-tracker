import express from "express";
import {
  userHandler,
  dueReviewHandler,
} from "../controllers/review";
import { jwtMiddleware } from "../middleware/jwtAuth";
import { markReviewed } from "../controllers/review";

const router = express.Router();

router.get("/user/:username", userHandler);
router.get("/reviews/due", jwtMiddleware, dueReviewHandler);
router.patch("/review/:id", jwtMiddleware, markReviewed);

export default router;
