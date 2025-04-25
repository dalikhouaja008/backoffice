import 'package:equatable/equatable.dart';
import 'package:flareline/domain/entities/docusign_entity.dart';

abstract class DocuSignState extends Equatable {
  const DocuSignState();
  
  @override
  List<Object?> get props => [];
}

class DocuSignInitial extends DocuSignState {}

// États d'authentification
class DocuSignAuthCheckInProgress extends DocuSignState {}
class DocuSignAuthenticated extends DocuSignState {}
class DocuSignNotAuthenticated extends DocuSignState {}
class DocuSignAuthenticationInitiated extends DocuSignState {}
class DocuSignAuthError extends DocuSignState {
  final String message;
  
  const DocuSignAuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// États de création d'enveloppe
class EnvelopeCreationInProgress extends DocuSignState {}
class EnvelopeCreated extends DocuSignState {
  final String envelopeId;
  
  const EnvelopeCreated(this.envelopeId);
  
  @override
  List<Object?> get props => [envelopeId];
}
class EnvelopeCreationError extends DocuSignState {
  final String message;
  
  const EnvelopeCreationError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// États de l'URL de signature
class SigningUrlLoadInProgress extends DocuSignState {}
class SigningUrlLoaded extends DocuSignState {
  final String signingUrl;
  
  const SigningUrlLoaded(this.signingUrl);
  
  @override
  List<Object?> get props => [signingUrl];
}
class SigningUrlError extends DocuSignState {
  final String message;
  
  const SigningUrlError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// États de vérification du statut
class EnvelopeStatusCheckInProgress extends DocuSignState {}
class EnvelopeStatusLoaded extends DocuSignState {
  final DocuSignEntity envelope;
  
  const EnvelopeStatusLoaded(this.envelope);
  
  @override
  List<Object?> get props => [envelope];
}
class EnvelopeStatusError extends DocuSignState {
  final String message;
  
  const EnvelopeStatusError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// États de téléchargement de document
class DocumentDownloadInProgress extends DocuSignState {}
class DocumentDownloaded extends DocuSignState {
  final List<int> documentBytes;
  
  const DocumentDownloaded(this.documentBytes);
  
  @override
  List<Object?> get props => [documentBytes.length];
}
class DocumentDownloadError extends DocuSignState {
  final String message;
  
  const DocumentDownloadError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// États de l'historique de signature
class SignatureHistoryLoadInProgress extends DocuSignState {}
class SignatureHistoryLoaded extends DocuSignState {
  final List<DocuSignEntity> signatures;
  
  const SignatureHistoryLoaded(this.signatures);
  
  @override
  List<Object?> get props => [signatures];
}
class SignatureHistoryError extends DocuSignState {
  final String message;
  
  const SignatureHistoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}