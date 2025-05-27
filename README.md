# Real-Time Chat Application

A comprehensive real-time chat application built with Flutter (frontend) and Node.js (backend), featuring WebSocket communication, custom authentication, and MongoDB database integration.

## 🚀 Features

### Frontend (Flutter)
- **Cross-platform mobile app** - Works on iOS and Android
- **Real-time messaging** with WebSocket connections
- **User authentication** - Custom email/password login and registration
- **Modern UI** with Material Design 3
- **Chat rooms** - Create, join, and manage public/private rooms
- **Online status** - See who's online in real-time
- **Typing indicators** - See when users are typing
- **Message timestamps** and delivery status
- **User profiles** with profile picture support

### Backend (Node.js)
- **RESTful API** with Express.js framework
- **WebSocket server** using Socket.io for real-time communication
- **Custom authentication** with JWT tokens
- **Plain text password storage** (as per user preference)
- **MongoDB integration** with Mongoose ODM
- **Comprehensive error handling** and validation
- **CORS support** for cross-origin requests

### Database (MongoDB)
- **User management** - Store user credentials and profiles
- **Chat rooms** - Public and private room support
- **Message persistence** - Complete chat history
- **Indexing** for optimized queries
- **Real-time updates** with change streams

## 📁 Project Structure

```
chat_app/
├── backend/                 # Node.js Express server
│   ├── src/
│   │   ├── config/         # Database configuration
│   │   ├── controllers/    # Business logic
│   │   ├── middleware/     # Authentication & validation
│   │   ├── models/         # MongoDB schemas
│   │   ├── routes/         # API endpoints
│   │   └── socket/         # Socket.io handlers
│   ├── .env               # Environment variables
│   ├── package.json       # Dependencies
│   └── server.js          # Main server file
├── frontend/               # Flutter mobile app
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API & WebSocket services
│   │   ├── widgets/        # Reusable UI components
│   │   └── main.dart       # App entry point
│   └── pubspec.yaml       # Flutter dependencies
└── README.md              # This file
```

## 🛠️ Installation & Setup

### Prerequisites
- Node.js (v16 or higher)
- Flutter SDK (v3.0 or higher)
- MongoDB Atlas account (or local MongoDB)
- Git

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Environment configuration:**
   The `.env` file is already configured with:
   ```env
   PORT=3000
   MONGODB_URI=mongodb+srv://anmoldiscord4328:anmol4328@ak-chats.bhaiorc.mongodb.net/chatapp
   JWT_SECRET=your_jwt_secret_key_here_change_in_production
   NODE_ENV=development
   CORS_ORIGIN=http://localhost:3000
   ```

4. **Start the server:**
   ```bash
   npm start
   # or for development with auto-reload:
   npm run dev
   ```

   The server will start on `http://localhost:3000`

### Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d android
   flutter run -d ios
   ```

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/profile` - Get current user profile
- `GET /api/auth/verify` - Verify JWT token

### Chat Rooms
- `GET /api/chat/rooms` - Get user's chat rooms
- `GET /api/chat/rooms/public` - Get public chat rooms
- `POST /api/chat/rooms` - Create new chat room
- `POST /api/chat/rooms/:id/join` - Join chat room
- `POST /api/chat/rooms/:id/leave` - Leave chat room
- `GET /api/chat/rooms/:id/messages` - Get room messages

### Users
- `GET /api/user` - Get all users
- `GET /api/user/:id` - Get user by ID
- `PUT /api/user/profile` - Update user profile
- `PUT /api/user/password` - Change password

## 🔌 WebSocket Events

### Client to Server
- `join_room` - Join a chat room
- `leave_room` - Leave a chat room
- `send_message` - Send a message
- `typing_start` - Start typing indicator
- `typing_stop` - Stop typing indicator
- `mark_message_read` - Mark message as read

### Server to Client
- `new_message` - New message received
- `user_online` - User came online
- `user_offline` - User went offline
- `user_typing` - User started typing
- `user_stop_typing` - User stopped typing
- `user_joined_room` - User joined room
- `user_left_room` - User left room

## 🗄️ Database Schema

### Users Collection
```javascript
{
  username: String,
  email: String,
  password: String, // Plain text as per requirement
  profilePicture: String,
  isOnline: Boolean,
  lastSeen: Date,
  socketId: String,
  joinedRooms: [ObjectId]
}
```

### ChatRooms Collection
```javascript
{
  name: String,
  description: String,
  type: String, // 'public' or 'private'
  participants: [{
    user: ObjectId,
    joinedAt: Date,
    role: String // 'admin' or 'member'
  }],
  createdBy: ObjectId,
  lastMessage: ObjectId,
  lastActivity: Date
}
```

### Messages Collection
```javascript
{
  content: String,
  sender: ObjectId,
  chatRoom: ObjectId,
  messageType: String, // 'text', 'image', 'file'
  deliveryStatus: String, // 'sent', 'delivered', 'read'
  readBy: [{
    user: ObjectId,
    readAt: Date
  }],
  replyTo: ObjectId,
  isEdited: Boolean,
  editedAt: Date
}
```

## 🚦 Getting Started

1. **Start the backend server** (see Backend Setup above)
2. **Launch the Flutter app** (see Frontend Setup above)
3. **Register a new account** or login with existing credentials
4. **Create or join chat rooms** to start messaging
5. **Invite friends** to join your chat rooms

## 🔒 Security Features

- JWT-based authentication
- Input validation and sanitization
- CORS protection
- Rate limiting (can be added)
- SQL injection prevention with Mongoose
- XSS protection with input validation

## 🎯 Key Features Implemented

✅ **User Authentication** - Custom email/password system
✅ **Real-time Messaging** - WebSocket communication
✅ **Chat Rooms** - Create and manage rooms
✅ **Online Status** - Real-time user presence
✅ **Message History** - Persistent chat storage
✅ **Typing Indicators** - Live typing status
✅ **Cross-platform** - Flutter mobile app
✅ **Modern UI** - Material Design 3
✅ **Error Handling** - Comprehensive error management

## 🔮 Future Enhancements

- File and image sharing
- Push notifications
- Message encryption
- Voice messages
- Video calling
- Message reactions
- User roles and permissions
- Message search functionality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 📞 Support

For support or questions, please create an issue in the repository or contact the development team.

---

**Built with ❤️ using Flutter and Node.js**
