import { sequelize } from '../db/sequelize';
import { User } from '../models/User';
import bcrypt from 'bcrypt';

const reset = async () => {
  try {
    await sequelize.authenticate();

    console.log('Dropping all tables...');
    await sequelize.drop();

    console.log('Recreating tables...');
    await sequelize.sync();

    console.log('Seeding data...');
    const hashedPassword = await bcrypt.hash('test123', 10);

    await User.create({
      username: 'jerodahero',
      password: hashedPassword,
    });

    console.log('DB reset and seeded with jerodahero (password: test123)');
    process.exit(0);
  } catch (err) {
    console.error('Failed to reset DB:', err);
    process.exit(1);
  }
};

reset();
