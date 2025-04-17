import { expressjwt } from 'express-jwt';

const SECRET = process.env.JWT_SECRET || 'supersecret';

export const jwtMiddleware = expressjwt({
  secret: SECRET,
  algorithms: ['HS256'],
  getToken: (req) => req.cookies.token,
});
