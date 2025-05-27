const { authenticateSocket } = require('../middleware/auth');
const User = require('../models/User');
const ChatRoom = require('../models/ChatRoom');
const Message = require('../models/Message');
const FriendRequest = require('../models/FriendRequest');
const PrivateChat = require('../models/PrivateChat');

const socketHandler = (io) => {
  // Authentication middleware for socket connections
  io.use(authenticateSocket);

  io.on('connection', async (socket) => {
    console.log(`✅ User connected: ${socket.user.username} (${socket.id})`);

    try {
      // Update user's online status and socket ID
      await socket.user.setOnlineStatus(true, socket.id);

      // Join user to their chat rooms
      const userRooms = await ChatRoom.find({
        'participants.user': socket.user._id
      }).select('_id');

      userRooms.forEach(room => {
        socket.join(room._id.toString());
        console.log(`📱 ${socket.user.username} joined room: ${room._id}`);
      });

      // Notify other users that this user is online
      socket.broadcast.emit('user_online', {
        userId: socket.user._id,
        username: socket.user.username,
        isOnline: true
      });

      // Send user's rooms and online users
      socket.emit('user_rooms', userRooms.map(room => room._id));

      // Get online users
      const onlineUsers = await User.find({ isOnline: true })
        .select('username profilePicture isOnline')
        .limit(100);

      socket.emit('online_users', onlineUsers);

    } catch (error) {
      console.error('Socket connection setup error:', error);
    }

    // Handle joining a chat room
    socket.on('join_room', async (data) => {
      try {
        const { roomId } = data;
        const chatRoom = await ChatRoom.findById(roomId);

        if (!chatRoom) {
          socket.emit('error', { message: 'Chat room not found' });
          return;
        }

        if (!chatRoom.isParticipant(socket.user._id)) {
          socket.emit('error', { message: 'Not authorized to join this room' });
          return;
        }

        socket.join(roomId);
        console.log(`📱 ${socket.user.username} joined room: ${roomId}`);

        // Notify room members
        socket.to(roomId).emit('user_joined_room', {
          userId: socket.user._id,
          username: socket.user.username,
          roomId
        });

        socket.emit('joined_room', { roomId });

      } catch (error) {
        console.error('Join room error:', error);
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    // Handle leaving a chat room
    socket.on('leave_room', async (data) => {
      try {
        const { roomId } = data;

        socket.leave(roomId);
        console.log(`📱 ${socket.user.username} left room: ${roomId}`);

        // Notify room members
        socket.to(roomId).emit('user_left_room', {
          userId: socket.user._id,
          username: socket.user.username,
          roomId
        });

        socket.emit('left_room', { roomId });

      } catch (error) {
        console.error('Leave room error:', error);
        socket.emit('error', { message: 'Failed to leave room' });
      }
    });

    // Handle sending a message
    socket.on('send_message', async (data) => {
      try {
        const { roomId, content, messageType = 'text', replyTo } = data;

        // Validate input
        if (!roomId || !content || content.trim().length === 0) {
          socket.emit('error', { message: 'Room ID and message content are required' });
          return;
        }

        // Check if user is participant of the room
        const chatRoom = await ChatRoom.findById(roomId);
        if (!chatRoom || !chatRoom.isParticipant(socket.user._id)) {
          socket.emit('error', { message: 'Not authorized to send messages to this room' });
          return;
        }

        // Create new message
        const message = new Message({
          content: content.trim(),
          sender: socket.user._id,
          chatRoom: roomId,
          messageType,
          replyTo: replyTo || null
        });

        await message.save();

        // Update chat room's last activity and last message
        chatRoom.lastMessage = message._id;
        await chatRoom.updateLastActivity();

        // Populate message for response
        await message.populate('sender', 'username profilePicture');
        if (replyTo) {
          await message.populate('replyTo', 'content sender');
        }

        // Send message to all room participants
        io.to(roomId).emit('new_message', {
          message: {
            _id: message._id,
            content: message.content,
            sender: message.sender,
            chatRoom: message.chatRoom,
            messageType: message.messageType,
            deliveryStatus: message.deliveryStatus,
            replyTo: message.replyTo,
            createdAt: message.createdAt,
            isEdited: message.isEdited
          }
        });

        console.log(`💬 Message sent by ${socket.user.username} in room ${roomId}`);

      } catch (error) {
        console.error('Send message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Handle message read status
    socket.on('mark_message_read', async (data) => {
      try {
        const { messageId } = data;

        const message = await Message.findById(messageId);
        if (!message) {
          socket.emit('error', { message: 'Message not found' });
          return;
        }

        // Mark message as read by current user
        await message.markAsRead(socket.user._id);

        // Notify sender about read status
        const senderUser = await User.findById(message.sender);
        if (senderUser && senderUser.socketId) {
          io.to(senderUser.socketId).emit('message_read', {
            messageId: message._id,
            readBy: socket.user._id,
            readAt: new Date()
          });
        }

      } catch (error) {
        console.error('Mark message read error:', error);
        socket.emit('error', { message: 'Failed to mark message as read' });
      }
    });

    // Handle typing indicators
    socket.on('typing_start', (data) => {
      const { roomId } = data;
      socket.to(roomId).emit('user_typing', {
        userId: socket.user._id,
        username: socket.user.username,
        roomId
      });
    });

    socket.on('typing_stop', (data) => {
      const { roomId } = data;
      socket.to(roomId).emit('user_stop_typing', {
        userId: socket.user._id,
        username: socket.user.username,
        roomId
      });
    });

    // Handle private chat joining
    socket.on('join_private_chat', async (data) => {
      try {
        const { chatId } = data;
        const privateChat = await PrivateChat.findById(chatId);

        if (!privateChat) {
          socket.emit('error', { message: 'Private chat not found' });
          return;
        }

        if (!privateChat.participants.includes(socket.user._id)) {
          socket.emit('error', { message: 'Not authorized to join this private chat' });
          return;
        }

        socket.join(`private_${chatId}`);
        console.log(`📱 ${socket.user.username} joined private chat: ${chatId}`);

        socket.emit('joined_private_chat', { chatId });

      } catch (error) {
        console.error('Join private chat error:', error);
        socket.emit('error', { message: 'Failed to join private chat' });
      }
    });

    // Handle private message sending
    socket.on('send_private_message', async (data) => {
      try {
        const { chatId, content, messageType = 'text', replyTo } = data;

        // Validate input
        if (!chatId || !content || content.trim().length === 0) {
          socket.emit('error', { message: 'Chat ID and message content are required' });
          return;
        }

        // Check if user is participant of the private chat
        const privateChat = await PrivateChat.findById(chatId);
        if (!privateChat || !privateChat.participants.includes(socket.user._id)) {
          socket.emit('error', { message: 'Not authorized to send messages to this private chat' });
          return;
        }

        // Create new message
        const message = new Message({
          content: content.trim(),
          sender: socket.user._id,
          privateChat: chatId,
          messageType,
          replyTo: replyTo || null
        });

        await message.save();

        // Update private chat's last activity and last message
        privateChat.lastMessage = message._id;
        privateChat.lastActivity = new Date();
        await privateChat.save();

        // Populate message for response
        await message.populate('sender', 'username profilePicture');
        if (replyTo) {
          await message.populate('replyTo', 'content sender');
        }

        // Send message to private chat participants
        io.to(`private_${chatId}`).emit('new_private_message', {
          message: {
            _id: message._id,
            content: message.content,
            sender: message.sender,
            privateChat: message.privateChat,
            messageType: message.messageType,
            deliveryStatus: message.deliveryStatus,
            replyTo: message.replyTo,
            createdAt: message.createdAt,
            isEdited: message.isEdited
          }
        });

        // Send notification to the other participant if they're online
        const otherParticipant = privateChat.getOtherParticipant(socket.user._id);
        const otherUser = await User.findById(otherParticipant);
        if (otherUser && otherUser.socketId && otherUser.isOnline) {
          io.to(otherUser.socketId).emit('private_message_notification', {
            chatId,
            senderId: socket.user._id,
            senderName: socket.user.username,
            messagePreview: content.substring(0, 50) + (content.length > 50 ? '...' : ''),
            timestamp: new Date()
          });
        }

        console.log(`💬 Private message sent by ${socket.user.username} in chat ${chatId}`);

      } catch (error) {
        console.error('Send private message error:', error);
        socket.emit('error', { message: 'Failed to send private message' });
      }
    });

    // Handle friend request notifications
    socket.on('friend_request_sent', async (data) => {
      try {
        const { receiverId, requestId } = data;

        const receiver = await User.findById(receiverId);
        if (receiver && receiver.socketId && receiver.isOnline) {
          const friendRequest = await FriendRequest.findById(requestId)
            .populate('sender', 'username email profilePicture');

          io.to(receiver.socketId).emit('friend_request_received', {
            friendRequest,
            timestamp: new Date()
          });
        }

      } catch (error) {
        console.error('Friend request notification error:', error);
      }
    });

    // Handle friend request response notifications
    socket.on('friend_request_responded', async (data) => {
      try {
        const { senderId, status, requestId } = data;

        const sender = await User.findById(senderId);
        if (sender && sender.socketId && sender.isOnline) {
          io.to(sender.socketId).emit('friend_request_response', {
            requestId,
            status,
            responderId: socket.user._id,
            responderName: socket.user.username,
            timestamp: new Date()
          });
        }

      } catch (error) {
        console.error('Friend request response notification error:', error);
      }
    });

    // Handle private chat typing indicators
    socket.on('private_typing_start', (data) => {
      const { chatId } = data;
      socket.to(`private_${chatId}`).emit('private_user_typing', {
        userId: socket.user._id,
        username: socket.user.username,
        chatId
      });
    });

    socket.on('private_typing_stop', (data) => {
      const { chatId } = data;
      socket.to(`private_${chatId}`).emit('private_user_stop_typing', {
        userId: socket.user._id,
        username: socket.user.username,
        chatId
      });
    });

    // Handle disconnection
    socket.on('disconnect', async () => {
      try {
        console.log(`❌ User disconnected: ${socket.user.username} (${socket.id})`);

        // Update user's offline status
        await socket.user.setOnlineStatus(false);

        // Notify other users that this user is offline
        socket.broadcast.emit('user_offline', {
          userId: socket.user._id,
          username: socket.user.username,
          isOnline: false,
          lastSeen: new Date()
        });

      } catch (error) {
        console.error('Socket disconnection error:', error);
      }
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error('Socket error:', error);
    });

  });

  // Handle connection errors
  io.on('connect_error', (error) => {
    console.error('Socket.io connection error:', error);
  });
};

module.exports = socketHandler;
