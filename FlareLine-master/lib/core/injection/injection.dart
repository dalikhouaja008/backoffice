import 'package:flareline/core/network/docusign_interceptor.dart';
import 'package:flareline/core/network/graphql_client.dart';
import 'package:flareline/core/routes/route_guard.dart';
import 'package:flareline/core/services/location_service.dart';
import 'package:flareline/core/services/openroute_service.dart';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:flareline/core/services/session_service.dart';
import 'package:flareline/data/datasources/auth_remote_data_source.dart';
import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:flareline/data/datasources/expert_juridique_remote_data_source.dart';
import 'package:flareline/data/repositories/auth_repo_impl.dart';
import 'package:flareline/data/repositories/docusign_repository_impl.dart';
import 'package:flareline/data/repositories/expert_juridique_repository_impl.dart';
import 'package:flareline/domain/repositories/auth_repo.dart';
import 'package:flareline/domain/repositories/docusign_repository.dart';
import 'package:flareline/domain/repositories/expert_juridique_repository.dart';
import 'package:flareline/domain/use_cases/docusign/check_authentication_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/check_envelope_status_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/create_envelope_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/download_signed_document_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/get_signature_history_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/get_signing_url_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/initiate_authentication_use_case.dart';
import 'package:flareline/domain/use_cases/expert_juridique/get_pending_lands.dart';
import 'package:flareline/domain/use_cases/expert_juridique/validate_land.dart';
import 'package:flareline/domain/use_cases/login_use_case.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/expert_juridique/expert_juridique_bloc.dart';
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
import 'package:flareline/core/network/auth_interceptor.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Ajout de l'import pour DocuSign
import 'package:flareline/core/services/docusign_service.dart';

final getIt = GetIt.instance;

