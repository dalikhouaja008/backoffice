import 'package:equatable/equatable.dart';

abstract class DocuSignEvent extends Equatable {
  const DocuSignEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckDocuSignAuthenticationEvent extends DocuSignEvent {}

class InitiateDocuSignAuthenticationEvent extends DocuSignEvent {}

class CreateEnvelopeEvent extends DocuSignEvent {
  final String documentBase64;
  final String signerEmail;
  final String signerName;
  final String title;
  
  const CreateEnvelopeEvent({
    required this.documentBase64,
    required this.signerEmail,
    required this.signerName,
    required this.title,
  });
  
  @override
  List<Object?> get props => [documentBase64, signerEmail, signerName, title];
}

class GetSigningUrlEvent extends DocuSignEvent {
  final String envelopeId;
  final String signerEmail;
  final String signerName;
  final String returnUrl;
  
  const GetSigningUrlEvent({
    required this.envelopeId,
    required this.signerEmail,
    required this.signerName,
    required this.returnUrl,
  });
  
  @override
  List<Object?> get props => [envelopeId, signerEmail, signerName, returnUrl];
}

class CheckEnvelopeStatusEvent extends DocuSignEvent {
  final String envelopeId;
  
  const CheckEnvelopeStatusEvent({required this.envelopeId});
  
  @override
  List<Object?> get props => [envelopeId];
}

class DownloadDocumentEvent extends DocuSignEvent {
  final String envelopeId;
  
  const DownloadDocumentEvent({required this.envelopeId});
  
  @override
  List<Object?> get props => [envelopeId];
}

class OpenSigningUrlEvent extends DocuSignEvent {
  final String envelopeId;
  final String signerEmail;
  final String signerName;
  
  OpenSigningUrlEvent({
    required this.envelopeId,
    required this.signerEmail,
    required this.signerName,
  });
}
class UpdateDocuSignTokenEvent extends DocuSignEvent {
  final String token;
  final int? expiresIn;
  
  const UpdateDocuSignTokenEvent({
    required this.token,
    this.expiresIn,
  });
  
  @override
  List<Object?> get props => [token, expiresIn];
}

class DocuSignTokenExpiredEvent extends DocuSignEvent {}

class GetSignatureHistoryEvent extends DocuSignEvent {}
