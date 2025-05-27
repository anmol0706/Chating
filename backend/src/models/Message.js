const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  content: {
    type: String,
    required: [true, 'Message content is required'],
    trim: true,
    maxlength: [1000, 'Message cannot exceed 1000 characters']
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  chatRoom: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ChatRoom'
  },
  privateChat: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'PrivateChat'
  },
  messageType: {
    type: String,
    enum: ['text', 'image', 'file', 'system'],
    default: 'text'
  },
  deliveryStatus: {
    type: String,
    enum: ['sent', 'delivered', 'read'],
    default: 'sent'
  },
  readBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  editedAt: {
    type: Date,
    default: null
  },
  isEdited: {
    type: Boolean,
    default: false
  },
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message',
    default: null
  }
}, {
  timestamps: true
});

// Validation: message must belong to either chatRoom or privateChat, but not both
messageSchema.pre('save', function(next) {
  const hasChatRoom = !!this.chatRoom;
  const hasPrivateChat = !!this.privateChat;

  if (hasChatRoom && hasPrivateChat) {
    return next(new Error('Message cannot belong to both chatRoom and privateChat'));
  }

  if (!hasChatRoom && !hasPrivateChat) {
    return next(new Error('Message must belong to either chatRoom or privateChat'));
  }

  next();
});

// Index for faster queries
messageSchema.index({ chatRoom: 1, createdAt: -1 });
messageSchema.index({ privateChat: 1, createdAt: -1 });
messageSchema.index({ sender: 1 });
messageSchema.index({ deliveryStatus: 1 });
messageSchema.index({ createdAt: -1 });

// Virtual for formatted timestamp
messageSchema.virtual('formattedTime').get(function() {
  return this.createdAt.toLocaleTimeString();
});

// Method to mark as read by user
messageSchema.methods.markAsRead = function(userId) {
  const existingRead = this.readBy.find(r => r.user.toString() === userId.toString());

  if (!existingRead) {
    this.readBy.push({
      user: userId,
      readAt: new Date()
    });

    // Update delivery status if this is the sender's first read
    if (this.deliveryStatus === 'delivered') {
      this.deliveryStatus = 'read';
    }
  }

  return this.save();
};

// Method to edit message
messageSchema.methods.editContent = function(newContent) {
  this.content = newContent;
  this.isEdited = true;
  this.editedAt = new Date();
  return this.save();
};

// Static method to get recent messages for a chat room
messageSchema.statics.getRecentMessages = function(chatRoomId, limit = 50, skip = 0) {
  return this.find({ chatRoom: chatRoomId })
    .populate('sender', 'username profilePicture')
    .populate('replyTo', 'content sender')
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip(skip)
    .exec();
};

module.exports = mongoose.model('Message', messageSchema);
