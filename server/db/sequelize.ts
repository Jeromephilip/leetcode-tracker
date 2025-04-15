import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';

dotenv.config();

export const sequelize = new Sequelize(
  process.env.PGDATABASE || 'leetcode',
  process.env.PGUSER || 'admin',
  process.env.PGPASSWORD || 'secret',
  {
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT) || 5432,
    dialect: 'postgres',
    logging: false,
  }
);
