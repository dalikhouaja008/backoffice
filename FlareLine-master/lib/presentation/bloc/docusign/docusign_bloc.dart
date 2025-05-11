import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/domain/use_cases/docusign/check_authentication_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/initiate_authentication_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/create_envelope_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/get_signing_url_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/check_envelope_status_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/download_signed_document_use_case.dart';
import 'package:flareline/domain/use_cases/docusign/get_signature_history_use_case.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'package:logger/logger.dart';

class DocuSignBloc extends Bloc<DocuSignEvent, DocuSignState> {
  final CheckDocuSignAuthenticationUseCase checkAuthentication;
  final InitiateDocuSignAuthenticationUseCase initiateAuthentication;
  final CreateEnvelopeUseCase createEnvelope;
  final GetSigningUrlUseCase getSigningUrl;
  final CheckEnvelopeStatusUseCase checkEnvelopeStatus;
  final DownloadSignedDocumentUseCase downloadSignedDocument;
  final GetSignatureHistoryUseCase getSignatureHistory;
  final Logger logger;

  DocuSignBloc({
    required this.checkAuthentication,
    required this.initiateAuthentication,
    required this.createEnvelope,
    required this.getSigningUrl,
    required this.checkEnvelopeStatus,
    required this.downloadSignedDocument,
    required this.getSignatureHistory,
    required this.logger,
  }) : super(DocuSignInitial()) {
    on<CheckDocuSignAuthenticationEvent>(_onCheckAuthentication);
    on<InitiateDocuSignAuthenticationEvent>(_onInitiateAuthentication);
    on<CreateEnvelopeEvent>(_onCreateEnvelope);
    on<GetSigningUrlEvent>(_onGetSigningUrl);
    on<CheckEnvelopeStatusEvent>(_onCheckEnvelopeStatus);
    on<DownloadDocumentEvent>(_onDownloadDocument);
    on<GetSignatureHistoryEvent>(_onGetSignatureHistory);
    on<UpdateDocuSignTokenEvent>(_onUpdateToken);
  }

  Future<void> _onCheckAuthentication(
    CheckDocuSignAuthenticationEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i(
        '[$timestamp] 🔐 Vérification de l\'état d\'authentification DocuSign');

    try {
      emit(DocuSignAuthCheckInProgress());

      final isAuthenticated = await checkAuthentication();

      if (isAuthenticated) {
        logger.i('[$timestamp] ✅ Utilisateur authentifié à DocuSign');
        emit(DocuSignAuthenticated());
      } else {
        logger.i('[$timestamp] ℹ️ Utilisateur non authentifié à DocuSign');
        emit(DocuSignNotAuthenticated());
      }
    } catch (e) {
      logger.e(
          '[$timestamp] ❌ Erreur lors de la vérification d\'authentification: $e');
      emit(DocuSignAuthError(
          'Erreur lors de la vérification de l\'authentification: $e'));
    }
  }

  Future<void> _onInitiateAuthentication(
    InitiateDocuSignAuthenticationEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🚀 Initialisation de l\'authentification DocuSign');

