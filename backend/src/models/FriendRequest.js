const mongoose = require('mongoose');

const friendRequestSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  receiver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'declined', 'cancelled'],
    default: 'pending'
  },
  message: {
    type: String,
    trim: true,
    maxlength: [200, 'Friend request message cannot exceed 200 characters'],
    default: ''
  },
  respondedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Index for faster queries
friendRequestSchema.index({ sender: 1, receiver: 1 });
friendRequestSchema.index({ receiver: 1, status: 1 });
friendRequestSchema.index({ sender: 1, status: 1 });
friendRequestSchema.index({ createdAt: -1 });

// Ensure unique friend request between two users
friendRequestSchema.index(
  { sender: 1, receiver: 1 },
  { 
    unique: true,
    partialFilterExpression: { status: 'pending' }
  }
);

// Virtual for request age
friendRequestSchema.virtual('requestAge').get(function() {
  return Date.now() - this.createdAt.getTime();
});

// Method to accept friend request
friendRequestSchema.methods.accept = async function() {
  const User = require('./User');
  
  // Update request status
  this.status = 'accepted';
  this.respondedAt = new Date();
  await this.save();

  // Add each user to the other's friends list
  await User.findByIdAndUpdate(
    this.sender,
    { $addToSet: { friends: this.receiver } }
  );
  
  await User.findByIdAndUpdate(
    this.receiver,
    { $addToSet: { friends: this.sender } }
  );

  return this;
};

// Method to decline friend request
friendRequestSchema.methods.decline = async function() {
  this.status = 'declined';
  this.respondedAt = new Date();
  return await this.save();
};

// Method to cancel friend request
friendRequestSchema.methods.cancel = async function() {
  this.status = 'cancelled';
  this.respondedAt = new Date();
  return await this.save();
};

// Static method to check if friend request exists
friendRequestSchema.statics.existsBetween = async function(senderId, receiverId) {
  return await this.findOne({
    $or: [
      { sender: senderId, receiver: receiverId, status: 'pending' },
      { sender: receiverId, receiver: senderId, status: 'pending' }
    ]
  });
};

// Static method to check if users are already friends
friendRequestSchema.statics.areFriends = async function(userId1, userId2) {
  const User = require('./User');
  const user = await User.findById(userId1).select('friends');
  return user && user.friends.includes(userId2);
};

module.exports = mongoose.model('FriendRequest', friendRequestSchema);
