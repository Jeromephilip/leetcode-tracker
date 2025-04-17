import express from 'express';
import { userHandler, dueReviewHandler } from '../controllers/leetcodeController';
import { jwtMiddleware } from '../middleware/jwtAuth';

const router = express.Router();

router.get('/user/:username', userHandler);
router.get('/reviews/due', jwtMiddleware, dueReviewHandler);

export default router;
