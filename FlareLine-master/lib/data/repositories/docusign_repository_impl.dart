import 'package:flareline/data/datasources/docusign_remote_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flareline/data/models/docusign_model.dart';
import 'package:flareline/domain/entities/docusign_entity.dart';
import 'package:flareline/domain/repositories/docusign_repository.dart';

class DocuSignRepositoryImpl implements DocuSignRepository {
  final DocuSignRemoteDataSource remoteDataSource;
  
  DocuSignRepositoryImpl({required this.remoteDataSource});
  
  @override
  Future<bool> isAuthenticated() async {
    return await remoteDataSource.isAuthenticated();
  }
  
  @override
  Future<bool> initiateAuthentication() async {
    return await remoteDataSource.initiateAuthentication();
  }
  
  @override
  Future<DocuSignEntity> createEnvelope({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
  }) async {
    try {
      final response = await remoteDataSource.createEmbeddedEnvelope(
        documentBase64: documentBase64,
        signerEmail: signerEmail,
        signerName: signerName,
        title: title,
      );
      
      if (response['success'] == true && response['envelopeId'] != null) {
        return DocuSignModel(
          envelopeId: response['envelopeId'],
          status: 'sent',
          createdDate: DateTime.now(),
        );
      } else {
        throw Exception(response['error'] ?? 'Échec de la création de l\'enveloppe');
      }
    } catch (e) {
      debugPrint('Erreur dans le repository lors de la création de l\'enveloppe: $e');
      rethrow;
    }
  }
  
  @override
  Future<String> getSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    required String returnUrl,
  }) async {
    try {
      final response = await remoteDataSource.getEmbeddedSigningUrl(
        envelopeId: envelopeId,
        signerEmail: signerEmail,
        signerName: signerName,
        returnUrl: returnUrl,
      );
      
      if (response['success'] == true && response['signingUrl'] != null) {
        return response['signingUrl'];
      } else {
        throw Exception(response['error'] ?? 'Échec de récupération de l\'URL de signature');
      }
    } catch (e) {
      debugPrint('Erreur dans le repository lors de la récupération de l\'URL: $e');
      rethrow;
    }
  }
  
  @override
  Future<DocuSignEntity> checkEnvelopeStatus(String envelopeId) async {
    try {
      final response = await remoteDataSource.checkEnvelopeStatus(
        envelopeId: envelopeId,
      );
      
      if (response['success'] == true) {
        return DocuSignModel(
          envelopeId: envelopeId,
          status: response['status'],
          createdDate: response['created'] != null ? DateTime.parse(response['created']) : null,
          sentDate: response['sent'] != null ? DateTime.parse(response['sent']) : null,
          completedDate: response['completed'] != null ? DateTime.parse(response['completed']) : null,
        );
      } else {
        throw Exception(response['error'] ?? 'Échec de la vérification du statut');
      }
    } catch (e) {
      debugPrint('Erreur dans le repository lors de la vérification du statut: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<int>> downloadSignedDocument(String envelopeId) async {
    try {
      final documentBytes = await remoteDataSource.downloadSignedDocument(
        envelopeId: envelopeId,
      );
      
      return documentBytes;
    } catch (e) {
      debugPrint('Erreur dans le repository lors du téléchargement du document: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<DocuSignEntity>> getSignatureHistory() async {
    try {
      final response = await remoteDataSource.getSignatureHistory();
      
      if (response['success'] == true && response['signatures'] != null) {
        final signaturesJson = response['signatures'] as List;
        return DocuSignModel.fromJsonList(signaturesJson);
      } else {
        throw Exception(response['error'] ?? 'Échec de la récupération de l\'historique');
      }
    } catch (e) {
      debugPrint('Erreur dans le repository lors de la récupération de l\'historique: $e');
      rethrow;
    }
  }
  
}