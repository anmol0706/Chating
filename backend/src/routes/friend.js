const express = require('express');
const { body } = require('express-validator');
const {
  sendFriendRequest,
  getReceivedFriendRequests,
  getSentFriendRequests,
  acceptFriendRequest,
  declineFriendRequest,
  cancelFriendRequest,
  getFriendsList,
  removeFriend
} = require('../controllers/friendController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const sendFriendRequestValidation = [
  body('receiverId')
    .notEmpty()
    .withMessage('Receiver ID is required')
    .isMongoId()
    .withMessage('Invalid receiver ID format'),
  
  body('message')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Message cannot exceed 200 characters')
];

// All routes require authentication
router.use(authenticateToken);

// Friend request routes
router.post('/request', sendFriendRequestValidation, sendFriendRequest);
router.get('/requests/received', getReceivedFriendRequests);
router.get('/requests/sent', getSentFriendRequests);
router.post('/requests/:requestId/accept', acceptFriendRequest);
router.post('/requests/:requestId/decline', declineFriendRequest);
router.post('/requests/:requestId/cancel', cancelFriendRequest);

// Friends management routes
router.get('/list', getFriendsList);
router.delete('/:friendId', removeFriend);

module.exports = router;