    try {
      final success = await initiateAuthentication();

      if (success) {
        logger.i('[$timestamp] ✅ Authentification initiée avec succès');
        emit(DocuSignAuthenticationInitiated());
      } else {
        logger.e(
            '[$timestamp] ❌ Échec de l\'initialisation de l\'authentification');
        emit(
            DocuSignAuthError('Impossible d\'initialiser l\'authentification'));
      }
    } catch (e) {
      logger.e(
          '[$timestamp] ❌ Erreur lors de l\'initialisation de l\'authentification: $e');
      emit(DocuSignAuthError('Erreur lors de l\'authentification: $e'));
    }
  }

 Future<void> _onCreateEnvelope(
  CreateEnvelopeEvent event,
  Emitter<DocuSignState> emit,
) async {
  final timestamp = DateTime.now().toIso8601String();
  logger.i('[$timestamp] 📨 Création d\'une enveloppe DocuSign'
           '\n└─ Titre: ${event.title}'
           '\n└─ Signataire: ${event.signerName} (${event.signerEmail})');
  
  try {
    emit(EnvelopeCreationInProgress());
    
    // Récupérer une instance du data source DocuSign
    final docuSignDataSource = getIt<DocuSignRemoteDataSource>();
    
    // Vérifier d'abord si le token est valide
    final isAuthenticated = await docuSignDataSource.isAuthenticated();
    if (!isAuthenticated) {
      logger.e('[$timestamp] 🚫 Session DocuSign expirée, authentification requise');
      emit(const DocuSignAuthRequired());
      return;
    }
    
    final envelope = await createEnvelope(
      documentBase64: event.documentBase64,
      signerEmail: event.signerEmail,
      signerName: event.signerName,
      title: event.title,
    );
    
    if (envelope.envelopeId != null) {
      logger.i('[$timestamp] ✅ Enveloppe créée avec succès: ${envelope.envelopeId}');
      emit(EnvelopeCreated(envelope.envelopeId!));
    } else {
      logger.e('[$timestamp] ❌ L\'enveloppe a été créée mais sans ID');
      emit(const EnvelopeCreationError('L\'enveloppe a été créée mais sans ID'));
    }
  } catch (e) {
    logger.e('[$timestamp] ❌ Erreur lors de la création de l\'enveloppe: $e');
    
    // Vérifier si c'est une erreur liée à l'authentification ou token expiré
    if (e.toString().contains('jwt expired') || 
        e.toString().contains('token') && e.toString().contains('invalid') ||
        e.toString().contains('401') || e.toString().contains('403')) {
      logger.e('[$timestamp] 🔑 Token DocuSign expiré ou invalide');
      emit(const DocuSignAuthRequired());
    } else {
      emit(EnvelopeCreationError('Erreur lors de la création de l\'enveloppe: $e'));
    }
  }
}

  Future<void> _onGetSigningUrl(
    GetSigningUrlEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🔗 Récupération de l\'URL de signature'
        '\n└─ Enveloppe: ${event.envelopeId}'
        '\n└─ Signataire: ${event.signerName} (${event.signerEmail})');

    try {
      emit(SigningUrlLoadInProgress());

      final signingUrl = await getSigningUrl(
        envelopeId: event.envelopeId,
        signerEmail: event.signerEmail,
        signerName: event.signerName,
        returnUrl: event.returnUrl,
      );

      logger.i('[$timestamp] ✅ URL de signature récupérée avec succès');
      emit(SigningUrlLoaded(signingUrl));
    } catch (e) {
      logger.e('[$timestamp] ❌ Erreur lors de la récupération de l\'URL: $e');
      
      // Vérifier si c'est une erreur liée à l'authentification
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        logger.e('[$timestamp] 🔑 Token DocuSign expiré ou invalide');
        emit(const DocuSignAuthRequired());
      } else {
        emit(SigningUrlError('Erreur lors de la récupération de l\'URL: $e'));
      }
    }
  }

  Future<void> _onCheckEnvelopeStatus(
    CheckEnvelopeStatusEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i(
        '[$timestamp] 🔍 Vérification du statut de l\'enveloppe: ${event.envelopeId}');

    try {
      emit(EnvelopeStatusCheckInProgress());

      final envelope = await checkEnvelopeStatus(event.envelopeId);

      logger.i(
          '[$timestamp] ✅ Statut de l\'enveloppe récupéré: ${envelope.status}');
      emit(EnvelopeStatusLoaded(envelope));
    } catch (e) {
      logger.e('[$timestamp] ❌ Erreur lors de la vérification du statut: $e');
      
      // Vérifier si c'est une erreur liée à l'authentification
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        logger.e('[$timestamp] 🔑 Token DocuSign expiré ou invalide');
        emit(const DocuSignAuthRequired());
      } else {
        emit(EnvelopeStatusError('Erreur lors de la vérification du statut: $e'));
      }
    }
  }

  Future<void> _onDownloadDocument(
    DownloadDocumentEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i(
        '[$timestamp] 📥 Téléchargement du document signé: ${event.envelopeId}');

    try {
      emit(DocumentDownloadInProgress());

      final documentBytes = await downloadSignedDocument(event.envelopeId);

      logger.i(
          '[$timestamp] ✅ Document téléchargé avec succès (${documentBytes.length} bytes)');
      emit(DocumentDownloaded(documentBytes));
    } catch (e) {
      logger.e('[$timestamp] ❌ Erreur lors du téléchargement du document: $e');
      
      // Vérifier si c'est une erreur liée à l'authentification
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        logger.e('[$timestamp] 🔑 Token DocuSign expiré ou invalide');
        emit(const DocuSignAuthRequired());
      } else {
        emit(DocumentDownloadError('Erreur lors du téléchargement: $e'));
      }
    }
  }

  Future<void> _onGetSignatureHistory(
    GetSignatureHistoryEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 📚 Récupération de l\'historique des signatures');

    try {
      emit(SignatureHistoryLoadInProgress());

      final signatures = await getSignatureHistory();

      logger.i(
          '[$timestamp] ✅ Historique récupéré: ${signatures.length} signatures');
      emit(SignatureHistoryLoaded(signatures));
    } catch (e) {
      logger.e(
          '[$timestamp] ❌ Erreur lors de la récupération de l\'historique: $e');
      
      // Vérifier si c'est une erreur liée à l'authentification
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        logger.e('[$timestamp] 🔑 Token DocuSign expiré ou invalide');
        emit(const DocuSignAuthRequired());
      } else {
        emit(SignatureHistoryError('Erreur lors de la récupération de l\'historique: $e'));
      }
    }
  }

  Future<void> _onUpdateToken(
    UpdateDocuSignTokenEvent event,
    Emitter<DocuSignState> emit,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    logger.i('[$timestamp] 🔄 Mise à jour manuelle du token DocuSign');

    try {
      // Utiliser le DocuSignRemoteDataSource au lieu de DocuSignService
      final docuSignDataSource = getIt<DocuSignRemoteDataSource>();
      await docuSignDataSource.setAccessToken(
        event.token,
        expiresIn: event.expiresIn,
      );

      logger.i('[$timestamp] ✅ Token DocuSign mis à jour manuellement');
      emit(DocuSignAuthenticated());
    } catch (e) {
      logger.e('[$timestamp] ❌ Erreur lors de la mise à jour du token: $e');
      emit(DocuSignAuthError('Erreur lors de la mise à jour du token: $e'));
    }
  }
}