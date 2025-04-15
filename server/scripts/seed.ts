import { sequelize } from '../db/sequelize';
import { User } from '../models/User';
import bcrypt from 'bcrypt';

const seed = async () => {
  try {
    await sequelize.authenticate();
    await sequelize.sync();

    const hashedPassword = await bcrypt.hash('test123', 10);

    const [user, created] = await User.findOrCreate({
      where: { username: 'jerodahero' },
      defaults: { password: hashedPassword },
    });

    if (created) {
      console.log('Seeded user: jerodahero');
    } else {
      console.log('User already exists: jerodahero');
    }

    await sequelize.close();
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
};

seed();