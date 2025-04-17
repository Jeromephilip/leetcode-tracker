import express from 'express';
import { loginHandler, logoutHandler } from '../controllers/auth';

const router = express.Router();

router.post('/login', loginHandler);
router.post('/logout', logoutHandler);

export default router;
