const { validationResult } = require('express-validator');
const FriendRequest = require('../models/FriendRequest');
const User = require('../models/User');
const PrivateChat = require('../models/PrivateChat');

// Send friend request
const sendFriendRequest = async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { receiverId, message } = req.body;
    const senderId = req.user._id;

    // Check if trying to send request to self
    if (senderId.toString() === receiverId) {
      return res.status(400).json({
        error: 'Cannot send friend request to yourself'
      });
    }

    // Check if receiver exists
    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    // Check if users are already friends
    const areFriends = await FriendRequest.areFriends(senderId, receiverId);
    if (areFriends) {
      return res.status(400).json({
        error: 'Users are already friends'
      });
    }

    // Check if friend request already exists
    const existingRequest = await FriendRequest.existsBetween(senderId, receiverId);
    if (existingRequest) {
      return res.status(400).json({
        error: 'Friend request already exists between these users'
      });
    }

    // Create friend request
    const friendRequest = new FriendRequest({
      sender: senderId,
      receiver: receiverId,
      message: message || ''
    });

    await friendRequest.save();

    // Update user's friend request arrays
    await User.findByIdAndUpdate(senderId, {
      $push: { friendRequestsSent: friendRequest._id }
    });

    await User.findByIdAndUpdate(receiverId, {
      $push: { friendRequestsReceived: friendRequest._id }
    });

    // Populate sender info for response
    await friendRequest.populate('sender', 'username email profilePicture isOnline');

    res.status(201).json({
      message: 'Friend request sent successfully',
      friendRequest
    });

  } catch (error) {
    console.error('Send friend request error:', error);
    res.status(500).json({
      error: 'Failed to send friend request',
      message: 'Internal server error'
    });
  }
};

// Get received friend requests
const getReceivedFriendRequests = async (req, res) => {
  try {
    const userId = req.user._id;
    const { status = 'pending', page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const friendRequests = await FriendRequest.find({
      receiver: userId,
      status: status
    })
    .populate('sender', 'username email profilePicture isOnline lastSeen')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

    const total = await FriendRequest.countDocuments({
      receiver: userId,
      status: status
    });

    res.status(200).json({
      friendRequests,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get received friend requests error:', error);
    res.status(500).json({
      error: 'Failed to get friend requests',
      message: 'Internal server error'
    });
  }
};

// Get sent friend requests
const getSentFriendRequests = async (req, res) => {
  try {
    const userId = req.user._id;
    const { status = 'pending', page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const friendRequests = await FriendRequest.find({
      sender: userId,
      status: status
    })
    .populate('receiver', 'username email profilePicture isOnline lastSeen')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

    const total = await FriendRequest.countDocuments({
      sender: userId,
      status: status
    });

    res.status(200).json({
      friendRequests,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get sent friend requests error:', error);
    res.status(500).json({
      error: 'Failed to get friend requests',
      message: 'Internal server error'
    });
  }
};

// Accept friend request
const acceptFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.user._id;

    const friendRequest = await FriendRequest.findById(requestId)
      .populate('sender', 'username email profilePicture isOnline');

    if (!friendRequest) {
      return res.status(404).json({
        error: 'Friend request not found'
      });
    }

    // Check if user is the receiver
    if (friendRequest.receiver.toString() !== userId.toString()) {
      return res.status(403).json({
        error: 'Not authorized to accept this friend request'
      });
    }

    // Check if request is still pending
    if (friendRequest.status !== 'pending') {
      return res.status(400).json({
        error: 'Friend request is no longer pending'
      });
    }

    // Accept the friend request (this also updates the users' friends lists)
    await friendRequest.accept();

    // Create private chat between the two users
    const privateChat = await PrivateChat.findOrCreate(
      friendRequest.sender._id,
      friendRequest.receiver
    );

    res.status(200).json({
      message: 'Friend request accepted successfully',
      friendRequest,
      privateChat
    });

  } catch (error) {
    console.error('Accept friend request error:', error);
    res.status(500).json({
      error: 'Failed to accept friend request',
      message: 'Internal server error'
    });
  }
};

// Decline friend request
const declineFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.user._id;

    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
      return res.status(404).json({
        error: 'Friend request not found'
      });
    }

    // Check if user is the receiver
    if (friendRequest.receiver.toString() !== userId.toString()) {
      return res.status(403).json({
        error: 'Not authorized to decline this friend request'
      });
    }

    // Check if request is still pending
    if (friendRequest.status !== 'pending') {
      return res.status(400).json({
        error: 'Friend request is no longer pending'
      });
    }

    // Decline the friend request
    await friendRequest.decline();

    res.status(200).json({
      message: 'Friend request declined successfully',
      friendRequest
    });

  } catch (error) {
    console.error('Decline friend request error:', error);
    res.status(500).json({
      error: 'Failed to decline friend request',
      message: 'Internal server error'
    });
  }
};

// Cancel friend request
const cancelFriendRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const userId = req.user._id;

    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
      return res.status(404).json({
        error: 'Friend request not found'
      });
    }

    // Check if user is the sender
    if (friendRequest.sender.toString() !== userId.toString()) {
      return res.status(403).json({
        error: 'Not authorized to cancel this friend request'
      });
    }

    // Check if request is still pending
    if (friendRequest.status !== 'pending') {
      return res.status(400).json({
        error: 'Friend request is no longer pending'
      });
    }

    // Cancel the friend request
    await friendRequest.cancel();

    res.status(200).json({
      message: 'Friend request cancelled successfully',
      friendRequest
    });

  } catch (error) {
    console.error('Cancel friend request error:', error);
    res.status(500).json({
      error: 'Failed to cancel friend request',
      message: 'Internal server error'
    });
  }
};

// Get user's friends list
const getFriendsList = async (req, res) => {
  try {
    const userId = req.user._id;
    const { page = 1, limit = 50, search } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build query for friends
    let friendsQuery = { _id: { $in: req.user.friends } };
    
    if (search) {
      friendsQuery.$or = [
        { username: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const friends = await User.find(friendsQuery)
      .select('username email profilePicture isOnline lastSeen')
      .sort({ isOnline: -1, username: 1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(friendsQuery);

    res.status(200).json({
      friends,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Get friends list error:', error);
    res.status(500).json({
      error: 'Failed to get friends list',
      message: 'Internal server error'
    });
  }
};

// Remove friend
const removeFriend = async (req, res) => {
  try {
    const { friendId } = req.params;
    const userId = req.user._id;

    // Check if they are actually friends
    const areFriends = await FriendRequest.areFriends(userId, friendId);
    if (!areFriends) {
      return res.status(400).json({
        error: 'Users are not friends'
      });
    }

    // Remove from both users' friends lists
    await User.findByIdAndUpdate(userId, {
      $pull: { friends: friendId }
    });

    await User.findByIdAndUpdate(friendId, {
      $pull: { friends: userId }
    });

    // Optionally deactivate private chat
    await PrivateChat.findOneAndUpdate(
      {
        participants: { $all: [userId, friendId], $size: 2 },
        isActive: true
      },
      { isActive: false }
    );

    res.status(200).json({
      message: 'Friend removed successfully'
    });

  } catch (error) {
    console.error('Remove friend error:', error);
    res.status(500).json({
      error: 'Failed to remove friend',
      message: 'Internal server error'
    });
  }
};

module.exports = {
  sendFriendRequest,
  getReceivedFriendRequests,
  getSentFriendRequests,
  acceptFriendRequest,
  declineFriendRequest,
  cancelFriendRequest,
  getFriendsList,
  removeFriend
};
