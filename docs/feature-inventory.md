# AshTrail Feature Inventory

## Overview
This document provides a comprehensive inventory of all current features in the AshTrail (Smoke Log) application, serving as the foundation for the redesign planning.

## 1. User Management & Authentication

### 1.1 Multi-Account System
- **Firebase Authentication Integration**
  - Email/password authentication
  - Google Sign-In integration
  - Apple Sign-In support (iOS)
  - Auto-login for development mode

- **User Account Management**
  - Multiple user account support
  - User account switching functionality
  - Account-specific data isolation
  - User profile management

- **User Profile System**
  - Personal information storage (first name, last name, email)
  - Account creation and modification timestamps
  - Active/inactive account status tracking
  - User preference persistence

### 1.2 Security & Privacy
- **Secure Storage**
  - Flutter Secure Storage for sensitive data
  - Credential management service
  - Token-based authentication

- **Data Privacy**
  - User-specific data isolation
  - Secure credential handling
  - Privacy-focused data management

## 2. Log Entry System

### 2.1 Core Logging Features
- **Comprehensive Log Creation**
  - Timestamp tracking (automatic and manual)
  - Duration measurement in seconds
  - Mood rating scale (1-10)
  - Physical rating scale (1-10)
  - Potency rating system
  - Custom notes and observations
  - Categorized reason selection

- **Reason Categories**
  - Predefined reason options
  - Custom reason input capability
  - Multiple reason selection support
  - Reason option management

### 2.2 Log Management
- **CRUD Operations**
  - Create new log entries
  - View log history
  - Edit existing logs
  - Delete log entries

- **Log List Interface**
  - Chronological log display
  - Search and filter capabilities
  - Sort options
  - Detailed log view

## 3. THC Modeling & Analytics

### 3.1 Advanced THC Concentration Tracking
- **Sophisticated THC Model**
  - Demographic-based calculations (age, sex, body fat percentage)
  - Metabolic rate considerations (daily caloric burn)
  - Consumption method differentiation:
    - Joint (~1.5 mg/s base rate)
    - Bong (~2.0 mg/s base rate)
    - Vape (~2.5 mg/s base rate)
    - Dab (~5.0 mg/s base rate)

- **Absorption Modeling**
  - Diminishing absorption function for long inhales
  - Maximum absorption fraction (95%)
  - Time-based absorption rate constants
  - Perceived strength adjustments

- **Elimination Calculations**
  - Exponential elimination with demographic adjustments
  - Baseline half-life calculations (~1.5 hours)
  - Age-based elimination rate modifications
  - Sex-specific elimination adjustments
  - Body fat percentage impact
  - Metabolic rate considerations

### 3.2 Data Visualization
- **Chart System**
  - FL Chart integration for data visualization
  - Line chart widgets for trend analysis
  - Chart data processors for data transformation
  - Configurable chart settings

- **Analytics Features**
  - THC content tracking over time
  - Historical trend analysis
  - Log aggregation and statistics
  - Visual data representation

## 4. Synchronization & Offline Capabilities

### 4.1 Cloud Synchronization
- **Firebase Integration**
  - Firestore for data storage
  - Real-time synchronization
  - Conflict resolution strategies
  - Cross-device data consistency

- **Offline Support**
  - Local data caching
  - Offline-first architecture
  - Cache service implementation
  - Data persistence during connectivity loss

### 4.2 Data Management
- **Cache Service**
  - Local data storage
  - Cache size management (unlimited cache size)
  - Data retrieval optimization
  - Sync status tracking

- **Log Transfer System**
  - Data export capabilities
  - Log transfer between accounts
  - Backup and restore functionality

## 5. User Interface & Experience

### 5.1 Theme Customization
- **Theme System**
  - Light and dark mode support
  - Custom accent color selection
  - Theme preference persistence
  - Dynamic theme switching

- **UI Components**
  - Custom app bar with connectivity indicators
  - Rating sliders for user input
  - THC information displays
  - User account selector
  - Sync status indicators

### 5.2 Responsive Design
- **Cross-Platform Support**
  - Android native support
  - iOS native support
  - Web platform support
  - Desktop platforms (Linux, macOS, Windows)

- **Adaptive Layouts**
  - Screen size optimization
  - Platform-specific UI adaptations
  - Accessibility considerations

## 6. Settings & Preferences

### 6.1 User Preferences
- **Account Settings**
  - Personal information management
  - Account options configuration
  - Data management preferences

- **App Configuration**
  - Theme preferences
  - Sync settings
  - Notification preferences
  - Data backup options

### 6.2 Data Management
- **My Data Screen**
  - Data export functionality
  - Data deletion options
  - Privacy controls
  - Data usage statistics

## 7. Development & Testing Features

### 7.1 Development Tools
- **Debug Features**
  - Screenshot mode for testing
  - Coordinate finder for UI testing
  - Development auto-login
  - Debug logging

- **Testing Infrastructure**
  - Unit test framework
  - Widget testing
  - Integration testing
  - Mock services for testing

### 7.2 Build & Deployment
- **Multi-Platform Building**
  - Flutter framework integration
  - Platform-specific configurations
  - Asset management
  - App icon handling

## 8. Third-Party Integrations

### 8.1 External Services
- **Authentication Providers**
  - Google Sign-In
  - Apple Sign-In
  - Firebase Authentication

- **Data Storage**
  - Cloud Firestore
  - Local secure storage
  - Shared preferences

### 8.2 Dependencies
- **Core Libraries**
  - Riverpod for state management
  - Provider for additional state management
  - FL Chart for data visualization
  - Font Awesome for icons
  - Connectivity Plus for network status
  - HTTP for network requests

## Feature Completeness Assessment

### ✅ Well-Implemented Features
- Multi-account authentication system
- Comprehensive log entry system
- Advanced THC modeling
- Firebase synchronization
- Theme customization
- Offline capabilities

### ⚠️ Partially Implemented Features
- Clean architecture (domain layer exists but incomplete)
- Error handling (basic implementation)
- Data validation (minimal validation)
- User onboarding (basic implementation)

### ❌ Missing or Limited Features
- Advanced analytics and reporting
- Data export formats (limited options)
- Push notifications
- Social features
- Advanced search and filtering
- Data insights and recommendations
- Backup and restore automation
- Performance monitoring
- Comprehensive error reporting

---

*This inventory serves as the baseline for the AshTrail redesign, ensuring all current functionality is preserved while identifying opportunities for enhancement and architectural improvements.*