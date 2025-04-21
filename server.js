const express = require('express');
const mongoose = require('mongoose');
const Redis = require('ioredis');
const axios = require('axios');
const cors = require('cors');
const promClient = require('prom-client');
const morgan = require('morgan');
const helmet = require('helmet');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Environment variables
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/microservices';
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;
const PYTHON_SERVICE_URL = process.env.PYTHON_SERVICE_URL || 'http://localhost:5000';
const NODE_ENV = process.env.NODE_ENV || 'development';

// Prometheus metrics
const collectDefaultMetrics = promClient.collectDefaultMetrics;
const Registry = promClient.Registry;
const register = new Registry();
collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
});
register.registerMetric(httpRequestDurationMicroseconds);

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan(NODE_ENV === 'development' ? 'dev' : 'combined'));

// Middleware to measure request duration
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequestDurationMicroseconds
      .labels(req.method, req.route ? req.route.path : req.path, res.statusCode)
      .observe(duration);
  });
  next();
});

// Database connections
const connectMongo = async () => {
  try {
    await mongoose.connect(MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// Redis client
const redisClient = new Redis({
  host: REDIS_HOST,
  port: REDIS_PORT,
  maxRetriesPerRequest: 3
});

redisClient.on('connect', () => console.log('Redis connected successfully'));
redisClient.on('error', (err) => console.error('Redis connection error:', err));

// Simple user schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Node.js Microservice API!' });
});

app.get('/health', async (req, res) => {
  try {
    // Check MongoDB connection
    const mongoStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
    
    // Check Redis connection
    let redisStatus;
    try {
      await redisClient.ping();
      redisStatus = 'connected';
    } catch (error) {
      redisStatus = 'disconnected';
    }
    
    // Check Python service connection
    let pythonServiceStatus;
    try {
      const response = await axios.get(`${PYTHON_SERVICE_URL}/health`, { timeout: 3000 });
      pythonServiceStatus = response.data.status === 'healthy' ? 'connected' : 'degraded';
    } catch (error) {
      pythonServiceStatus = 'disconnected';
    }
    
    const allHealthy = mongoStatus === 'connected' && 
                       redisStatus === 'connected' && 
                       pythonServiceStatus === 'connected';
    
    res.status(allHealthy ? 200 : 503).json({
      status: allHealthy ? 'healthy' : 'degraded',
      services: {
        mongo: mongoStatus,
        redis: redisStatus,
        pythonService: pythonServiceStatus
      }
    });
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({ status: 'error', message: 'Health check failed' });
  }
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// User API routes
app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' });
    }
    
    const user = new User({ name, email });
    await user.save();
    
    // Invalidate cache
    await redisClient.del('users');
    
    res.status(201).json({ message: 'User created successfully', userId: user._id });
  } catch (error) {
    if (error.code === 11000) { // Duplicate key error
      return res.status(409).json({ error: 'User with this email already exists' });
    }
    console.error('Create user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/users', async (req, res) => {
  try {
    // Try to get from cache
    const cachedUsers = await redisClient.get('users');
    if (cachedUsers) {
      console.log('Users retrieved from cache');
      return res.json(JSON.parse(cachedUsers));
    }
    
    // Get from DB
    const users = await User.find({}, { __v: 0 });
    
    // Store in cache for 60 seconds
    await redisClient.setex('users', 60, JSON.stringify(users));
    console.log('Users retrieved from MongoDB and stored in cache');
    
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Call Python service for data processing
app.post('/api/process-with-python', async (req, res) => {
  try {
    const { values } = req.body;
    if (!values || !Array.isArray(values)) {
      return res.status(400).json({ error: 'Values array is required' });
    }
    
    // Forward to Python service
    const response = await axios.post(`${PYTHON_SERVICE_URL}/api/process`, { values });
    
    // Add some Node.js specific processing
    const result = response.data;
    result.processed_by = 'node';
    result.even_values = values.filter(val => val % 2 === 0);
    result.odd_values = values.filter(val => val % 2 !== 0);
    
    res.json(result);
  } catch (error) {
    console.error('Process with Python error:', error);
    if (error.response) {
      // Python service returned an error
      return res.status(error.response.status).json({ error: error.response.data });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((req, res, next) => {
  res.status(404).json({ error: 'Route not found' });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const startServer = async () => {
  try {
    await connectMongo();
    app.listen(PORT, () => {
      console.log(`Node.js service running on port ${PORT} in ${NODE_ENV} mode`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();
