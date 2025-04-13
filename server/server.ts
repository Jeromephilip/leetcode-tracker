import express from 'express';
import { LeetCode } from 'leetcode-query';

const app = express();
const PORT = 4000;
var cors = require('cors')

app.use(cors());

app.get('/api/user/:username', async (req, res) => {
  const { username } = req.params;
  try {
    const leetcode = new LeetCode();
    const user = await leetcode.user(username);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch user' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});