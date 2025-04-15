import express, { Request, Response, RequestHandler } from 'express';
import fetch from 'node-fetch';
import { LeetCode, Credential } from 'leetcode-query';
import { expressjwt } from 'express-jwt';
import dotenv from 'dotenv';
import jwt from 'jsonwebtoken';
import { sequelize } from './db/sequelize';
import { User } from './models/User';
import bcrypt from 'bcrypt';

dotenv.config();

const app = express();
const PORT = 4000;
const SECRET = process.env.JWT_SECRET || 'supersecret';

var cors = require('cors');
var cookieParser = require('cookie-parser')

app.use(cors({ credentials: true, origin: 'http://localhost:5173' }));
app.use(cookieParser());
app.use(express.json());

type Submission = {
  problemId: string;
  solvedAt: string;
};

const loginHandler: RequestHandler = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    const user = await User.findOne({ where: { username } });
    if (!user) {
      res.status(401).json({ error: 'Invalid username or password' });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.getDataValue('password'));
    if (!isMatch) {
      res.status(401).json({ error: 'Invalid username or password' });
      return;
    }

    const token = jwt.sign({ username }, SECRET, { expiresIn: '1h' });

    res.cookie('token', token, {
      httpOnly: true,
      sameSite: 'lax',
      secure: false,
      maxAge: 60 * 60 * 1000,
    });

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

const userHandler: RequestHandler = async (req: Request, res: Response) => {
  const { username } = req.params;
  try {
    const leetcode = new LeetCode();
    const user = await leetcode.user(username);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch user' });
  }
};

const dueReviewHandler: RequestHandler = async (req, res) => {
  try {
    const sessionCookie = process.env.LEETCODE_SESSION;
    if (!sessionCookie) throw new Error('Missing LEETCODE_SESSION');

    const credential = new Credential();
    await credential.init(sessionCookie);
    const leetcode = new LeetCode(credential);

    const submissions = await leetcode.submissions({ limit: 100, offset: 0 });

    const now = Date.now();
    const thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;

    const filtered = submissions.filter(
      (s: any) => s.timestamp >= thirtyDaysAgo && s.statusDisplay === 'Accepted'
    );

    const convertedSubmissions: Submission[] = filtered.map((s: any) => ({
      problemId: s.title,
      solvedAt: new Date(Number(s.timestamp)).toISOString(),
    }));

    const lambdaResponse = await fetch(process.env.HANDLE_SUBMISSION_LAMBDA_URL!, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ submissions: convertedSubmissions }),
    });

    const data = await lambdaResponse.json();
    res.status(lambdaResponse.status).json(data);
  } catch (err) {
    console.error('Handler error:', err);
    res.status(500).json({ error: 'Failed to process due reviews', details: (err as Error).message });
  }
};

app.use(
  '/api/reviews/due',
  expressjwt({
    secret: SECRET,
    algorithms: ['HS256'],
    getToken: (req) => req.cookies.token,
  })
);
app.get('/api/reviews/due', dueReviewHandler);

app.post('/api/login', loginHandler);
app.get('/api/user/:username', userHandler);


app.post('/api/logout', (req, res) => {
  res.clearCookie('token');
  res.json({ success: true });
});

const startServer = async () => {
  await sequelize.authenticate();
  await sequelize.sync();

  console.log('DB connected and models synced');

  app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
  });
};

startServer();
