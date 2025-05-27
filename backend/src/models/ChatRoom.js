const mongoose = require('mongoose');

const chatRoomSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Chat room name is required'],
    trim: true,
    minlength: [1, 'Chat room name must be at least 1 character long'],
    maxlength: [50, 'Chat room name cannot exceed 50 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [200, 'Description cannot exceed 200 characters'],
    default: ''
  },
  type: {
    type: String,
    enum: ['public', 'private'],
    default: 'public'
  },
  participants: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    role: {
      type: String,
      enum: ['admin', 'member'],
      default: 'member'
    }
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message'
  },
  lastActivity: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for faster queries
chatRoomSchema.index({ name: 1 });
chatRoomSchema.index({ type: 1 });
chatRoomSchema.index({ 'participants.user': 1 });
chatRoomSchema.index({ lastActivity: -1 });

// Virtual for participant count
chatRoomSchema.virtual('participantCount').get(function() {
  return this.participants.length;
});

// Method to add participant
chatRoomSchema.methods.addParticipant = function(userId, role = 'member') {
  const existingParticipant = this.participants.find(p => p.user.toString() === userId.toString());
  
  if (!existingParticipant) {
    this.participants.push({
      user: userId,
      role: role,
      joinedAt: new Date()
    });
  }
  
  return this.save();
};

// Method to remove participant
chatRoomSchema.methods.removeParticipant = function(userId) {
  this.participants = this.participants.filter(p => p.user.toString() !== userId.toString());
  return this.save();
};

// Method to check if user is participant
chatRoomSchema.methods.isParticipant = function(userId) {
  return this.participants.some(p => p.user.toString() === userId.toString());
};

// Method to update last activity
chatRoomSchema.methods.updateLastActivity = function() {
  this.lastActivity = new Date();
  return this.save();
};

module.exports = mongoose.model('ChatRoom', chatRoomSchema);
