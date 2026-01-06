const express = require('express');
const client = require('prom-client');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/app.log' })
  ]
});

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.1, 0.5, 1, 2, 5],
  registers: [register]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'code'],
  registers: [register]
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register]
});

let connectionCount = 0;

app.use(express.json());

app.use((req, res, next) => {
  connectionCount++;
  activeConnections.set(connectionCount);
  
  logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequestDuration.observe(
      {
        method: req.method,
        route: req.path,
        code: res.statusCode
      },
      duration / 1000
    );
    
    httpRequestsTotal.inc({
      method: req.method,
      route: req.path,
      code: res.statusCode
    });
    
    connectionCount--;
    activeConnections.set(connectionCount);
    
    logger.info('Request completed', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: duration
    });
  });
  next();
});

app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Cloud Native Demo',
    version: VERSION,
    timestamp: new Date().toISOString(),
    hostname: require('os').hostname()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', version: VERSION });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/info', (req, res) => {
  res.json({
    version: VERSION,
    commit: process.env.GIT_COMMIT || 'unknown',
    buildTime: process.env.BUILD_TIME || 'unknown',
    environment: process.env.NODE_ENV || 'development'
  });
});

app.post('/webhook/alerts', (req, res) => {
  logger.warn('Alert received', { alerts: req.body });
  res.json({ status: 'received' });
});

app.get('/simulate/error', (req, res) => {
  const errorRate = parseFloat(req.query.rate) || 0.5;
  if (Math.random() < errorRate) {
    logger.error('Simulated error', { errorRate });
    res.status(500).json({ error: 'Simulated internal server error' });
  } else {
    res.json({ message: 'Request successful' });
  }
});

app.get('/simulate/slow', (req, res) => {
  const delay = parseInt(req.query.delay) || 2000;
  setTimeout(() => {
    res.json({ message: `Response delayed by ${delay}ms` });
  }, delay);
});

app.get('/simulate/crash', (req, res) => {
  logger.error('Simulating crash');
  process.exit(1);
});

app.get('/api/data', (req, res) => {
  const dataSize = parseInt(req.query.size) || 100;
  const data = {
    items: Array.from({ length: dataSize }, (_, i) => ({
      id: i + 1,
      name: `Item ${i + 1}`,
      value: Math.random() * 100
    })),
    timestamp: new Date().toISOString()
  };
  res.json(data);
});

app.get('/api/users', (req, res) => {
  const users = [
    { id: 1, name: 'Alice', email: 'alice@example.com' },
    { id: 2, name: 'Bob', email: 'bob@example.com' },
    { id: 3, name: 'Charlie', email: 'charlie@example.com' }
  ];
  res.json(users);
});

app.post('/api/users', (req, res) => {
  const user = req.body;
  logger.info('Creating user', { user });
  res.status(201).json({ ...user, id: Date.now() });
});

app.listen(PORT, () => {
  logger.info('Server started', {
    port: PORT,
    version: VERSION,
    commit: process.env.GIT_COMMIT || 'unknown',
    environment: process.env.NODE_ENV || 'development'
  });
});

module.exports = app;
