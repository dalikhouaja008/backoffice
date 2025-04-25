import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flareline/domain/entities/land_entity.dart';

class DocuSignDocumentService {
  // Préparation du document pour signature
  Future<String> prepareDocumentForSignature(Land land) async {
    try {
      // Vérifier si un document PDF est disponible
      String? pdfUrl;
      for (final url in land.documentUrls) {
        if (url.toLowerCase().endsWith('.pdf')) {
          pdfUrl = url;
          break;
        }
      }
      
      if (pdfUrl == null) {
        throw Exception('Aucun document PDF trouvé pour ce terrain');
      }
      
      // Télécharger le PDF
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Impossible de télécharger le document');
      }
      
      // Convertir en base64
      final bytes = response.bodyBytes;
      final base64Document = base64Encode(bytes);
      
      return base64Document;
    } catch (e) {
      debugPrint('Erreur lors de la préparation du document: $e');
      rethrow;
    }
  }
}