import { sequelize } from '../db/sequelize';
import '../models/User';
import '../models/ReviewTask';

const reset = async () => {
  try {
    await sequelize.authenticate();

    console.log('Dropping all tables...');
    await sequelize.drop();

    console.log('Recreating tables...');
    await sequelize.sync({ alter: true });

    console.log('Tables reset complete. Current tables:', Object.keys(sequelize.models));
    process.exit(0);
  } catch (err) {
    console.error('Failed to reset DB:', err);
    process.exit(1);
  }
};

reset();
