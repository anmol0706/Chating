const ChatRoom = require('../models/ChatRoom');
const Message = require('../models/Message');
const User = require('../models/User');
const { validationResult } = require('express-validator');

// Create a new chat room
const createChatRoom = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { name, description, type = 'public' } = req.body;
    const userId = req.user._id;

    // Create new chat room
    const chatRoom = new ChatRoom({
      name,
      description,
      type,
      createdBy: userId,
      participants: [{
        user: userId,
        role: 'admin',
        joinedAt: new Date()
      }]
    });

    await chatRoom.save();

    // Add room to user's joined rooms
    await User.findByIdAndUpdate(userId, {
      $addToSet: { joinedRooms: chatRoom._id }
    });

    // Populate the response
    await chatRoom.populate('participants.user', 'username profilePicture isOnline');
    await chatRoom.populate('createdBy', 'username profilePicture');

    res.status(201).json({
      message: 'Chat room created successfully',
      chatRoom
    });

  } catch (error) {
    console.error('Create chat room error:', error);
    res.status(500).json({
      error: 'Failed to create chat room',
      message: 'Internal server error'
    });
  }
};

// Get all chat rooms for a user
const getUserChatRooms = async (req, res) => {
  try {
    const userId = req.user._id;

    const chatRooms = await ChatRoom.find({
      'participants.user': userId
    })
    .populate('participants.user', 'username profilePicture isOnline')
    .populate('createdBy', 'username profilePicture')
    .populate('lastMessage', 'content sender createdAt')
    .sort({ lastActivity: -1 });

    res.status(200).json({
      chatRooms
    });

  } catch (error) {
    console.error('Get user chat rooms error:', error);
    res.status(500).json({
      error: 'Failed to get chat rooms',
      message: 'Internal server error'
    });
  }
};

// Join a chat room
const joinChatRoom = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id;

    const chatRoom = await ChatRoom.findById(roomId);

    if (!chatRoom) {
      return res.status(404).json({
        error: 'Chat room not found'
      });
    }

    // Check if user is already a participant
    if (chatRoom.isParticipant(userId)) {
      return res.status(400).json({
        error: 'Already a member of this chat room'
      });
    }

    // Add user to chat room
    await chatRoom.addParticipant(userId);

    // Add room to user's joined rooms
    await User.findByIdAndUpdate(userId, {
      $addToSet: { joinedRooms: roomId }
    });

    // Populate the response
    await chatRoom.populate('participants.user', 'username profilePicture isOnline');

    res.status(200).json({
      message: 'Successfully joined chat room',
      chatRoom
    });

  } catch (error) {
    console.error('Join chat room error:', error);
    res.status(500).json({
      error: 'Failed to join chat room',
      message: 'Internal server error'
    });
  }
};

// Leave a chat room
const leaveChatRoom = async (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user._id;

    const chatRoom = await ChatRoom.findById(roomId);

    if (!chatRoom) {
      return res.status(404).json({
        error: 'Chat room not found'
      });
    }

    // Check if user is a participant
    if (!chatRoom.isParticipant(userId)) {
      return res.status(400).json({
        error: 'Not a member of this chat room'
      });
    }

    // Remove user from chat room
    await chatRoom.removeParticipant(userId);

    // Remove room from user's joined rooms
    await User.findByIdAndUpdate(userId, {
      $pull: { joinedRooms: roomId }
    });

    res.status(200).json({
      message: 'Successfully left chat room'
    });

  } catch (error) {
    console.error('Leave chat room error:', error);
    res.status(500).json({
      error: 'Failed to leave chat room',
      message: 'Internal server error'
    });
  }
};

// Get messages for a chat room
const getChatRoomMessages = async (req, res) => {
  try {
    const { roomId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const userId = req.user._id;

    // Check if user is a participant of the chat room
    const chatRoom = await ChatRoom.findById(roomId);
    
    if (!chatRoom) {
      return res.status(404).json({
        error: 'Chat room not found'
      });
    }

    if (!chatRoom.isParticipant(userId)) {
      return res.status(403).json({
        error: 'Access denied',
        message: 'You are not a member of this chat room'
      });
    }

    const skip = (page - 1) * limit;
    const messages = await Message.getRecentMessages(roomId, parseInt(limit), skip);

    // Reverse to get chronological order (oldest first)
    messages.reverse();

    res.status(200).json({
      messages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        hasMore: messages.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Get chat room messages error:', error);
    res.status(500).json({
      error: 'Failed to get messages',
      message: 'Internal server error'
    });
  }
};

// Get public chat rooms
const getPublicChatRooms = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const chatRooms = await ChatRoom.find({ type: 'public' })
      .populate('createdBy', 'username profilePicture')
      .populate('lastMessage', 'content createdAt')
      .sort({ lastActivity: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    res.status(200).json({
      chatRooms,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        hasMore: chatRooms.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Get public chat rooms error:', error);
    res.status(500).json({
      error: 'Failed to get public chat rooms',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  createChatRoom,
  getUserChatRooms,
  joinChatRoom,
  leaveChatRoom,
  getChatRoomMessages,
  getPublicChatRooms
};
