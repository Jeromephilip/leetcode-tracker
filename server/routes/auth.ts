import express from 'express';
import { loginHandler, logoutHandler } from '../controllers/authController';

const router = express.Router();

router.post('/login', loginHandler);
router.post('/logout', logoutHandler);

export default router;
