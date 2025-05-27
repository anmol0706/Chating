const mongoose = require('mongoose');

const privateChatSchema = new mongoose.Schema({
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }],
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message'
  },
  lastActivity: {
    type: Date,
    default: Date.now
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Track read status for each participant
  readStatus: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    lastReadMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message'
    },
    lastReadAt: {
      type: Date,
      default: Date.now
    }
  }],
  // Metadata for the chat
  metadata: {
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    chatType: {
      type: String,
      default: 'private',
      immutable: true
    }
  }
}, {
  timestamps: true
});

// Index for faster queries
privateChatSchema.index({ participants: 1 });
privateChatSchema.index({ lastActivity: -1 });
privateChatSchema.index({ isActive: 1 });
privateChatSchema.index({ 'readStatus.user': 1 });

// Ensure exactly 2 participants for private chat
privateChatSchema.pre('save', function(next) {
  if (this.participants.length !== 2) {
    return next(new Error('Private chat must have exactly 2 participants'));
  }
  next();
});

// Ensure unique private chat between two users
privateChatSchema.index(
  { participants: 1 },
  { 
    unique: true,
    partialFilterExpression: { isActive: true }
  }
);

// Virtual for unread message count for a specific user
privateChatSchema.methods.getUnreadCount = async function(userId) {
  const Message = require('./Message');
  
  const userReadStatus = this.readStatus.find(
    status => status.user.toString() === userId.toString()
  );
  
  if (!userReadStatus || !userReadStatus.lastReadMessage) {
    // Count all messages if user hasn't read any
    return await Message.countDocuments({ 
      privateChat: this._id,
      sender: { $ne: userId }
    });
  }
  
  // Count messages after last read message
  const lastReadMessage = await Message.findById(userReadStatus.lastReadMessage);
  if (!lastReadMessage) {
    return 0;
  }
  
  return await Message.countDocuments({
    privateChat: this._id,
    sender: { $ne: userId },
    createdAt: { $gt: lastReadMessage.createdAt }
  });
};

// Method to mark messages as read
privateChatSchema.methods.markAsRead = async function(userId, messageId = null) {
  const userReadStatusIndex = this.readStatus.findIndex(
    status => status.user.toString() === userId.toString()
  );
  
  if (userReadStatusIndex === -1) {
    // Add new read status
    this.readStatus.push({
      user: userId,
      lastReadMessage: messageId || this.lastMessage,
      lastReadAt: new Date()
    });
  } else {
    // Update existing read status
    this.readStatus[userReadStatusIndex].lastReadMessage = messageId || this.lastMessage;
    this.readStatus[userReadStatusIndex].lastReadAt = new Date();
  }
  
  return await this.save();
};

// Method to get the other participant
privateChatSchema.methods.getOtherParticipant = function(userId) {
  return this.participants.find(
    participantId => participantId.toString() !== userId.toString()
  );
};

// Static method to find or create private chat between two users
privateChatSchema.statics.findOrCreate = async function(user1Id, user2Id) {
  // Sort user IDs to ensure consistent ordering
  const sortedParticipants = [user1Id, user2Id].sort();
  
  let privateChat = await this.findOne({
    participants: { $all: sortedParticipants, $size: 2 },
    isActive: true
  }).populate('participants', 'username email profilePicture isOnline lastSeen');
  
  if (!privateChat) {
    privateChat = new this({
      participants: sortedParticipants,
      metadata: {
        createdBy: user1Id
      },
      readStatus: [
        { user: user1Id, lastReadAt: new Date() },
        { user: user2Id, lastReadAt: new Date() }
      ]
    });
    
    await privateChat.save();
    await privateChat.populate('participants', 'username email profilePicture isOnline lastSeen');
  }
  
  return privateChat;
};

// Static method to get user's private chats
privateChatSchema.statics.getUserChats = async function(userId, page = 1, limit = 20) {
  const skip = (page - 1) * limit;
  
  return await this.find({
    participants: userId,
    isActive: true
  })
  .populate('participants', 'username email profilePicture isOnline lastSeen')
  .populate('lastMessage')
  .sort({ lastActivity: -1 })
  .skip(skip)
  .limit(limit);
};

module.exports = mongoose.model('PrivateChat', privateChatSchema);
