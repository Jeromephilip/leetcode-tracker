import server from './server';
import { sequelize } from './db/sequelize';

const PORT = 4000;

const startServer = async () => {
  await sequelize.authenticate();
  await sequelize.sync();

  console.log('DB connected and models synced');

  server.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
  });
};

startServer();
