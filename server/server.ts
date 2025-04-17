import express, { Request, Response, NextFunction } from 'express';
import authRoutes from './routes/auth';
import reviewRoutes from './routes/review';

const server = express();
const cookieParser = require('cookie-parser');
const cors = require('cors');

server.use(cors({ credentials: true, origin: 'http://localhost:5173' }));
server.use(cookieParser());
server.use(express.json());

server.use('/api', authRoutes);
server.use('/api', reviewRoutes);

server.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong', details: err.message });
});

export default server;
