# AshTrail Feature Documentation

## Overview
AshTrail (Smoke Log) is a comprehensive cannabis consumption tracking application built with Flutter. This document provides a complete inventory of current features, technical capabilities, and user functionality.

## Table of Contents
1. [Core Features](#core-features)
2. [User Management](#user-management)
3. [Data Tracking & Analytics](#data-tracking--analytics)
4. [Advanced THC Modeling](#advanced-thc-modeling)
5. [Synchronization & Offline Support](#synchronization--offline-support)
6. [User Interface & Experience](#user-interface--experience)
7. [Security & Privacy](#security--privacy)
8. [Technical Capabilities](#technical-capabilities)

## Core Features

### 1. Log Entry System
**Description**: Comprehensive tracking system for cannabis consumption sessions.

**Capabilities**:
- **Duration Tracking**: Record session duration in seconds with precise timing
- **Mood Rating**: 1-10 scale mood assessment before/after consumption
- **Physical Rating**: 1-10 scale physical state assessment
- **Potency Rating**: Track perceived strength/potency of consumed material
- **Notes**: Free-form text notes for additional context
- **Reason Tracking**: Multiple reason selection from predefined options
- **Timestamp Management**: Automatic timestamping with manual date/time override capability

**Data Model**:
```dart
class Log {
  String? id;
  DateTime timestamp;
  double durationSeconds;
  int moodRating;           // 1-10 scale
  int physicalRating;       // 1-10 scale
  int? potencyRating;       // User-defined scale
  String? notes;
  List<String>? reason;     // Multiple reasons supported
}
```

### 2. Multi-Reason Selection System
**Description**: Flexible reason tracking for consumption patterns.

**Capabilities**:
- Multiple reason selection per log entry
- Predefined reason options via `ReasonOption` model
- Extensible reason system through providers
- Support for custom reason categories

## User Management

### 3. Multi-Account System
**Description**: Robust user account management supporting multiple users and account switching.

**Capabilities**:
- **User Registration**: Email/password and OAuth authentication (Google, Apple)
- **Account Switching**: Seamless switching between multiple user accounts
- **Profile Management**: User profile creation and management
- **Authentication State**: Persistent authentication with automatic re-authentication

**Services**:
- `AuthService`: Core authentication logic
- `AuthAccountService`: Account-specific authentication management
- `UserAccountService`: User account data management
- `UserProfileService`: Profile information management
- `CredentialService`: Secure credential storage and management
- `TokenService`: Authentication token management

**User Profile Model**:
```dart
class UserProfile {
  String uid;
  String email;
  String firstName;
  String? lastName;
  DateTime createdAt;
  DateTime? lastLoginAt;
  bool isActive;
}
```

### 4. Secure Authentication
**Description**: Enterprise-grade authentication with multiple provider support.

**Capabilities**:
- Firebase Authentication integration
- Google Sign-In support
- Apple Sign-In support
- Secure credential storage using Flutter Secure Storage
- Auto-login capabilities for development/testing

## Data Tracking & Analytics

### 5. Data Visualization & Charts
**Description**: Comprehensive analytics and visualization system using FL Chart.

**Current Capabilities**:
- Line chart visualization for trend analysis
- Chart data processing and aggregation
- Configurable chart display options
- Time-series data presentation

**Chart Components**:
- `LineChartWidget`: Primary chart display component
- `ChartDataProcessors`: Data aggregation and processing
- `ChartHelpers`: Utility functions for chart operations
- `ChartConfig`: Chart appearance and behavior configuration

### 6. Log Aggregation & Statistics
**Description**: Advanced data aggregation for insights and pattern recognition.

**Model**: `LogAggregates` - Statistical summaries and trend analysis
**Capabilities**:
- Time-based aggregation (daily, weekly, monthly)
- Statistical analysis of consumption patterns
- Mood and physical rating correlation analysis
- Usage frequency tracking

## Advanced THC Modeling

### 7. Pharmacokinetic THC Content Tracking
**Description**: Scientific THC concentration modeling based on consumption patterns.

**Core Model**: `THCModelNoMgInput`

**Advanced Capabilities**:
- **Consumption Method Support**: Joint, Bong, Vape, Dab with method-specific delivery rates
- **Demographic Adjustments**: Age, sex, body fat percentage, metabolic rate considerations
- **Absorption Modeling**: Diminishing absorption function for inhalation duration
- **Elimination Kinetics**: Exponential elimination with demographic-adjusted half-life
- **Real-time Estimation**: Current THC content calculation at any point in time

**Consumption Methods**:
```dart
enum ConsumptionMethod {
  joint,    // ~1.5 mg/s base delivery
  bong,     // ~2.0 mg/s base delivery  
  vape,     // ~2.5 mg/s base delivery
  dab,      // ~5.0 mg/s base delivery
}
```

**Demographic Factors**:
- Age adjustments (faster for <25, slower for 50+)
- Sex-based elimination differences
- Body fat percentage impact on clearance
- Metabolic rate (daily caloric burn) considerations

### 8. THC Calculator Use Case
**Description**: Domain-specific business logic for THC calculations.

**Location**: `lib/domain/use_cases/thc_calculator.dart`
**Purpose**: Encapsulates THC-related calculations and business rules

## Synchronization & Offline Support

### 9. Comprehensive Sync System
**Description**: Robust synchronization between local storage and cloud backend.

**Service**: `SyncService`

**Capabilities**:
- **Periodic Synchronization**: Configurable automatic sync intervals (default: 5 minutes)
- **Manual Sync**: User-initiated synchronization
- **Connectivity Awareness**: Network state monitoring with Connectivity Plus
- **Conflict Resolution**: Intelligent conflict resolution for concurrent edits
- **Sync Status Tracking**: Real-time sync status updates
- **Offline Operation**: Full functionality during network unavailability

**Sync States**:
- `SyncStatus.syncing`: Active synchronization in progress
- `SyncStatus.noUser`: No authenticated user for sync
- `SyncStatus.error`: Sync operation failed
- `SyncStatus.success`: Successful sync completion

### 10. Local Caching System
**Description**: Intelligent local data caching for offline functionality.

**Service**: `CacheService`

**Capabilities**:
- Persistent local storage using shared preferences
- Intelligent cache management and cleanup
- Data consistency maintenance between cache and remote storage
- Cache invalidation strategies

### 11. Connectivity Management
**Description**: Network connectivity monitoring and offline state management.

**Features**:
- Real-time connectivity status monitoring
- Automatic sync resumption on network restoration
- Offline indicators in UI
- Graceful degradation of network-dependent features

## User Interface & Experience

### 12. Theme System & Customization
**Description**: Comprehensive theming system with user personalization.

**Services**:
- `ThemeProvider`: Central theme state management
- `ThemePreferenceService`: Theme preference persistence
- `UserThemeService`: User-specific theme settings

**Capabilities**:
- **Light/Dark Mode**: System-wide theme switching
- **Accent Color Customization**: User-selectable accent colors
- **Theme Persistence**: Automatic theme preference saving
- **System Theme Detection**: Automatic theme based on system settings

**Theme Components**:
- `AppTheme`: Core theme definitions
- `ThemeToggleSwitch`: UI component for theme switching
- `AccentColorScreen`: Accent color selection interface

### 13. Responsive Design & Layouts
**Description**: Adaptive UI that works across different screen sizes and platforms.

**Capabilities**:
- Responsive dialog sizing (desktop vs mobile)
- Adaptive form layouts
- Screen-size aware component rendering
- Cross-platform consistent design

### 14. User Interface Components
**Description**: Rich set of custom UI components for enhanced user experience.

**Key Components**:
- `CustomAppBar`: Application-specific app bar with user switching
- `UserAccountSelector`: Multi-account switching interface
- `UserSwitcher`: Seamless account switching UI
- `RatingSlider`: Custom rating input component
- `AddLogForm`: Comprehensive log entry form
- `LogList`: Optimized log display component
- `InfoDisplay`: Data presentation component
- `THCInfoDisplay`: THC-specific information display
- `SyncIndicator`: Real-time sync status indicator
- `ConnectivityIndicator`: Network status display

## Security & Privacy

### 15. Data Security
**Description**: Enterprise-grade security measures for user data protection.

**Security Features**:
- **Encrypted Storage**: Flutter Secure Storage for sensitive data
- **Firebase Security Rules**: Server-side data access control
- **Authentication Token Management**: Secure token storage and refresh
- **Data Isolation**: User data completely isolated per account
- **Offline Security**: Local data encryption and secure caching

### 16. Privacy Protection
**Description**: Privacy-first design with minimal data collection.

**Privacy Features**:
- Local-first data storage approach
- User-controlled data synchronization
- No unnecessary data collection
- User-initiated account deletion support
- Transparent data usage policies

## Technical Capabilities

### 17. Cross-Platform Support
**Description**: Full Flutter cross-platform implementation.

**Supported Platforms**:
- iOS (native iOS support)
- Android (native Android support) 
- Web (Progressive Web App capabilities)
- macOS (desktop support)
- Windows (desktop support)
- Linux (desktop support)

### 18. Testing Infrastructure
**Description**: Comprehensive testing framework for reliability.

**Testing Capabilities**:
- Unit tests for core business logic
- Widget tests for UI components
- Integration tests for end-to-end workflows
- Mock services for isolated testing
- Firebase testing with mock implementations

**Testing Structure**:
```
test/
├── helpers/          # Test utilities and helpers
├── mocks/           # Mock implementations
├── providers/       # Provider testing
├── services/        # Service layer testing
├── theme/           # Theme system testing
└── widgets/         # Widget testing
```

### 19. Development & Build Tools
**Description**: Professional development workflow and tooling.

**Development Features**:
- **Linting**: Flutter Lints for code quality
- **Analysis**: Static code analysis with custom rules
- **Debug Tools**: Development-mode auto-login and debugging features
- **Screenshot Testing**: Automated screenshot generation for app store
- **Fastlane Integration**: Automated deployment and testing workflows

### 20. Performance Optimizations
**Description**: Performance-focused implementation for smooth user experience.

**Current Optimizations**:
- **Lazy Loading**: Efficient data loading strategies
- **Provider Pattern**: Optimized state management with Riverpod
- **Cache Management**: Intelligent caching with size limits
- **Timer Management**: Efficient timer usage for real-time updates
- **Memory Management**: Proper disposal of resources and controllers

## Firebase Integration

### 21. Cloud Infrastructure
**Description**: Robust cloud backend powered by Firebase.

**Firebase Services**:
- **Authentication**: User authentication and account management
- **Firestore**: Real-time database with offline persistence
- **Cloud Functions**: Server-side logic execution
- **Security Rules**: Data access control and validation

**Firestore Configuration**:
- Offline persistence enabled
- Unlimited cache size for optimal offline experience
- Real-time synchronization capabilities
- Automatic conflict resolution

## Summary

AshTrail represents a mature, feature-rich cannabis consumption tracking application with:

- **23+ Core Features** spanning user management, data tracking, analytics, and advanced modeling
- **Clean Architecture Foundation** with domain-driven design principles
- **Enterprise-Grade Security** with encrypted storage and secure authentication
- **Cross-Platform Support** for all major platforms
- **Offline-First Design** with intelligent synchronization
- **Advanced THC Modeling** using pharmacokinetic principles
- **Comprehensive Testing** infrastructure for reliability
- **Professional Development** workflow and tooling

The application successfully combines scientific accuracy in THC modeling with user-friendly design and robust technical architecture, providing users with a comprehensive tool for cannabis consumption tracking and analysis.