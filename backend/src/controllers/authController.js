const User = require('../models/User');
const { generateToken } = require('../middleware/auth');
const { validationResult } = require('express-validator');

// Register new user
const register = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { username, email, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { username }]
    });

    if (existingUser) {
      return res.status(409).json({
        error: 'User already exists',
        message: existingUser.email === email 
          ? 'Email is already registered' 
          : 'Username is already taken'
      });
    }

    // Create new user (password stored as plain text as per user preference)
    const user = new User({
      username,
      email,
      password // Plain text storage as requested
    });

    await user.save();

    // Generate token
    const token = generateToken(user._id);

    // Return user data without password
    const userResponse = {
      id: user._id,
      username: user.username,
      email: user.email,
      profilePicture: user.profilePicture,
      isOnline: user.isOnline,
      createdAt: user.createdAt
    };

    res.status(201).json({
      message: 'User registered successfully',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Registration failed',
      message: 'Internal server error during registration'
    });
  }
};

// Login user
const login = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Email not found'
      });
    }

    // Check password (plain text comparison as per user preference)
    if (user.password !== password) {
      return res.status(401).json({
        error: 'Invalid credentials',
        message: 'Incorrect password'
      });
    }

    // Update user online status
    await user.setOnlineStatus(true);

    // Generate token
    const token = generateToken(user._id);

    // Return user data without password
    const userResponse = {
      id: user._id,
      username: user.username,
      email: user.email,
      profilePicture: user.profilePicture,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen
    };

    res.status(200).json({
      message: 'Login successful',
      user: userResponse,
      token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed',
      message: 'Internal server error during login'
    });
  }
};

// Logout user
const logout = async (req, res) => {
  try {
    const userId = req.user._id;

    // Update user offline status
    await User.findByIdAndUpdate(userId, {
      isOnline: false,
      lastSeen: new Date(),
      socketId: null
    });

    res.status(200).json({
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      error: 'Logout failed',
      message: 'Internal server error during logout'
    });
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  try {
    const user = req.user;

    const userResponse = {
      id: user._id,
      username: user.username,
      email: user.email,
      profilePicture: user.profilePicture,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      joinedRooms: user.joinedRooms,
      createdAt: user.createdAt
    };

    res.status(200).json({
      user: userResponse
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Failed to get profile',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  register,
  login,
  logout,
  getProfile
};
