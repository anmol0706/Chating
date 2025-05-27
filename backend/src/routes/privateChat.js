const express = require('express');
const { body } = require('express-validator');
const {
  getOrCreatePrivateChat,
  getUserPrivateChats,
  getPrivateChatMessages,
  sendPrivateMessage,
  markPrivateChatAsRead,
  getPrivateChatDetails,
  deletePrivateChat
} = require('../controllers/privateChatController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const sendMessageValidation = [
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Message content is required')
    .isLength({ max: 1000 })
    .withMessage('Message cannot exceed 1000 characters'),
  
  body('messageType')
    .optional()
    .isIn(['text', 'image', 'file'])
    .withMessage('Invalid message type'),
  
  body('replyTo')
    .optional()
    .isMongoId()
    .withMessage('Invalid reply message ID format')
];

const markAsReadValidation = [
  body('messageId')
    .optional()
    .isMongoId()
    .withMessage('Invalid message ID format')
];

// All routes require authentication
router.use(authenticateToken);

// Private chat routes
router.get('/', getUserPrivateChats);
router.get('/with/:friendId', getOrCreatePrivateChat);
router.get('/:chatId', getPrivateChatDetails);
router.get('/:chatId/messages', getPrivateChatMessages);
router.post('/:chatId/messages', sendMessageValidation, sendPrivateMessage);
router.post('/:chatId/read', markAsReadValidation, markPrivateChatAsRead);
router.delete('/:chatId', deletePrivateChat);

module.exports = router;
