# AshTrail Technical Architecture Documentation

## Overview
This document outlines the current technical architecture of AshTrail and provides recommendations for implementing a robust clean architecture for the redesign.

## Current Architecture Analysis

### 1. Project Structure Overview
```
lib/
├── domain/                 # Partial clean architecture implementation
│   ├── adapters/          # Data transformation adapters
│   ├── models/            # Domain models
│   └── use_cases/         # Business logic use cases
├── models/                # Data models (legacy location)
├── providers/             # State management (Riverpod + Provider)
├── services/              # Business services layer
│   └── interfaces/        # Service abstractions
├── screens/               # UI screens
├── widgets/               # Reusable UI components
├── theme/                 # Theme management
└── utils/                 # Utility functions
```

### 2. Current State Management
- **Mixed Approach**: Uses both Riverpod and Provider
- **Provider Usage**: Theme management and some legacy state
- **Riverpod Usage**: Modern state management for new features
- **State Distribution**: State scattered across providers and services

### 3. Data Flow Architecture
```
UI Layer (Screens/Widgets)
    ↕
Provider/Riverpod Layer
    ↕
Services Layer
    ↕
Repository Layer (Log Repository)
    ↕
Data Sources (Firebase, Cache)
```

## Recommended Clean Architecture Implementation

### 1. Proposed Directory Structure
```
lib/
├── core/                           # Core utilities and configurations
│   ├── constants/                  # App constants
│   ├── error/                      # Error handling
│   ├── network/                    # Network utilities
│   ├── platform/                   # Platform-specific code
│   └── utils/                      # Shared utilities
├── features/                       # Feature-based organization
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/        # Remote and local data sources
│   │   │   ├── models/             # Data models with JSON serialization
│   │   │   └── repositories/       # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/           # Business entities
│   │   │   ├── repositories/       # Repository abstractions
│   │   │   └── usecases/           # Business logic use cases
│   │   └── presentation/
│   │       ├── providers/          # Riverpod providers
│   │       ├── pages/              # UI pages
│   │       └── widgets/            # Feature-specific widgets
│   ├── logging/                    # Smoke log feature
│   ├── analytics/                  # THC analytics feature
│   ├── sync/                       # Data synchronization feature
│   └── settings/                   # Settings and preferences
├── shared/                         # Shared components across features
│   ├── data/                       # Shared data components
│   ├── domain/                     # Shared domain components
│   └── presentation/               # Shared UI components
└── app/                           # App-level configuration
    ├── app.dart                   # Main app widget
    ├── injection_container.dart   # Dependency injection setup
    └── routes.dart                # App routing
```

### 2. Clean Architecture Layers

#### 2.1 Domain Layer (Business Logic)
```dart
// Entities - Core business objects
class LogEntry {
  final String id;
  final DateTime timestamp;
  final Duration duration;
  final MoodRating mood;
  final PhysicalRating physical;
  final PotencyRating potency;
  final String? notes;
  final List<String> reasons;
}

// Repository Abstractions
abstract class LogRepository {
  Future<Either<Failure, List<LogEntry>>> getLogs();
  Future<Either<Failure, void>> createLog(LogEntry log);
  Future<Either<Failure, void>> updateLog(LogEntry log);
  Future<Either<Failure, void>> deleteLog(String id);
}

// Use Cases - Single responsibility business logic
class CreateLogUseCase {
  final LogRepository repository;
  
  CreateLogUseCase(this.repository);
  
  Future<Either<Failure, void>> call(CreateLogParams params) async {
    final log = LogEntry(/* ... */);
    return await repository.createLog(log);
  }
}
```

#### 2.2 Data Layer (External Concerns)
```dart
// Data Models - For serialization/API
class LogModel extends LogEntry {
  LogModel({/* ... */}) : super(/* ... */);
  
  factory LogModel.fromJson(Map<String, dynamic> json) => /* ... */;
  Map<String, dynamic> toJson() => /* ... */;
  
  factory LogModel.fromEntity(LogEntry entity) => /* ... */;
  LogEntry toEntity() => /* ... */;
}

// Data Sources
abstract class LogRemoteDataSource {
  Future<List<LogModel>> getLogs(String userId);
  Future<void> createLog(LogModel log);
}

class LogFirebaseDataSource implements LogRemoteDataSource {
  final FirebaseFirestore firestore;
  
  LogFirebaseDataSource(this.firestore);
  
  @override
  Future<List<LogModel>> getLogs(String userId) async {
    // Firebase implementation
  }
}

// Repository Implementation
class LogRepositoryImpl implements LogRepository {
  final LogRemoteDataSource remoteDataSource;
  final LogLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  LogRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<LogEntry>>> getLogs() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLogs = await remoteDataSource.getLogs(userId);
        await localDataSource.cacheLogs(remoteLogs);
        return Right(remoteLogs.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localLogs = await localDataSource.getLastLogs();
        return Right(localLogs.map((model) => model.toEntity()).toList());
      } catch (e) {
        return Left(CacheFailure());
      }
    }
  }
}
```

