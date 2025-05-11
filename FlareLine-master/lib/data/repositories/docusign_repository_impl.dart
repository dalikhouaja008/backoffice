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
    // La méthode initiateAuthentication ne renvoie plus de Future<bool> mais void
    // Nous modifions donc ce comportement pour retourner toujours true
    remoteDataSource.initiateAuthentication();
    return true;
  }

  @override
  Future<DocuSignEntity> createEnvelope({
    required String documentBase64,
    required String signerEmail,
    required String signerName,
    required String title,
    String? documentName,
    String? documentType,
  }) async {
    try {
      final response = await remoteDataSource.createEmbeddedEnvelope(
        documentBase64: documentBase64,
        signerEmail: signerEmail,
        signerName: signerName,
        title: title,
        documentName: documentName,
        documentType: documentType,
      );

      if (response['success'] == true && response['envelopeId'] != null) {
        return DocuSignModel(
          envelopeId: response['envelopeId'],
          status: 'sent',
          createdDate: DateTime.now(),
        );
      } else {
        throw Exception(
            response['error'] ?? 'Échec de la création de l\'enveloppe');
      }
    } catch (e) {
      debugPrint(
          'Erreur dans le repository lors de la création de l\'enveloppe: $e');
      rethrow;
    }
  }

  @override
  Future<String> getSigningUrl({
    required String envelopeId,
    required String signerEmail,
    required String signerName,
    String? returnUrl,
  }) async {
    try {
      // Appeler la méthode du DataSource
      final response = await remoteDataSource.getEmbeddedSigningUrl(
        envelopeId: envelopeId,
        signerEmail: signerEmail,
        signerName: signerName,
        returnUrl: returnUrl,
      );

      // La méthode retourne maintenant une String directement
      return response;
    } catch (e) {
      debugPrint(
          'Erreur dans le repository lors de la récupération de l\'URL: $e');
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
          createdDate: response['created'] != null
              ? DateTime.parse(response['created'])
              : null,
          sentDate: response['sent'] != null
              ? DateTime.parse(response['sent'])
              : null,
          completedDate: response['completed'] != null
              ? DateTime.parse(response['completed'])
              : null,
        );
      } else {
        throw Exception(
            response['error'] ?? 'Échec de la vérification du statut');
      }
    } catch (e) {
      debugPrint(
          'Erreur dans le repository lors de la vérification du statut: $e');
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadSignedDocument(String envelopeId) async {
    try {
      final documentBytes = await remoteDataSource.downloadSignedDocument(
        envelopeId: envelopeId,
      );

      // Convertir Uint8List en List<int>
      return documentBytes.toList();
    } catch (e) {
      debugPrint(
          'Erreur dans le repository lors du téléchargement du document: $e');
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
        throw Exception(
            response['error'] ?? 'Échec de la récupération de l\'historique');
      }
    } catch (e) {
      debugPrint(
          'Erreur dans le repository lors de la récupération de l\'historique: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateToken(String token, {int? expiresIn}) async {
    try {
      await remoteDataSource.setAccessToken(token, expiresIn: expiresIn);
    } catch (e) {
      debugPrint(
          'Erreur dans le repository lors de la mise à jour du token: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      debugPrint('Erreur dans le repository lors de la déconnexion: $e');
      rethrow;
    }
  }
}
