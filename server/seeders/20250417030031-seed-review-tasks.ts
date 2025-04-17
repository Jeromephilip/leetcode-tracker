import { QueryInterface } from "sequelize";

export async function up(queryInterface: QueryInterface): Promise<void> {
  await queryInterface.bulkInsert('review_tasks', [
    {
      username: 'jerodahero',
      problemId: 'Graph Valid Tree',
      reviewDate: '2025-04-10',
      reviewed: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      username: 'jerodahero',
      problemId: 'Number of Connected Components in an Undirected Graph',
      reviewDate: '2025-04-10',
      reviewed: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    {
      username: 'jerodahero',
      problemId: 'Number of Connected Components in an Undirected Graph',
      reviewDate: '2025-04-10',
      reviewed: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ]);
}

export async function down(queryInterface: QueryInterface): Promise<void> {
  await queryInterface.bulkDelete('review_tasks', {
    username: 'jerodahero',
  });
}

