# Himachali Taxi - Backend

This is the backend server for the Himachali Taxi application. It handles user authentication, captain management, ride requests, location updates, and more.

## 🏗 Project Structure

```
Backend/
├── config/         # Configuration files (database, socket.io)
├── controllers/    # Request handlers and business logic
├── middleware/     # Custom middleware (e.g., authentication)
├── models/         # Mongoose schemas and data models
├── routes/         # API route definitions
├── services/       # External service integrations (e.g., email)
├── uploads/        # Directory for user uploads (e.g., profile images)
├── utils/          # Utility functions (OTP generation, email templates, logger)
├── .env.example    # Example environment variables file
├── .gitignore      # Specifies intentionally untracked files
├── package.json    # Project metadata and dependencies
├── package-lock.json # Records exact versions of dependencies
└── server.js       # Main application entry point
```

## 🚀 Technologies Used

- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **Socket.IO** - Real-time communication
- **JWT** - Authentication
- **Mongoose** - MongoDB object modeling
- **Nodemailer** - Email service
- **Multer** - File upload handling

## 📋 Prerequisites

- Node.js (LTS version recommended, e.g., v18.x or v20.x)
- npm (usually comes with Node.js)
- MongoDB (either a local instance or MongoDB Atlas)
- Git client

## ⚙️ Setup and Installation

1. Clone the repository:
```bash
git clone https://github.com/KashishIndoria/Himachali_Taxi.git
cd Himachali_Taxi/Backend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
   - Create a `.env` file in the Backend root directory
   - Add the following variables:
     ```
     PORT=3000
     MONGODB_URI=your_mongodb_connection_string
     JWT_SECRET=your_very_strong_jwt_secret_key
     EMAIL_HOST=your_email_host
     EMAIL_PORT=your_email_port
     EMAIL_USER=your_email_user
     EMAIL_PASS=your_email_password
     NODE_ENV=development
     ```

## 🚀 Available Scripts

- Start development server:
```bash
npm run dev
```

- Start production server:
```bash
npm start
```

- Run tests:
```bash
npm test
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/user/signup` - User registration
- `POST /api/auth/user/login` - User login
- `POST /api/auth/captain/signup` - Captain registration
- `POST /api/auth/captain/login` - Captain login

### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `POST /api/users/upload` - Upload profile picture

### Captain Management
- `GET /api/captains/profile/:captainId` - Get captain profile
- `PUT /api/captains/profile` - Update captain profile
- `GET /api/captains/nearby` - Get nearby captains
- `PUT /api/captains/availability` - Update availability status

### Ride Management
- `POST /api/rides/request` - Request a ride
- `PUT /api/rides/:rideId/accept` - Accept ride request
- `PUT /api/rides/:rideId/cancel` - Cancel ride
- `PUT /api/rides/:rideId/complete` - Complete ride
- `GET /api/rides/history` - Get ride history

### Real-time Updates
- WebSocket events for:
  - Location updates
  - Ride status changes
  - New ride requests
  - Captain availability

## 🔒 Security Features

- JWT-based authentication
- Password hashing using bcrypt
- Rate limiting
- Input validation
- CORS configuration
- Helmet security headers

## 📦 Deployment

The backend can be deployed to various platforms:

- Render
- Heroku
- Azure App Service
- AWS Elastic Beanstalk
- Google App Engine

### Deployment Checklist

1. Set up environment variables
2. Configure MongoDB connection
3. Set up SSL/TLS certificates
4. Configure CORS for production
5. Set up logging and monitoring
6. Configure backup strategy

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

For support, email support@himachalitaxi.com or join our Slack channel.

## 🔄 Updates

- Real-time location tracking
- Enhanced security features
- Improved error handling
- Better documentation
