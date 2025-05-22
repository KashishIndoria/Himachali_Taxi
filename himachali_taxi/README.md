# Himachali Taxi

A modern taxi booking application built with Flutter, providing seamless ride-hailing services with real-time tracking, video calling, and secure payments.

## 🚀 Features

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

## 🛠 Technologies & Services

| Technology        | Purpose                                     |
|------------------|---------------------------------------------|
| **Flutter**       | Frontend cross-platform mobile framework    |
| **MongoDB Atlas** | Backend database for auth and ride data     |
| **Supabase**      | Cloud storage for driver profile images     |
| **Google Maps API** | Display maps and routes in the app       |
| **Geolocator**    | Fetch current GPS location                  |
| **Provider**      | App-wide state management                   |
| **GoRouter**      | Navigation between Flutter screens          |

## 📱 Project Structure

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

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK (latest version)
- Android Studio / VS Code
- Google Maps API key
- MongoDB Atlas account
- Supabase account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/himachali_taxi.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment variables:
   - Create a `.env` file in the root directory
   - Add your API keys and configuration:
     ```
     BACKEND_URL=your_backend_url
     GOOGLE_MAPS_API_KEY=your_google_maps_api_key
     ```

4. Run the app:
```bash
flutter run
```

## 🔧 Key Components

### State Management
- Uses Provider pattern for state management
- Separate providers for:
  - Authentication
  - Socket connections
  - Captain (Driver) management
  - Video calls
  - Theme management

### Real-time Features
- Socket.IO integration for real-time updates
- Live location tracking
- Real-time ride status updates
- Video call functionality

### Authentication
- Token-based authentication
- Secure storage using SfManager
- Role-based access control
- Automatic token refresh

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

- Real-time ride tracking
- Video calling integration
- Dark/Light theme support
- Enhanced security features
