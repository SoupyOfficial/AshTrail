# AshTrail (Smoke Log)

A comprehensive cannabis consumption tracking application built with Flutter, featuring advanced THC modeling, analytics, and multi-platform support.

## Overview

AshTrail is a privacy-focused smoke logging application that helps users track their cannabis consumption with detailed metrics, advanced THC concentration modeling, and comprehensive analytics. The app supports multiple user accounts, offline synchronization, and cross-platform functionality.

## Key Features

- **Advanced THC Modeling**: Sophisticated pharmacokinetic calculations based on user demographics and consumption methods
- **Comprehensive Logging**: Track duration, mood ratings, physical effects, potency, and detailed notes
- **Multi-Account Support**: Secure user authentication with account switching capabilities
- **Analytics & Visualization**: Interactive charts and data insights using FL Chart
- **Offline-First Architecture**: Firebase integration with robust offline capabilities
- **Cross-Platform**: Native support for iOS, Android, Web, and Desktop platforms
- **Theme Customization**: Light/dark modes with custom accent color selection

## Architecture

The application follows a modern Flutter architecture with:
- **State Management**: Riverpod for reactive state management
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **Local Storage**: Hive for efficient offline data storage
- **UI Framework**: Material Design 3 with custom theming

## Project Documentation

📚 **Comprehensive redesign documentation is available in the [docs/](./docs/) directory:**

- **[Feature Inventory](./docs/feature-inventory.md)**: Complete catalog of current capabilities
- **[Technical Architecture](./docs/technical-architecture.md)**: Architecture analysis and clean architecture implementation plan  
- **[Missing Features Analysis](./docs/missing-features-analysis.md)**: Gap analysis and enhancement opportunities
- **[Performance Optimization](./docs/performance-optimization.md)**: Comprehensive performance improvement strategies
- **[Implementation Roadmap](./docs/implementation-roadmap.md)**: 14-week development plan for redesign

## Getting Started

### Prerequisites

- Flutter SDK 3.6.0 or higher
- Dart SDK 3.0.0 or higher
- Firebase project setup
- Platform-specific development tools (Xcode for iOS, Android Studio for Android)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/SoupyOfficial/AshTrail.git
cd AshTrail
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in `lib/firebase_options.dart`

4. Run the application:
```bash
flutter run
```

### Development Setup

For development mode with auto-login (modify `main.dart`):
```dart
const bool enableAutoLoginInDevMode = true; // Set to true for development
```

## Project Structure

```
lib/
├── domain/              # Business logic and entities
├── models/              # Data models
├── providers/           # Riverpod state management
├── services/            # Business services
├── screens/             # UI screens
├── widgets/             # Reusable UI components
├── theme/               # Theme and styling
└── utils/               # Utility functions

docs/                    # Comprehensive project documentation
test/                    # Test files
```

## Contributing

1. Review the [Implementation Roadmap](./docs/implementation-roadmap.md) for planned development phases
2. Follow the [Technical Architecture](./docs/technical-architecture.md) guidelines
3. Ensure all new features include appropriate tests
4. Follow the existing code style and conventions

## Performance Targets

- **Startup Time**: < 2 seconds
- **Memory Usage**: < 150MB during normal operation
- **Battery Impact**: Optimized background processing
- **Test Coverage**: 90%+ with comprehensive testing

## Platforms Supported

- ✅ **iOS**: Native iOS application
- ✅ **Android**: Native Android application  
- ✅ **Web**: Progressive Web App capabilities
- ✅ **macOS**: Desktop application
- ✅ **Windows**: Desktop application
- ✅ **Linux**: Desktop application

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the excellent framework
- Firebase for backend services
- FL Chart for data visualization capabilities
- Riverpod for state management
- The cannabis research community for THC pharmacokinetic insights
