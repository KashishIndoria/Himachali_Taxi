# Himachali Taxi 🚕

A modern taxi booking application with real-time tracking, video calling, and secure payments. Built with Flutter for the frontend and Node.js for the backend.

## 🌟 Features

### Frontend Features
- **Real-time Ride Tracking**
  - Live location sharing between driver and passenger
  - Real-time ride status updates
  - Interactive map interface

- **Video Calling**
  - In-app video calls between driver and passenger
  - Secure peer-to-peer communication
  - High-quality video streaming

- **Authentication & Security**
  - Secure token-based authentication
  - Role-based access control (Driver/Passenger)
  - Secure data storage

- **Ride Management**
  - Easy ride booking
  - Ride history tracking
  - Real-time ride status updates
  - Ride cancellation support

- **User Experience**
  - Dark/Light theme support
  - Responsive UI design
  - Push notifications
  - Offline support

### Backend Features
- **Real-time Communication**
  - WebSocket integration
  - Live location updates
  - Instant notifications
  - Ride status synchronization

- **Security**
  - JWT authentication
  - Password hashing
  - Rate limiting
  - Input validation
  - CORS protection

- **Data Management**
  - MongoDB integration
  - File upload handling
  - Email notifications
  - Data validation

## 🛠 Tech Stack

### Frontend
| Technology        | Purpose                                     |
|------------------|---------------------------------------------|
| **Flutter**       | Frontend cross-platform mobile framework    |
| **MongoDB Atlas** | Backend database for auth and ride data     |
| **Supabase**      | Cloud storage for driver profile images     |
| **Google Maps API** | Display maps and routes in the app       |
| **Geolocator**    | Fetch current GPS location                  |
| **Provider**      | App-wide state management                   |
| **GoRouter**      | Navigation between Flutter screens          |

### Backend
| Technology        | Purpose                                     |
|------------------|---------------------------------------------|
| **Node.js**       | Runtime environment                         |
| **Express.js**    | Web framework                               |
| **MongoDB**       | Database                                    |
| **Socket.IO**     | Real-time communication                     |
| **JWT**           | Authentication                              |
| **Mongoose**      | MongoDB object modeling                     |
| **Nodemailer**    | Email service                               |
| **Multer**        | File upload handling                        |

## 📁 Project Structure

### Frontend (himachali_taxi/)
```
lib/
├── models/         # Data models and entities
├── screens/        # UI screens
│   ├── ride_booking_screen.dart
│   ├── ride_history_screen.dart
│   └── video_call_screen.dart
├── services/       # API and service integrations
│   └── socket_service.dart
├── utils/          # Utility functions and helpers
│   ├── sf_manager.dart
│   └── themes/
├── widgets/        # Reusable UI components
├── provider/       # State management
│   ├── auth_provider.dart
│   ├── captain_provider.dart
│   └── socket_provider.dart
├── routers/        # Navigation routes
└── main.dart       # Application entry point
```

### Backend (Backend/)
```
Backend/
├── config/         # Configuration files
├── controllers/    # Request handlers
├── middleware/     # Custom middleware
├── models/         # Mongoose schemas
├── routes/         # API route definitions
├── services/       # External services
├── uploads/        # User uploads
├── utils/          # Utility functions
├── .env.example    # Environment variables
├── package.json    # Dependencies
└── server.js       # Entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Node.js (LTS version)
- MongoDB (local or Atlas)
- Git client
- Android Studio / VS Code

### Frontend Setup
1. Clone the repository:
```bash
git clone https://github.com/KashishIndoria/Himachali_Taxi.git
cd Himachali_Taxi/himachali_taxi
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment:
   - Create `.env` file
   - Add required API keys:
     ```
     BACKEND_URL=your_backend_url
     GOOGLE_MAPS_API_KEY=your_google_maps_api_key
     ```

4. Run the app:
```bash
flutter run
```

### Backend Setup
1. Navigate to backend directory:
```bash
cd ../Backend
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment:
   - Create `.env` file
   - Add required variables:
     ```
     PORT=3000
     MONGODB_URI=your_mongodb_connection_string
     JWT_SECRET=your_jwt_secret
     EMAIL_HOST=your_email_host
     EMAIL_PORT=your_email_port
     EMAIL_USER=your_email_user
     EMAIL_PASS=your_email_password
     NODE_ENV=development
     ```

4. Start the server:
```bash
npm run dev
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

## 📦 Deployment

### Frontend Deployment
- Google Play Store
- Apple App Store
- Firebase App Distribution

### Backend Deployment
- Render
- Heroku
- Azure App Service
- AWS Elastic Beanstalk
- Google App Engine

### Deployment Checklist
1. Set up environment variables
2. Configure database connections
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

## 🔄 Recent Updates

- Real-time location tracking
- Video calling integration
- Enhanced security features
- Improved error handling
- Better documentation
- Dark/Light theme support 