void setupInjection() {
  // Services de base
  getIt.registerLazySingleton(() => Logger());
  getIt.registerLazySingleton(() => GraphQLService());
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  getIt.registerLazySingleton(() => SecureStorageService());
  getIt.registerLazySingleton(() => SessionService());
  getIt.registerLazySingleton(() => RouteGuard(getIt<SessionService>()));

  // Enregistrement du service DocuSign
  getIt.registerLazySingleton<DocuSignService>(() => DocuSignService());

  // Configuration de l'URL de l'API en fonction de la plateforme
  final String apiBaseUrl = _getApiBaseUrl();
  getIt.registerLazySingleton<String>(() => apiBaseUrl,
      instanceName: 'apiBaseUrl');

  getIt<Logger>().i('API Base URL configurée: $apiBaseUrl ');

  // Configuration de Dio avec AuthInterceptor pour LandService
  getIt.registerLazySingleton(() {
    final dio = Dio();

    // Configuration de base avec l'URL
    dio.options.baseUrl = apiBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);

    // Ajout des intercepteurs
    dio.interceptors.add(
      AuthInterceptor(
        secureStorage: getIt<SecureStorageService>(),
        logger: getIt<Logger>(),
      ),
    );

    // Ajout d'un intercepteur de logs pour le débogage
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) {
          getIt<Logger>().d(' [Dio] $log');
        },
      ),
    );

    dio.interceptors.add(DocuSignInterceptor(logger: getIt<Logger>()));

    // Configuration des en-têtes par défaut
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Ajout d'un intercepteur de logs pour le débogage
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) {
          getIt<Logger>().d('[Dio] $log');
        },
      ),
    );

    getIt<Logger>().i(
        ' Dio client configured with AuthInterceptor and DocuSignInterceptor');
    return dio;
  });

  // Services externes
  getIt.registerLazySingleton<OpenRouteService>(() => OpenRouteService(
        apiKey: '5b3ce3597851110001cf6248c25ce73e7fc44895be99f46b9e13afbd',
      ));

  getIt.registerLazySingleton<LocationService>(() => LocationService(
        logger: getIt<Logger>(),
      ));

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      graphQLService: getIt<GraphQLService>(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerLazySingleton<GeometreRemoteDataSource>(
    () => GeometreRemoteDataSource(
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
      baseUrl: apiBaseUrl,
    ),
  );

  getIt.registerLazySingleton<ExpertJuridiqueRemoteDataSource>(
    () => ExpertJuridiqueRemoteDataSource(
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
      baseUrl: apiBaseUrl,
    ),
  );

  getIt.registerLazySingleton<DocuSignRemoteDataSource>(
      () => DocuSignRemoteDataSource(
            dio: getIt<Dio>(),
            logger: getIt<Logger>(),
            secureStorage: getIt<SecureStorageService>(),
            baseUrl: apiBaseUrl,
          ));

  // Repositories
  getIt.registerLazySingleton<GeometreRepository>(
    () => GeometreRepositoryImpl(
      remoteDataSource: getIt<GeometreRemoteDataSource>(),
      logger: getIt<Logger>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
  );

  getIt.registerLazySingleton<ExpertJuridiqueRepository>(
    () => ExpertJuridiqueRepositoryImpl(
      remoteDataSource: getIt<ExpertJuridiqueRemoteDataSource>(),
    ),
  );
// Repository pour DocuSign
  getIt.registerLazySingleton<DocuSignRepository>(
    () => DocuSignRepositoryImpl(
      remoteDataSource: getIt<DocuSignRemoteDataSource>(),
    ),
  );

// Use Cases pour DocuSign
  getIt.registerLazySingleton<CheckDocuSignAuthenticationUseCase>(
    () => CheckDocuSignAuthenticationUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

  getIt.registerLazySingleton<InitiateDocuSignAuthenticationUseCase>(
    () => InitiateDocuSignAuthenticationUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

  getIt.registerLazySingleton<CreateEnvelopeUseCase>(
    () => CreateEnvelopeUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetSigningUrlUseCase>(
    () => GetSigningUrlUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

  getIt.registerLazySingleton<CheckEnvelopeStatusUseCase>(
    () => CheckEnvelopeStatusUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

  getIt.registerLazySingleton<DownloadSignedDocumentUseCase>(
    () => DownloadSignedDocumentUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetSignatureHistoryUseCase>(
    () => GetSignatureHistoryUseCase(
      repository: getIt<DocuSignRepository>(),
    ),
  );

// Bloc pour DocuSign
  getIt.registerFactory<DocuSignBloc>(
    () => DocuSignBloc(
      checkAuthentication: getIt<CheckDocuSignAuthenticationUseCase>(),
      initiateAuthentication: getIt<InitiateDocuSignAuthenticationUseCase>(),
      createEnvelope: getIt<CreateEnvelopeUseCase>(),
      getSigningUrl: getIt<GetSigningUrlUseCase>(),
      checkEnvelopeStatus: getIt<CheckEnvelopeStatusUseCase>(),
      downloadSignedDocument: getIt<DownloadSignedDocumentUseCase>(),
      getSignatureHistory: getIt<GetSignatureHistoryUseCase>(),
      logger: getIt<Logger>(),
    ),
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

  getIt.registerLazySingleton<GetPendingLandsExpertJuridique>(
    () => GetPendingLandsExpertJuridique(
      repository: getIt<ExpertJuridiqueRepository>(),
    ),
  );

  getIt.registerLazySingleton<ValidateLandUseCaseExpertJuridique>(
    () => ValidateLandUseCaseExpertJuridique(
      repository: getIt<ExpertJuridiqueRepository>(),
    ),
  );

  // Blocs
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

  getIt.registerFactory<ExpertJuridiqueBloc>(
    () => ExpertJuridiqueBloc(
      getPendingLands: getIt<GetPendingLandsExpertJuridique>(),
      validateLand: getIt<ValidateLandUseCaseExpertJuridique>(),
      logger: getIt<Logger>(),
    ),
  );

  // Log initialization
  getIt<Logger>().log(
    Level.info,
    ' Dependency injection setup completed ',
  );
}

// Fonction pour déterminer l'URL de l'API en fonction de la plateforme
String _getApiBaseUrl() {
  const String postmanWorkingUrl = 'http://localhost:5000';

  if (kIsWeb) {
    // Pour le web, on utilise l'URL complète avec le protocole pour éviter les problèmes CORS
    return postmanWorkingUrl;
  } else if (Platform.isAndroid) {
    // Pour Android, remplacer localhost par 10.0.2.2 (l'adresse IP de l'hôte depuis l'émulateur)
    return 'http://10.0.2.2:5000';
  } else if (Platform.isIOS) {
    // Pour iOS, utiliser 127.0.0.1 au lieu de localhost
    return 'http://127.0.0.1:5000';
  } else {
    // Pour les autres plateformes (desktop)
    return postmanWorkingUrl;
  }
}
