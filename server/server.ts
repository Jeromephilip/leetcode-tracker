import express from 'express';
import type { Request, Response } from 'express';
import fetch from 'node-fetch';
import type { RequestHandler } from 'express';
import { LeetCode, Credential } from 'leetcode-query';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = 4000;
var cors = require('cors');

app.use(cors());
app.use(express.json());

type Submission = {
  problemId: string;
  solvedAt: string;
};

type ReviewRequest = {
  submissions: Submission[];
};

app.get('/api/user/:username', async (req: Request, res: Response) => {
  const { username } = req.params;
  try {
    const leetcode = new LeetCode();
    const user = await leetcode.user(username);
    res.json(user);

  } catch (err) {
    res.status(500).json({ error: 'Could not fetch user' });
  }
});

const dueReviewHandler: RequestHandler = async (req, res) => {
  try {

    const sessionCookie = process.env.LEETCODE_SESSION;
    if (!sessionCookie) {
      console.log(sessionCookie)
      throw new Error('Missing LEETCODE_SESSION in environment variables');
    }

    const credential = new Credential();
    await credential.init(sessionCookie); // Load from .env

    const leetcode = new LeetCode(credential);
    const submissions = await leetcode.submissions({ limit: 100, offset: 0 });

    const now = Date.now();
    const thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;
    const filtered = submissions.filter((s: any) => {
      return s.timestamp >= thirtyDaysAgo && s.statusDisplay === 'Accepted';
    });

    console.log(submissions)

    const convertedSubmissions: Submission[] = filtered.map((s: any) => ({
      problemId: s.title,
      solvedAt: new Date(Number(s.timestamp)).toISOString(),
    }));

    const lambdaResponse = await fetch(
      process.env.HANDLE_SUBMISSION_LAMBDA_URL!,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ submissions: convertedSubmissions }),
      }
    );

    const data = await lambdaResponse.json();
    res.status(lambdaResponse.status).json(data);
  } catch (err) {
    console.error('Handler error:', err);
    res.status(500).json({ error: 'Failed to process due reviews', details: (err as Error).message });
  }
};

app.get('/api/reviews/due', dueReviewHandler);

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});