#### 2.3 Presentation Layer (UI)
```dart
// Riverpod Providers
final logUseCasesProvider = Provider<LogUseCases>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return LogUseCases(
    createLog: CreateLogUseCase(repository),
    getLogs: GetLogsUseCase(repository),
    updateLog: UpdateLogUseCase(repository),
    deleteLog: DeleteLogUseCase(repository),
  );
});

final logStateProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  final useCases = ref.watch(logUseCasesProvider);
  return LogNotifier(useCases);
});

// State Management with Riverpod
class LogNotifier extends StateNotifier<LogState> {
  final LogUseCases _logUseCases;
  
  LogNotifier(this._logUseCases) : super(LogInitial());
  
  Future<void> createLog(CreateLogParams params) async {
    state = LogLoading();
    final result = await _logUseCases.createLog(params);
    result.fold(
      (failure) => state = LogError(failure.message),
      (success) => state = LogCreated(),
    );
  }
}

// UI Components
class LogListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logStateProvider);
    
    return Scaffold(
      body: logState.when(
        loading: () => CircularProgressIndicator(),
        loaded: (logs) => LogList(logs: logs),
        error: (message) => ErrorWidget(message),
      ),
    );
  }
}
```

## 3. State Management Strategy

### 3.1 Recommended Approach: Pure Riverpod
- **Migration Plan**: Gradually migrate from Provider to Riverpod
- **Provider Types**:
  - `Provider`: For dependency injection
  - `StateNotifierProvider`: For complex state management
  - `FutureProvider`: For async operations
  - `StreamProvider`: For real-time data

### 3.2 State Organization
```dart
// Feature-based provider organization
// authentication/presentation/providers/auth_providers.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) => /* ... */);
final authUseCasesProvider = Provider<AuthUseCases>((ref) => /* ... */);
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => /* ... */);

// logging/presentation/providers/log_providers.dart
final logRepositoryProvider = Provider<LogRepository>((ref) => /* ... */);
final logUseCasesProvider = Provider<LogUseCases>((ref) => /* ... */);
final logStateProvider = StateNotifierProvider<LogNotifier, LogState>((ref) => /* ... */);
```

## 4. Dependency Injection Implementation

### 4.1 Service Locator Pattern with Riverpod
```dart
// injection_container.dart
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Authentication
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ));
  
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  
  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}

// Using with Riverpod
final authRepositoryProvider = Provider<AuthRepository>((ref) => sl<AuthRepository>());
```

### 4.2 Pure Riverpod Approach (Recommended)
```dart
// Core providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl());

// Data source providers
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthFirebaseDataSource(ref.watch(firebaseAuthProvider));
});

// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
```

## 5. Error Handling Strategy

### 5.1 Failure Classes
```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error occurred']) : super(message);
}
```

### 5.2 Error Handling in Use Cases
```dart
class CreateLogUseCase {
  final LogRepository repository;
  
  CreateLogUseCase(this.repository);
  
  Future<Either<Failure, void>> call(CreateLogParams params) async {
    // Validation
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }
    
    try {
      final log = LogEntry.fromParams(params);
      return await repository.createLog(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  String? _validateParams(CreateLogParams params) {
    if (params.timestamp.isAfter(DateTime.now())) {
      return 'Timestamp cannot be in the future';
    }
    if (params.duration.isNegative) {
      return 'Duration cannot be negative';
    }
    return null;
  }
}
```

## 6. Data Layer Architecture

### 6.1 Repository Pattern Implementation
```dart
// Abstract repository
abstract class LogRepository {
  Future<Either<Failure, List<LogEntry>>> getLogs();
  Future<Either<Failure, LogEntry>> getLogById(String id);
  Future<Either<Failure, void>> createLog(LogEntry log);
  Future<Either<Failure, void>> updateLog(LogEntry log);
  Future<Either<Failure, void>> deleteLog(String id);
  Stream<Either<Failure, List<LogEntry>>> watchLogs();
}

// Repository implementation with caching strategy
class LogRepositoryImpl implements LogRepository {
  final LogRemoteDataSource remoteDataSource;
  final LogLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  LogRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<LogEntry>>> getLogs() async {
    if (await networkInfo.isConnected) {
      return await _getLogsFromRemote();
    } else {
      return await _getLogsFromLocal();
    }
  }
  
  Future<Either<Failure, List<LogEntry>>> _getLogsFromRemote() async {
    try {
      final remoteLogs = await remoteDataSource.getLogs();
      await localDataSource.cacheLogs(remoteLogs);
      return Right(remoteLogs.map((model) => model.toEntity()).toList());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
  
  Future<Either<Failure, List<LogEntry>>> _getLogsFromLocal() async {
    try {
      final localLogs = await localDataSource.getLastLogs();
      return Right(localLogs.map((model) => model.toEntity()).toList());
    } on CacheException {
      return Left(CacheFailure());
    }
  }
}
```

