import { QueryInterface } from 'sequelize';
import bcrypt from 'bcrypt';

export async function up(queryInterface: QueryInterface): Promise<void> {
  const hashedPassword = await bcrypt.hash('test123', 10);

  await queryInterface.bulkInsert('users', [
    {
      username: 'jerodahero',
      password: hashedPassword,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ]);
}

export async function down(queryInterface: QueryInterface): Promise<void> {
  await queryInterface.bulkDelete('users', {
    username: 'jerodahero',
  });
}
