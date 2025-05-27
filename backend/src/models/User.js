const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, 'Username is required'],
    unique: true,
    trim: true,
    minlength: [3, 'Username must be at least 3 characters long'],
    maxlength: [30, 'Username cannot exceed 30 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters long']
  },
  profilePicture: {
    type: String,
    default: ''
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  socketId: {
    type: String,
    default: null
  },
  joinedRooms: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ChatRoom'
  }],
  friends: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  friendRequestsSent: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'FriendRequest'
  }],
  friendRequestsReceived: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'FriendRequest'
  }]
}, {
  timestamps: true
});

// Index for faster queries
userSchema.index({ email: 1 });
userSchema.index({ username: 1 });
userSchema.index({ isOnline: 1 });

// Virtual for user's full profile
userSchema.virtual('profile').get(function() {
  return {
    id: this._id,
    username: this.username,
    email: this.email,
    profilePicture: this.profilePicture,
    isOnline: this.isOnline,
    lastSeen: this.lastSeen
  };
});

// Method to update last seen
userSchema.methods.updateLastSeen = function() {
  this.lastSeen = new Date();
  return this.save();
};

// Method to set online status
userSchema.methods.setOnlineStatus = function(isOnline, socketId = null) {
  this.isOnline = isOnline;
  this.socketId = socketId;
  if (!isOnline) {
    this.lastSeen = new Date();
  }
  return this.save();
};

module.exports = mongoose.model('User', userSchema);
