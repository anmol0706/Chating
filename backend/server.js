const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const connectDB = require('./src/config/database');
const authRoutes = require('./src/routes/auth');
const chatRoutes = require('./src/routes/chat');
const userRoutes = require('./src/routes/user');
const friendRoutes = require('./src/routes/friend');
const privateChatRoutes = require('./src/routes/privateChat');
const socketHandler = require('./src/socket/socketHandler');

const app = express();
const server = http.createServer(app);
// CORS origins configuration
const corsOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',')
  : [
      "http://localhost:3000",
      "http://localhost:8080",
      "http://localhost:8081",
      "http://localhost:8082",
      "http://localhost:53086",  // Flutter web dev server
      "http://127.0.0.1:53086",  // Flutter web dev server alternative
      "http://localhost:*",      // Allow any localhost port
      "http://127.0.0.1:*"       // Allow any 127.0.0.1 port
    ];

const io = socketIo(server, {
  cors: {
    origin: function (origin, callback) {
      // Allow requests with no origin (like mobile apps)
      if (!origin) return callback(null, true);

      // Allow all localhost and 127.0.0.1 origins during development
      if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
        return callback(null, true);
      }

      // Check against configured origins
      if (corsOrigins.indexOf(origin) !== -1) {
        return callback(null, true);
      }

      return callback(null, false);
    },
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Connect to MongoDB
connectDB();

// Middleware
app.use(helmet());
app.use(morgan('combined'));
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);

    // Allow all localhost and 127.0.0.1 origins during development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }

    // Check against configured origins
    if (corsOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }

    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/user', userRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/private-chat', privateChatRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Chat App Backend is running',
    timestamp: new Date().toISOString()
  });
});

// Socket.io connection handling
socketHandler(io);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Socket.io server ready for connections`);
});

module.exports = { app, server, io };
