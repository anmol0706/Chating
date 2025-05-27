const express = require('express');
const { body } = require('express-validator');
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');
const { validationResult } = require('express-validator');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get all users (for user list)
router.get('/', async (req, res) => {
  try {
    const { search, online } = req.query;
    let query = {};

    // Search by username or email
    if (search) {
      query.$or = [
        { username: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    // Filter by online status
    if (online !== undefined) {
      query.isOnline = online === 'true';
    }

    const users = await User.find(query)
      .select('username email profilePicture isOnline lastSeen')
      .sort({ isOnline: -1, lastSeen: -1 })
      .limit(50);

    res.status(200).json({
      users
    });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      error: 'Failed to get users',
      message: 'Internal server error'
    });
  }
});

// Get user by ID
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId)
      .select('username email profilePicture isOnline lastSeen createdAt');

    if (!user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    res.status(200).json({
      user
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      error: 'Failed to get user',
      message: 'Internal server error'
    });
  }
});

// Update user profile
router.put('/profile', [
  body('username')
    .optional()
    .trim()
    .isLength({ min: 3, max: 30 })
    .withMessage('Username must be between 3 and 30 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  
  body('profilePicture')
    .optional()
    .isURL()
    .withMessage('Profile picture must be a valid URL')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const userId = req.user._id;
    const { username, profilePicture } = req.body;

    const updateData = {};
    if (username) updateData.username = username;
    if (profilePicture !== undefined) updateData.profilePicture = profilePicture;

    // Check if username is already taken (if updating username)
    if (username) {
      const existingUser = await User.findOne({ 
        username, 
        _id: { $ne: userId } 
      });

      if (existingUser) {
        return res.status(409).json({
          error: 'Username already taken'
        });
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true, runValidators: true }
    ).select('-password');

    res.status(200).json({
      message: 'Profile updated successfully',
      user: updatedUser
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Failed to update profile',
      message: 'Internal server error'
    });
  }
});

// Change password
router.put('/password', [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('New password must be at least 6 characters long')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const userId = req.user._id;
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(userId);

    // Verify current password (plain text comparison)
    if (user.password !== currentPassword) {
      return res.status(401).json({
        error: 'Invalid current password'
      });
    }

    // Update password (plain text storage as per user preference)
    user.password = newPassword;
    await user.save();

    res.status(200).json({
      message: 'Password updated successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      error: 'Failed to change password',
      message: 'Internal server error'
    });
  }
});

module.exports = router;
