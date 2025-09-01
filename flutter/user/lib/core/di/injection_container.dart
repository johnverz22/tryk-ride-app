import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core services
import '../services/load_balancer_service.dart';
import '../services/message_queue_service.dart';
import '../config/api_config.dart';

// Features
import '../../features/user/data/datasources/user_local_datasource.dart';
import '../../features/user/data/datasources/user_remote_datasource.dart';
import '../../features/user/data/repositories/user_repository_impl.dart';
import '../../features/user/business/repositories/user_repository.dart';
import '../../features/user/business/usecases/get_user_usecase.dart';
import '../../features/user/business/usecases/login_usecase.dart';
import '../../features/user/business/usecases/update_user_usecase.dart';
import '../../features/user/business/usecases/logout_usecase.dart';
import '../../features/user/presentation/viewmodels/user_viewmodel.dart';

// Ride features
import '../../features/ride/presentation/viewmodels/ride_booking_viewmodel.dart';
import '../../features/ride/business/usecases/request_ride_usecase.dart';
import '../../features/ride/business/usecases/track_ride_usecase.dart';
import '../../features/ride/business/usecases/get_nearby_drivers_usecase.dart';

final sl = GetIt.instance;

Future<void> init({
  bool enableLoadBalancer = false,
  bool enableMessageQueue = false,
  LoadBalancerStrategy loadBalancerStrategy = LoadBalancerStrategy.roundRobin,
  String messageQueueType = 'redis',
}) async {
  //! Core Services (Optional - Plug and Play)
  
  // Load Balancer (Optional)
  if (enableLoadBalancer) {
    sl.registerLazySingleton<LoadBalancerService>(
      () {
        final loadBalancer = LoadBalancerService(strategy: loadBalancerStrategy);
        
        // Add your server endpoints
        loadBalancer.addServers([
          ServerEndpoint(url: 'https://api1.yourapp.com', weight: 3, region: 'us-east'),
          ServerEndpoint(url: 'https://api2.yourapp.com', weight: 2, region: 'us-west'),
          ServerEndpoint(url: 'https://api3.yourapp.com', weight: 1, region: 'eu-west'),
        ]);
        
        // Start health checks
        loadBalancer.performHealthChecks();
        
        return loadBalancer;
      },
    );
  }

  // Message Queue (Optional)
  if (enableMessageQueue) {
    sl.registerLazySingleton<MessageQueueService>(
      () => MessageQueueFactory.create(messageQueueType),
    );
  }

  //! Features - User
  // ViewModels
  sl.registerFactory(
    () => UserViewModel(
      getUserUseCase: sl(),
      updateUserUseCase: sl(),
      loginUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Ride ViewModels
  sl.registerFactory(
    () => RideBookingViewModel(
      requestRideUseCase: sl(),
      trackRideUseCase: sl(),
      getNearbyDriversUseCase: sl(),
      messageQueue: enableMessageQueue ? sl<MessageQueueService>() : null,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUserUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      client: sl(),
      loadBalancer: enableLoadBalancer ? sl<LoadBalancerService>() : null,
      messageQueue: enableMessageQueue ? sl<MessageQueueService>() : null,
    ),
  );

  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(secureStorage: sl()),
  );

  //! Core
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}