### 6.2 Data Source Architecture
```dart
// Remote data source
abstract class LogRemoteDataSource {
  Future<List<LogModel>> getLogs();
  Future<LogModel> getLogById(String id);
  Future<void> createLog(LogModel log);
  Future<void> updateLog(LogModel log);
  Future<void> deleteLog(String id);
  Stream<List<LogModel>> watchLogs();
}

class LogFirebaseDataSource implements LogRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  
  LogFirebaseDataSource({
    required this.firestore,
    required this.auth,
  });
  
  @override
  Future<List<LogModel>> getLogs() async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) throw ServerException();
      
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => LogModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw ServerException();
    }
  }
}

// Local data source
abstract class LogLocalDataSource {
  Future<List<LogModel>> getLastLogs();
  Future<LogModel> getLogById(String id);
  Future<void> cacheLogs(List<LogModel> logs);
  Future<void> cacheLog(LogModel log);
  Future<void> deleteLog(String id);
}

class LogHiveDataSource implements LogLocalDataSource {
  final Box<LogModel> logBox;
  
  LogHiveDataSource(this.logBox);
  
  @override
  Future<List<LogModel>> getLastLogs() async {
    return logBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  @override
  Future<void> cacheLogs(List<LogModel> logs) async {
    await logBox.clear();
    for (final log in logs) {
      await logBox.put(log.id, log);
    }
  }
}
```

## 7. Performance Optimization Strategies

### 7.1 State Management Optimization
- **Provider Scoping**: Use specific providers for specific data
- **State Normalization**: Avoid deep nested objects in state
- **Selective Rebuilds**: Use `select` to listen to specific state parts
- **Memoization**: Cache expensive computations

### 7.2 Data Layer Optimization
- **Lazy Loading**: Load data on demand
- **Pagination**: Implement pagination for large datasets
- **Caching Strategy**: Smart cache invalidation
- **Background Sync**: Sync data in background

### 7.3 UI Optimization
- **Widget Rebuilding**: Minimize unnecessary rebuilds
- **List Performance**: Use `ListView.builder` for large lists
- **Image Optimization**: Optimize image loading and caching
- **Navigation**: Implement efficient navigation patterns

## 8. Testing Strategy

### 8.1 Unit Testing
```dart
// Domain layer testing
group('CreateLogUseCase', () {
  late CreateLogUseCase useCase;
  late MockLogRepository mockRepository;
  
  setUp(() {
    mockRepository = MockLogRepository();
    useCase = CreateLogUseCase(mockRepository);
  });
  
  test('should create log successfully', () async {
    // Arrange
    when(mockRepository.createLog(any))
        .thenAnswer((_) async => Right(null));
    
    // Act
    final result = await useCase(CreateLogParams(/* ... */));
    
    // Assert
    expect(result, equals(Right(null)));
    verify(mockRepository.createLog(any));
  });
});
```

### 8.2 Widget Testing
```dart
// Presentation layer testing
group('LogListPage', () {
  testWidgets('should display logs when state is loaded', (tester) async {
    // Arrange
    final logs = [/* test logs */];
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logStateProvider.overrideWith((ref) => LogLoaded(logs)),
        ],
        child: MaterialApp(home: LogListPage()),
      ),
    );
    
    // Assert
    expect(find.byType(LogList), findsOneWidget);
    expect(find.text(logs.first.notes ?? ''), findsOneWidget);
  });
});
```

## 9. Migration Strategy

### 9.1 Phase 1: Core Infrastructure
1. Set up clean architecture folder structure
2. Implement core error handling
3. Set up dependency injection with Riverpod
4. Create base classes and interfaces

### 9.2 Phase 2: Feature Migration
1. Start with authentication feature
2. Migrate logging feature
3. Migrate analytics feature
4. Migrate settings feature

### 9.3 Phase 3: Optimization
1. Implement performance optimizations
2. Add comprehensive testing
3. Optimize state management
4. Refine error handling

---

*This architecture documentation provides a roadmap for implementing a robust, maintainable, and scalable architecture for the AshTrail redesign.*