// lib/injection.dart
import 'package:flareline/core/network/graphql_client.dart';
import 'package:flareline/core/services/location_service.dart';
import 'package:flareline/core/services/openroute_service.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:flareline/core/services/session_service.dart';
import 'package:flareline/data/datasources/auth_remote_data_source.dart';
import 'package:flareline/data/repositories/auth_repo_impl.dart';
import 'package:flareline/domain/repositories/auth_repo.dart';
import 'package:flareline/domain/use_cases/login_use_case.dart';
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
import 'package:flareline/presentation/bloc/login/login_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flareline/data/datasources/geometre_remote_data_source.dart';
import 'package:flareline/data/repositories/geometre_repository_impl.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';
import 'package:flareline/domain/use_cases/geometre/get_pending_lands.dart';
import 'package:flareline/domain/use_cases/geometre/validate_land.dart';

final getIt = GetIt.instance;

void setupInjection() {

  getIt.registerLazySingleton(() => GraphQLService());
  // Core
  getIt.registerLazySingleton(() => Logger());
  getIt.registerLazySingleton(
      () => Dio()..options.baseUrl = 'http://localhost:5000');
  // Enregistrer le service OpenRouteService
  getIt.registerLazySingleton<OpenRouteService>(() => OpenRouteService(
        apiKey: '5b3ce3597851110001cf6248c25ce73e7fc44895be99f46b9e13afbd',
      ));

  // Services pour l'authentification
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  getIt.registerLazySingleton(() => SecureStorageService());
  getIt.registerLazySingleton(() => SessionService());

  // Data sources
getIt.registerLazySingleton<AuthRemoteDataSource>(
  () => AuthRemoteDataSourceImpl(
    graphQLService: getIt<GraphQLService>(),  // Injecter le service, pas le client
    secureStorage: getIt<SecureStorageService>(),
  ),
);
  // Enregistrer le service de localisation
  getIt.registerLazySingleton<LocationService>(() => LocationService(
        logger: getIt<Logger>(),
      ));

  // Data sources
  getIt.registerLazySingleton<GeometreRemoteDataSource>(
    () => GeometreRemoteDataSource(
      dio: getIt(),
      logger: getIt(),
      baseUrl: 'http://localhost:5000',
    ),
  );

  // Repositories
  getIt.registerLazySingleton<GeometreRepository>(
    () => GeometreRepositoryImpl(
      remoteDataSource: getIt(),
    ),
  );
  // Repositories pour l'authentification
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton(
    () => GetPendingLands(repository: getIt<GeometreRepository>()),
  );
  getIt.registerLazySingleton(
    () => ValidateLandUseCase(repository: getIt<GeometreRepository>()),
  );
  getIt.registerLazySingleton(
    () => LoginUseCase(repository: getIt<AuthRepository>()),
  );
  //blocs
   getIt.registerFactory(
    () => LoginBloc(
      loginUseCase: getIt<LoginUseCase>(),
      secureStorage: getIt<SecureStorageService>(),
      sessionService: getIt<SessionService>(),
    ),
  );
  getIt.registerFactory(
    () => GeometreBloc(
      getPendingLands: getIt<GetPendingLands>(),
      validateLand: getIt<ValidateLandUseCase>(),
      logger: getIt<Logger>(),
    ),
  );
  // Log initialization
  getIt<Logger>().log(
    Level.info,
    'Dependency injection setup completed',
  );
}
