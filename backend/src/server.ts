import { app } from './app';
import { config } from './config';

const server = app.listen(config.port, () => {
  console.log(`🌾 Govipala backend API running on port ${config.port} (${config.nodeEnv})`);
  console.log(`📍 Base URL: http://localhost:${config.port}/api/v1`);
});

export default server;
