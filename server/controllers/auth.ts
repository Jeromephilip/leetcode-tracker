import { Request, Response, NextFunction } from 'express';
import { User } from '../models/User';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';

const SECRET = process.env.JWT_SECRET || 'supersecret';

export const loginHandler = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
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

export const logoutHandler = (
  req: Request,
  res: Response
): void => {
  res.clearCookie('token');
  res.json({ success: true });
};
