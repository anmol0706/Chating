const express = require('express');
const { body } = require('express-validator');
const {
  createChatRoom,
  getUserChatRooms,
  joinChatRoom,
  leaveChatRoom,
  getChatRoomMessages,
  getPublicChatRooms
} = require('../controllers/chatController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createChatRoomValidation = [
  body('name')
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Chat room name must be between 1 and 50 characters'),
  
  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Description cannot exceed 200 characters'),
  
  body('type')
    .optional()
    .isIn(['public', 'private'])
    .withMessage('Type must be either public or private')
];

// All routes require authentication
router.use(authenticateToken);

// Routes
router.post('/rooms', createChatRoomValidation, createChatRoom);
router.get('/rooms', getUserChatRooms);
router.get('/rooms/public', getPublicChatRooms);
router.post('/rooms/:roomId/join', joinChatRoom);
router.post('/rooms/:roomId/leave', leaveChatRoom);
router.get('/rooms/:roomId/messages', getChatRoomMessages);

module.exports = router;
