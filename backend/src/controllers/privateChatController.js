const { validationResult } = require('express-validator');
const PrivateChat = require('../models/PrivateChat');
const Message = require('../models/Message');
const User = require('../models/User');
const FriendRequest = require('../models/FriendRequest');

// Get or create private chat with a friend
const getOrCreatePrivateChat = async (req, res) => {
  try {
    const { friendId } = req.params;
    const userId = req.user._id;

    // Check if users are friends
    const areFriends = await FriendRequest.areFriends(userId, friendId);
    if (!areFriends) {
      return res.status(403).json({
        error: 'Can only create private chats with friends'
      });
    }

    // Get or create private chat
    const privateChat = await PrivateChat.findOrCreate(userId, friendId);

    res.status(200).json({
      privateChat
    });

  } catch (error) {
    console.error('Get or create private chat error:', error);
    res.status(500).json({
      error: 'Failed to get or create private chat',
      message: 'Internal server error'
    });
  }
};

// Get user's private chats
const getUserPrivateChats = async (req, res) => {
  try {
    const userId = req.user._id;
    const { page = 1, limit = 20 } = req.query;

    const privateChats = await PrivateChat.getUserChats(
      userId,
      parseInt(page),
      parseInt(limit)
    );

    // Add unread count for each chat
    const chatsWithUnreadCount = await Promise.all(
      privateChats.map(async (chat) => {
        const unreadCount = await chat.getUnreadCount(userId);
        const otherParticipant = chat.getOtherParticipant(userId);
        
        return {
          ...chat.toObject(),
          unreadCount,
          otherParticipant: chat.participants.find(
            p => p._id.toString() === otherParticipant.toString()
          )
        };
      })
    );

    const total = await PrivateChat.countDocuments({
      participants: userId,
      isActive: true
    });

    res.status(200).json({
      privateChats: chatsWithUnreadCount,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get user private chats error:', error);
    res.status(500).json({
      error: 'Failed to get private chats',
      message: 'Internal server error'
    });
  }
};

// Get private chat messages
const getPrivateChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;
    const { page = 1, limit = 50 } = req.query;

    // Check if user is participant in this chat
    const privateChat = await PrivateChat.findById(chatId);
    if (!privateChat) {
      return res.status(404).json({
        error: 'Private chat not found'
      });
    }

    if (!privateChat.participants.includes(userId)) {
      return res.status(403).json({
        error: 'Not authorized to access this private chat'
      });
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const messages = await Message.find({ privateChat: chatId })
      .populate('sender', 'username email profilePicture isOnline')
      .populate('replyTo')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Message.countDocuments({ privateChat: chatId });

    // Mark messages as read
    if (messages.length > 0) {
      await privateChat.markAsRead(userId, messages[0]._id);
    }

    res.status(200).json({
      messages: messages.reverse(), // Reverse to show oldest first
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get private chat messages error:', error);
    res.status(500).json({
      error: 'Failed to get private chat messages',
      message: 'Internal server error'
    });
  }
};

// Send message in private chat
const sendPrivateMessage = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { chatId } = req.params;
    const { content, messageType = 'text', replyTo } = req.body;
    const userId = req.user._id;

    // Check if user is participant in this chat
    const privateChat = await PrivateChat.findById(chatId);
    if (!privateChat) {
      return res.status(404).json({
        error: 'Private chat not found'
      });
    }

    if (!privateChat.participants.includes(userId)) {
      return res.status(403).json({
        error: 'Not authorized to send messages in this private chat'
      });
    }

    // Create message
    const message = new Message({
      content,
      sender: userId,
      privateChat: chatId,
      messageType,
      replyTo: replyTo || null
    });

    await message.save();

    // Update private chat's last message and activity
    privateChat.lastMessage = message._id;
    privateChat.lastActivity = new Date();
    await privateChat.save();

    // Populate message for response
    await message.populate('sender', 'username email profilePicture isOnline');
    if (replyTo) {
      await message.populate('replyTo');
    }

    res.status(201).json({
      message: 'Message sent successfully',
      messageData: message
    });

  } catch (error) {
    console.error('Send private message error:', error);
    res.status(500).json({
      error: 'Failed to send message',
      message: 'Internal server error'
    });
  }
};

// Mark private chat as read
const markPrivateChatAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;
    const { messageId } = req.body;

    // Check if user is participant in this chat
    const privateChat = await PrivateChat.findById(chatId);
    if (!privateChat) {
      return res.status(404).json({
        error: 'Private chat not found'
      });
    }

    if (!privateChat.participants.includes(userId)) {
      return res.status(403).json({
        error: 'Not authorized to access this private chat'
      });
    }

    // Mark as read
    await privateChat.markAsRead(userId, messageId);

    res.status(200).json({
      message: 'Private chat marked as read'
    });

  } catch (error) {
    console.error('Mark private chat as read error:', error);
    res.status(500).json({
      error: 'Failed to mark private chat as read',
      message: 'Internal server error'
    });
  }
};

// Get private chat details
const getPrivateChatDetails = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;

    const privateChat = await PrivateChat.findById(chatId)
      .populate('participants', 'username email profilePicture isOnline lastSeen')
      .populate('lastMessage');

    if (!privateChat) {
      return res.status(404).json({
        error: 'Private chat not found'
      });
    }

    if (!privateChat.participants.some(p => p._id.toString() === userId.toString())) {
      return res.status(403).json({
        error: 'Not authorized to access this private chat'
      });
    }

    // Get unread count
    const unreadCount = await privateChat.getUnreadCount(userId);
    const otherParticipant = privateChat.getOtherParticipant(userId);

    res.status(200).json({
      privateChat: {
        ...privateChat.toObject(),
        unreadCount,
        otherParticipant: privateChat.participants.find(
          p => p._id.toString() === otherParticipant.toString()
        )
      }
    });

  } catch (error) {
    console.error('Get private chat details error:', error);
    res.status(500).json({
      error: 'Failed to get private chat details',
      message: 'Internal server error'
    });
  }
};

// Delete private chat (deactivate)
const deletePrivateChat = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;

    const privateChat = await PrivateChat.findById(chatId);
    if (!privateChat) {
      return res.status(404).json({
        error: 'Private chat not found'
      });
    }

    if (!privateChat.participants.includes(userId)) {
      return res.status(403).json({
        error: 'Not authorized to delete this private chat'
      });
    }

    // Deactivate the chat instead of deleting
    privateChat.isActive = false;
    await privateChat.save();

    res.status(200).json({
      message: 'Private chat deleted successfully'
    });

  } catch (error) {
    console.error('Delete private chat error:', error);
    res.status(500).json({
      error: 'Failed to delete private chat',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  getOrCreatePrivateChat,
  getUserPrivateChats,
  getPrivateChatMessages,
  sendPrivateMessage,
  markPrivateChatAsRead,
  getPrivateChatDetails,
  deletePrivateChat
};
