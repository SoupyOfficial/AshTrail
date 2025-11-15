# AshTrail Technical Architecture Documentation

## Overview
This document provides comprehensive technical architecture documentation for AshTrail, including current implementation analysis, clean architecture recommendations, and strategic technical decisions for the redesign.

## Table of Contents
1. [Current Architecture Analysis](#current-architecture-analysis)
2. [Clean Architecture Implementation](#clean-architecture-implementation)
3. [State Management Strategy](#state-management-strategy)
4. [Data Layer Architecture](#data-layer-architecture)
5. [Dependency Injection](#dependency-injection)
6. [Error Handling Strategy](#error-handling-strategy)
7. [Testing Architecture](#testing-architecture)
8. [Performance Architecture](#performance-architecture)
9. [Security Architecture](#security-architecture)
10. [Recommended Implementation Plan](#recommended-implementation-plan)

## Current Architecture Analysis

### Existing Structure Assessment

#### Strengths
1. **Partial Domain Layer**: Already has `lib/domain/` with models and use cases
2. **Service Layer**: Well-defined services with clear responsibilities
3. **Provider Pattern**: Consistent use of Riverpod for state management
4. **Model Separation**: Clear data models with proper serialization
5. **Interface Definition**: Some service interfaces already defined

#### Areas for Improvement
1. **Inconsistent Layer Separation**: Domain logic mixed with presentation layer
2. **Missing Repository Abstractions**: Direct service calls from providers
3. **Tightly Coupled Dependencies**: Hard dependencies instead of injected abstractions
4. **Incomplete Error Handling**: Inconsistent error handling across layers
5. **Mixed Responsibilities**: Some services handling multiple concerns

### Current Layer Structure
```
lib/
├── domain/           # Partial domain implementation
│   ├── models/      # Domain models
│   ├── use_cases/   # Business logic
│   └── adapters/    # Interface adapters
├── services/        # Service layer (infrastructure)
├── providers/       # State management (presentation)
├── screens/         # UI screens (presentation)
├── widgets/         # UI components (presentation)
├── models/          # Data models (should be in domain)
└── utils/           # Utilities and helpers
```

## Clean Architecture Implementation

### Recommended Layer Structure

```
lib/
├── core/                    # Core framework components
│   ├── error/              # Error handling framework
│   ├── network/            # Network utilities
│   ├── usecase/            # Base use case definitions
│   └── di/                 # Dependency injection
├── domain/                 # Enterprise business rules
│   ├── entities/           # Core business entities
│   ├── repositories/       # Repository interfaces
│   ├── usecases/          # Application business rules
│   └── failures/          # Domain-specific failures
├── data/                   # Data access layer
│   ├── repositories/      # Repository implementations
│   ├── datasources/       # Local and remote data sources
│   ├── models/            # Data models with serialization
│   └── mappers/           # Entity-Model mappers
└── presentation/           # Presentation layer
    ├── providers/         # State management
    ├── screens/           # UI screens
    ├── widgets/           # UI components
    └── utils/             # Presentation utilities
```

### 1. Domain Layer Design

#### Entities (Core Business Objects)
```dart
// lib/domain/entities/log_entity.dart
class LogEntity {
  final String? id;
  final DateTime timestamp;
  final Duration duration;
  final MoodRating moodRating;
  final PhysicalRating physicalRating;
  final PotencyRating potencyRating;
  final String? notes;
  final List<ReasonEntity> reasons;

  const LogEntity({
    this.id,
    required this.timestamp,
    required this.duration,
    required this.moodRating,
    required this.physicalRating,
    required this.potencyRating,
    this.notes,
    required this.reasons,
  });
}

// Value objects for type safety
class MoodRating {
  final int value;
  
  const MoodRating._(this.value);
  
  factory MoodRating.fromInt(int value) {
    if (value < 1 || value > 10) {
      throw ArgumentError('Mood rating must be between 1 and 10');
    }
    return MoodRating._(value);
  }
}
```

#### Repository Interfaces
```dart
// lib/domain/repositories/log_repository.dart
abstract class LogRepository {
  Future<Either<Failure, List<LogEntity>>> getAllLogs();
  Future<Either<Failure, LogEntity>> getLogById(String id);
  Future<Either<Failure, String>> createLog(LogEntity log);
  Future<Either<Failure, Unit>> updateLog(LogEntity log);
  Future<Either<Failure, Unit>> deleteLog(String id);
  Stream<Either<Failure, List<LogEntity>>> watchLogs();
}
```

#### Use Cases
```dart
// lib/domain/usecases/create_log_usecase.dart
class CreateLogUseCase implements UseCase<String, CreateLogParams> {
  final LogRepository repository;
  final THCCalculationUseCase thcCalculator;
  
  const CreateLogUseCase({
    required this.repository,
    required this.thcCalculator,
  });

  @override
  Future<Either<Failure, String>> call(CreateLogParams params) async {
    // Business rule validation
    if (params.log.duration.inSeconds < 1) {
      return Left(ValidationFailure('Duration must be at least 1 second'));
    }
    
    // Apply business logic
    final enhancedLog = await _enhanceLogWithTHCData(params.log);
    
    // Delegate to repository
    return await repository.createLog(enhancedLog);
  }
  
  Future<LogEntity> _enhanceLogWithTHCData(LogEntity log) async {
    // Business logic for THC calculation integration
    // ...
  }
}
```

### 2. Data Layer Design

#### Repository Implementation
```dart
// lib/data/repositories/log_repository_impl.dart
class LogRepositoryImpl implements LogRepository {
  final LogRemoteDataSource remoteDataSource;
  final LogLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final LogMapper mapper;

  const LogRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.mapper,
  });

  @override
  Future<Either<Failure, List<LogEntity>>> getAllLogs() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource.getAllLogs();
        await localDataSource.cacheLogs(remoteData);
        return Right(remoteData.map(mapper.toEntity).toList());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localData = await localDataSource.getCachedLogs();
        return Right(localData.map(mapper.toEntity).toList());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

#### Data Sources
```dart
// lib/data/datasources/log_remote_datasource.dart
abstract class LogRemoteDataSource {
  Future<List<LogModel>> getAllLogs();
  Future<LogModel> getLogById(String id);
  Future<String> createLog(LogModel log);
  Future<void> updateLog(LogModel log);
  Future<void> deleteLog(String id);
}

// lib/data/datasources/log_remote_datasource_impl.dart
class LogRemoteDataSourceImpl implements LogRemoteDataSource {
  final FirebaseFirestore firestore;
  final String userId;

  const LogRemoteDataSourceImpl({
    required this.firestore,
    required this.userId,
  });

  @override
  Future<List<LogModel>> getAllLogs() async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => LogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException();
    }
  }
}
```

### 3. Presentation Layer Design

#### Provider Architecture with Riverpod
```dart
// lib/presentation/providers/log_providers.dart

// State classes
@freezed
class LogState with _$LogState {
  const factory LogState.loading() = _Loading;
  const factory LogState.loaded(List<LogEntity> logs) = _Loaded;
  const factory LogState.error(String message) = _Error;
}

// Provider implementation
class LogNotifier extends StateNotifier<LogState> {
  final GetAllLogsUseCase getAllLogsUseCase;
  final CreateLogUseCase createLogUseCase;
  final DeleteLogUseCase deleteLogUseCase;

  LogNotifier({
    required this.getAllLogsUseCase,
    required this.createLogUseCase,
    required this.deleteLogUseCase,
  }) : super(const LogState.loading());

  Future<void> loadLogs() async {
    state = const LogState.loading();
    
    final result = await getAllLogsUseCase(NoParams());
    
    result.fold(
      (failure) => state = LogState.error(_mapFailureToMessage(failure)),
      (logs) => state = LogState.loaded(logs),
    );
  }

  Future<void> createLog(LogEntity log) async {
    final result = await createLogUseCase(CreateLogParams(log: log));
    
    result.fold(
      (failure) => state = LogState.error(_mapFailureToMessage(failure)),
      (_) => loadLogs(), // Refresh logs after creation
    );
  }
}

// Provider definition
final logProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier(
    getAllLogsUseCase: ref.read(getAllLogsUseCaseProvider),
    createLogUseCase: ref.read(createLogUseCaseProvider),
    deleteLogUseCase: ref.read(deleteLogUseCaseProvider),
  );
});
```

## State Management Strategy

### Riverpod Architecture

#### Provider Categories
1. **Repository Providers**: Dependency injection for repositories
2. **UseCase Providers**: Business logic providers
3. **State Providers**: UI state management
4. **Configuration Providers**: App configuration and settings

#### State Management Patterns
```dart
// lib/presentation/providers/providers.dart

// Repository providers
final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepositoryImpl(
    remoteDataSource: ref.read(logRemoteDataSourceProvider),
    localDataSource: ref.read(logLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
    mapper: ref.read(logMapperProvider),
  );
});

// UseCase providers
final getAllLogsUseCaseProvider = Provider<GetAllLogsUseCase>((ref) {
  return GetAllLogsUseCase(repository: ref.read(logRepositoryProvider));
});

// State providers
final logProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier(
    getAllLogsUseCase: ref.read(getAllLogsUseCaseProvider),
    createLogUseCase: ref.read(createLogUseCaseProvider),
    deleteLogUseCase: ref.read(deleteLogUseCaseProvider),
  );
});

// Stream providers for real-time data
final logStreamProvider = StreamProvider<List<LogEntity>>((ref) {
  final repository = ref.read(logRepositoryProvider);
  return repository.watchLogs().map(
    (either) => either.fold(
      (failure) => throw Exception(failure.toString()),
      (logs) => logs,
    ),
  );
});
```

## Data Layer Architecture

### Repository Pattern Implementation

#### Interface Definition
```dart
// lib/domain/repositories/repository.dart
abstract class Repository<T, ID> {
  Future<Either<Failure, List<T>>> getAll();
  Future<Either<Failure, T>> getById(ID id);
  Future<Either<Failure, ID>> create(T entity);
  Future<Either<Failure, Unit>> update(T entity);
  Future<Either<Failure, Unit>> delete(ID id);
  Stream<Either<Failure, List<T>>> watch();
}
```

#### Generic Repository Implementation
```dart
// lib/data/repositories/base_repository.dart
abstract class BaseRepository<Entity, Model, ID> {
  final RemoteDataSource<Model, ID> remoteDataSource;
  final LocalDataSource<Model, ID> localDataSource;
  final NetworkInfo networkInfo;
  final Mapper<Entity, Model> mapper;

  const BaseRepository({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.mapper,
  });

  Future<Either<Failure, List<Entity>>> getAll() async {
    return await _executeWithFallback(
      remoteCall: () => remoteDataSource.getAll(),
      localCall: () => localDataSource.getCached(),
      cacheOperation: (data) => localDataSource.cache(data),
    );
  }

  Future<Either<Failure, List<Entity>>> _executeWithFallback<T>({
    required Future<List<Model>> Function() remoteCall,
    required Future<List<Model>> Function() localCall,
    required Future<void> Function(List<Model>) cacheOperation,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteCall();
        await cacheOperation(remoteData);
        return Right(remoteData.map(mapper.toEntity).toList());
      } on ServerException {
        return Left(ServerFailure());
      } catch (e) {
        return Left(UnknownFailure());
      }
    } else {
      try {
        final localData = await localCall();
        return Right(localData.map(mapper.toEntity).toList());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

### Data Source Architecture

#### Local Data Source Pattern
```dart
// lib/data/datasources/local/log_local_datasource.dart
abstract class LogLocalDataSource extends LocalDataSource<LogModel, String> {
  Future<List<LogModel>> getLogsByDateRange(DateTime start, DateTime end);
  Future<void> clearOldLogs(DateTime cutoffDate);
}

class LogLocalDataSourceImpl implements LogLocalDataSource {
  final CacheService cacheService;
  final String cacheKey = 'user_logs';

  const LogLocalDataSourceImpl({required this.cacheService});

  @override
  Future<List<LogModel>> getCached() async {
    try {
      final jsonString = await cacheService.getString(cacheKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => LogModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> cache(List<LogModel> logs) async {
    try {
      final jsonString = json.encode(logs.map((log) => log.toJson()).toList());
      await cacheService.setString(cacheKey, jsonString);
    } catch (e) {
      throw CacheException();
    }
  }
}
```

## Dependency Injection

### Service Locator Pattern with Riverpod

#### Core DI Structure
```dart
// lib/core/di/injection_container.dart
class InjectionContainer {
  static void init() {
    // Core services
    _registerCore();
    // Data sources
    _registerDataSources();
    // Repositories
    _registerRepositories();
    // Use cases
    _registerUseCases();
  }

  static void _registerCore() {
    // Network
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
    
    // External services
    sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
    sl.registerLazySingleton<SharedPreferences>(() async => await SharedPreferences.getInstance());
  }
}
```

#### Riverpod DI Pattern
```dart
// lib/core/di/providers.dart

// Core providers
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfoImpl());
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Data source providers
final logRemoteDataSourceProvider = Provider<LogRemoteDataSource>((ref) {
  return LogRemoteDataSourceImpl(
    firestore: ref.read(firestoreProvider),
    userId: ref.read(currentUserProvider)?.uid ?? '',
  );
});

final logLocalDataSourceProvider = Provider<LogLocalDataSource>((ref) {
  return LogLocalDataSourceImpl(
    cacheService: ref.read(cacheServiceProvider),
  );
});

// Repository providers
final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepositoryImpl(
    remoteDataSource: ref.read(logRemoteDataSourceProvider),
    localDataSource: ref.read(logLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
    mapper: LogMapper(),
  );
});
```

## Error Handling Strategy

### Failure Hierarchy
```dart
// lib/core/error/failures.dart
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
  const ValidationFailure(String message) : super(message);
}
```

### Exception Handling
```dart
// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server exception occurred']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception occurred']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network exception occurred']);
}
```

### Error Handling in Use Cases
```dart
// lib/domain/usecases/base_usecase.dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}

// Implementation with error handling
class GetAllLogsUseCase implements UseCase<List<LogEntity>, NoParams> {
  final LogRepository repository;
  
  const GetAllLogsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<LogEntity>>> call(NoParams params) async {
    try {
      return await repository.getAllLogs();
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
```

## Testing Architecture

### Testing Strategy
```dart
// test/core/test_helpers.dart
class TestHelpers {
  static MockLogRepository createMockLogRepository() => MockLogRepository();
  static MockNetworkInfo createMockNetworkInfo() => MockNetworkInfo();
  
  static LogEntity createTestLogEntity({
    String? id,
    DateTime? timestamp,
  }) {
    return LogEntity(
      id: id ?? 'test-id',
      timestamp: timestamp ?? DateTime.now(),
      duration: const Duration(minutes: 5),
      moodRating: MoodRating.fromInt(7),
      physicalRating: PhysicalRating.fromInt(6),
      potencyRating: PotencyRating.fromInt(5),
      reasons: [ReasonEntity.recreational],
    );
  }
}
```

### Use Case Testing
```dart
// test/domain/usecases/get_all_logs_usecase_test.dart
void main() {
  late GetAllLogsUseCase useCase;
  late MockLogRepository mockRepository;

  setUp(() {
    mockRepository = MockLogRepository();
    useCase = GetAllLogsUseCase(repository: mockRepository);
  });

  group('GetAllLogsUseCase', () {
    final testLogs = [
      TestHelpers.createTestLogEntity(id: '1'),
      TestHelpers.createTestLogEntity(id: '2'),
    ];

    test('should return logs when repository call is successful', () async {
      // arrange
      when(() => mockRepository.getAllLogs())
          .thenAnswer((_) async => Right(testLogs));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, Right(testLogs));
      verify(() => mockRepository.getAllLogs()).called(1);
    });

    test('should return failure when repository call fails', () async {
      // arrange
      when(() => mockRepository.getAllLogs())
          .thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, Left(ServerFailure()));
      verify(() => mockRepository.getAllLogs()).called(1);
    });
  });
}
```

## Performance Architecture

### Performance Optimization Strategies

#### 1. Lazy Loading and Pagination
```dart
// lib/domain/usecases/get_paginated_logs_usecase.dart
class GetPaginatedLogsUseCase implements UseCase<PaginatedResult<LogEntity>, PaginationParams> {
  final LogRepository repository;
  
  const GetPaginatedLogsUseCase({required this.repository});

  @override
  Future<Either<Failure, PaginatedResult<LogEntity>>> call(PaginationParams params) async {
    return await repository.getPaginatedLogs(
      page: params.page,
      pageSize: params.pageSize,
      filters: params.filters,
    );
  }
}
```

#### 2. Caching Strategy
```dart
// lib/data/cache/cache_manager.dart
class CacheManager {
  final Map<String, CacheItem> _cache = {};
  final Duration defaultTTL = const Duration(minutes: 30);

  T? get<T>(String key) {
    final item = _cache[key];
    if (item != null && !item.isExpired) {
      return item.data as T;
    }
    _cache.remove(key);
    return null;
  }

  void set<T>(String key, T data, {Duration? ttl}) {
    _cache[key] = CacheItem(
      data: data,
      expiresAt: DateTime.now().add(ttl ?? defaultTTL),
    );
  }
}
```

#### 3. Provider Optimization
```dart
// lib/presentation/providers/optimized_providers.dart

// Family providers for parameter-based caching
final logByIdProvider = Provider.family<Future<LogEntity?>, String>((ref, id) async {
  final repository = ref.read(logRepositoryProvider);
  final result = await repository.getLogById(id);
  return result.fold((failure) => null, (log) => log);
});

// Auto-dispose providers for memory management
final temporaryLogProvider = StateNotifierProvider.autoDispose<TempLogNotifier, TempLogState>((ref) {
  return TempLogNotifier();
});
```

## Security Architecture

### Security Implementation Strategy

#### 1. Authentication Security
```dart
// lib/core/security/auth_security.dart
class AuthSecurity {
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  static Future<bool> validateLoginAttempt(String userId) async {
    final attempts = await _getLoginAttempts(userId);
    return attempts < maxLoginAttempts;
  }

  static Future<void> recordFailedLogin(String userId) async {
    // Record failed login attempt
    // Implement lockout mechanism
  }
}
```

#### 2. Data Encryption
```dart
// lib/core/security/encryption_service.dart
class EncryptionService {
  final FlutterSecureStorage _secureStorage;
  
  const EncryptionService({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  Future<void> storeSecurely(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> retrieveSecurely(String key) async {
    return await _secureStorage.read(key: key);
  }
}
```

## Recommended Implementation Plan

### Phase 1: Core Architecture Setup (Weeks 1-2)
1. **Setup Clean Architecture Structure**
   - Create proper folder structure
   - Implement base classes and interfaces
   - Setup dependency injection framework

2. **Implement Core Layer**
   - Error handling framework
   - Base use case implementation
   - Network utilities
   - Common types and constants

### Phase 2: Domain Layer Implementation (Weeks 3-4)
1. **Entities Migration**
   - Convert existing models to entities
   - Implement value objects for type safety
   - Create domain-specific business rules

2. **Repository Interfaces**
   - Define repository abstractions
   - Create use case interfaces
   - Implement business logic validation

### Phase 3: Data Layer Refactoring (Weeks 5-6)
1. **Repository Implementation**
   - Implement repository pattern
   - Create data source abstractions
   - Implement caching strategy

2. **Data Sources**
   - Refactor existing services to data sources
   - Implement offline-first strategy
   - Add comprehensive error handling

### Phase 4: Presentation Layer Optimization (Weeks 7-8)
1. **Provider Refactoring**
   - Implement state management improvements
   - Add performance optimizations
   - Improve error handling in UI

2. **UI Component Enhancement**
   - Implement responsive design improvements
   - Add accessibility features
   - Optimize for different screen sizes

### Phase 5: Testing and Documentation (Weeks 9-10)
1. **Comprehensive Testing**
   - Unit tests for all use cases
   - Integration tests for critical flows
   - Widget tests for UI components

2. **Documentation**
   - API documentation
   - Architecture decision records
   - Developer onboarding guides

## Benefits of Recommended Architecture

### Maintainability
- **Clear Separation of Concerns**: Each layer has distinct responsibilities
- **Testable Code**: Easy to test with mock implementations
- **Modular Design**: Independent modules that can be developed separately

### Scalability
- **Easy Feature Addition**: New features follow established patterns
- **Performance Optimization**: Built-in caching and optimization strategies
- **Team Scalability**: Multiple developers can work on different layers

### Reliability
- **Comprehensive Error Handling**: Graceful failure handling at every layer
- **Offline Support**: Robust offline-first architecture
- **Data Consistency**: Consistent data management across the application

### Developer Experience
- **Clear Patterns**: Consistent architectural patterns throughout
- **Type Safety**: Strong typing with value objects and entities
- **Easy Debugging**: Clear error messages and logging throughout the stack

This architecture provides a solid foundation for the AshTrail redesign, ensuring maintainability, scalability, and reliability while preserving all existing functionality.