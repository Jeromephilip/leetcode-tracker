import { RequestHandler } from "express";
import { expressjwt } from "express-jwt";

const SECRET = process.env.JWT_SECRET || "supersecret";

export const jwtMiddleware: RequestHandler =
  process.env.NODE_ENV === 'test'
    ? (req, _res, next) => {
        req.auth = { username: 'jerodahero' }; // ✅ match your controller's usage
        next();
      }
    : expressjwt({
        secret: SECRET,
        algorithms: ['HS256'],
        getToken: (req) => {
          const authHeader = req.headers.authorization;
          if (authHeader?.startsWith('Bearer ')) {
            return authHeader.split(' ')[1];
          }
          return req.cookies?.token;
        },
      });
