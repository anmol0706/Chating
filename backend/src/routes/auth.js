const express = require('express');
const { body } = require('express-validator');
const { register, login, logout, getProfile } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const registerValidation = [
  body('username')
    .trim()
    .isLength({ min: 3, max: 30 })
    .withMessage('Username must be between 3 and 30 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// Routes
router.post('/register', registerValidation, register);
router.post('/login', loginValidation, login);
router.post('/logout', authenticateToken, logout);
router.get('/profile', authenticateToken, getProfile);

// Verify token endpoint
router.get('/verify', authenticateToken, (req, res) => {
  res.status(200).json({
    valid: true,
    user: {
      id: req.user._id,
      username: req.user.username,
      email: req.user.email,
      isOnline: req.user.isOnline
    }
  });
});

module.exports = router;
