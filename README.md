# TaskFlow - Flutter ToDo App

## Overview

TaskFlow is a feature-rich task management app built with Flutter using the GetX state management pattern. It helps users organize their tasks efficiently while providing insightful analytics on productivity.

![TaskFlow App](https://via.placeholder.com/800x400)

## Features

- **Beautiful UI**: Clean, modern interface with light and dark theme support
- **User Authentication**: Secure login/signup with email and password
- **Task Management**:
  - Create, edit, and delete tasks
  - Set due dates and priorities
  - Categorize tasks for better organization
  - Mark tasks as complete
  - Slide to delete or edit tasks
- **Analytics Dashboard**: Track productivity with visual charts
  - Completion rate
  - Tasks by category
  - Daily/weekly performance metrics
- **Profile Management**: Customize user profile and preferences
- **Cloud Storage**: Synchronize tasks across devices using Firebase Firestore
- **Responsive Design**: Optimized for both mobile and tablet

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **GetX**: State management, dependency injection, and routing
- **Firebase**:
  - Firestore: Database for storing tasks and user data
  - Authentication: User management
- **fl_chart**: Beautiful charts for analytics
- **Google Fonts**: Typography
- **Flutter Slidable**: Swipe actions for tasks

## Getting Started

### Prerequisites

- Flutter 3.x or higher
- Dart SDK 3.x or higher
- Firebase project setup

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/taskflow.git
   cd taskflow
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password) and Firestore
   - Download `google-services.json` and place it in the `android/app` directory
   - Download `GoogleService-Info.plist` and place it in the `ios/Runner` directory

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── app/
│   ├── bindings/         # GetX dependency injection
│   ├── controllers/      # GetX controllers
│   ├── data/
│   │   ├── models/       # Data models
│   │   └── services/     # API services
│   ├── modules/          # Feature modules
│   │   ├── analytics/    # Analytics screen
│   │   ├── auth/         # Authentication screens
│   │   ├── home/         # Home screen
│   │   ├── profile/      # Profile screen
│   │   └── splash/       # Splash screen
│   ├── routes/           # App navigation
│   ├── theme/            # App theme
│   └── widgets/          # Reusable widgets
└── main.dart             # App entry point
```

## Screenshots

<div style="display: flex; justify-content: space-between;">
  <img src="https://via.placeholder.com/200x400" width="200" alt="Splash Screen">
  <img src="https://via.placeholder.com/200x400" width="200" alt="Home Screen">
  <img src="https://via.placeholder.com/200x400" width="200" alt="Analytics Screen">
  <img src="https://via.placeholder.com/200x400" width="200" alt="Profile Screen">
</div>

## Firebase Configuration

Make sure to set up your Firestore database with the following collections:

- `users`: Store user profiles
  - `{uid}`: User document (auto-generated by Firebase Auth)
    - `tasks`: Subcollection for user tasks

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [GetX](https://pub.dev/packages/get)
- [Firebase](https://firebase.google.com/)
- [Flutter Community](https://flutter.dev/community)