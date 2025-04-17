import { Request, Response, RequestHandler } from "express";
import { LeetCode, Credential } from "leetcode-query";
import { ReviewTask } from "../models/ReviewTask";
import fetch from "node-fetch";

type Submission = {
  problemId: string;
  solvedAt: string;
};

export const userHandler: RequestHandler = async (
  req: Request,
  res: Response
) => {
  const { username } = req.params;
  try {
    const leetcode = new LeetCode();
    const user = await leetcode.user(username);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: "Could not fetch user" });
  }
};

export const dueReviewHandler: RequestHandler = async (req, res) => {
  try {
    const sessionCookie = process.env.LEETCODE_SESSION;
    if (!sessionCookie) throw new Error("Missing LEETCODE_SESSION");

    const credential = new Credential();
    await credential.init(sessionCookie);
    const leetcode = new LeetCode(credential);
    console.log("Authenticated user:", req.auth);
    const { username } = req.auth!;

    const submissions = await leetcode.submissions({ limit: 100, offset: 0 });

    const now = Date.now();
    const thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;

    const filtered = submissions.filter(
      (s: any) => s.timestamp >= thirtyDaysAgo && s.statusDisplay === "Accepted"
    );
    // converts submission for lambda transformation into valid tasks following E. rule
    const convertedSubmissions: Submission[] = filtered.map((s: any) => ({
      problemId: s.title,
      solvedAt: new Date(Number(s.timestamp)).toISOString(),
    }));

    /* 
      This lambda returns the past 30 days of filtered data. The filtered data is based on
      E. rule, and returns solely based on timestamp intervals.
    */
    const lambdaResponse = await fetch(
      process.env.HANDLE_SUBMISSION_LAMBDA_URL!,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ submissions: convertedSubmissions }),
      }
    );

    const data: Submission[] = await lambdaResponse.json();

    console.log(username);
    console.log(data);

    /* 
      Using the previously used E. Rule tasks, we filter it again based on whether
      the user has reviewed them within our dashboard.
    */
    const tasks = await filterReviewedTasks(username, data);

    res.status(lambdaResponse.status).json(tasks);
  } catch (err) {
    console.error("Handler error:", err);
    res
      .status(500)
      .json({
        error: "Failed to process due reviews",
        details: (err as Error).message,
      });
  }
};

export const markReviewed: RequestHandler = async (req, res) => {
  const { id } = req.params;
  const { username } = req.auth!;

  try {
    const task = await ReviewTask.findOne({
      where: { id, userId: username },
    });

    if (!task) {
      res.status(404).json({ error: 'Task not found' });
      return;
    }

    task.reviewed = true;
    await task.save();

    res.json({ success: true });
  } catch (err) {
    console.error('Failed to mark task reviewed:', err);
    res.status(500).json({ error: 'Server error' });
  }
};


const filterReviewedTasks = async (username: string, data: Submission[]) => {
  const tasks = await ReviewTask.findAll({
    where: {
      userId: username,
      reviewed: false,
    },
  });

  return tasks;
};
