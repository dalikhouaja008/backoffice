// lib/injection.dart
import 'package:flareline/presentation/bloc/geometre/geometre_bloc.dart';
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
  // Core
  getIt.registerLazySingleton(() => Logger());
  getIt.registerLazySingleton(
      () => Dio()..options.baseUrl = 'http://localhost:5000');

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

  // Use cases
  getIt.registerLazySingleton(
    () => GetPendingLands(repository: getIt<GeometreRepository>()),
  );
  getIt.registerLazySingleton(
    () => ValidateLandUseCase(repository: getIt<GeometreRepository>()),
  );
  //blocs
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
