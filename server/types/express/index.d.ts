import * as express from 'express';

declare module 'express-serve-static-core' {
  interface Request {
    auth?: {
      username: string;
      [key: string]: any;
    };
  }
}
