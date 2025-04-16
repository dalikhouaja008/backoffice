// lib/data/models/land_model.dart
import 'package:flareline/data/models/validation_model.dart';
import 'package:flareline/domain/enums/validation_enums.dart';

class LandModel {
  final String id;
  final String title;
  final String? description;
  final String location;
  final double surface;
  final int? totalTokens;
  final String? pricePerToken;
  final String? priceland;
  final String ownerId;
  final String ownerAddress;
  final double? latitude;
  final double? longitude;
  final LandValidationStatus status;
  final String landtype;
  final List<String> ipfsCIDs;
  final List<String> imageCIDs;
  final List<String> imageUrls; // Nouvelle propriété pour les URLs d'images
  final List<String>
      documentUrls; // Nouvelle propriété pour les URLs de documents
  final String? coverImageUrl; // URL de l'image principale (optionnelle)
  final String? metadataCID;
  final String? blockchainTxHash;
  final String blockchainLandId;
  final List<ValidationModel> validations;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, bool>? amenities;

  const LandModel({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.surface,
    this.totalTokens,
    this.pricePerToken,
    this.priceland,
    required this.ownerId,
    required this.ownerAddress,
    this.latitude,
    this.longitude,
    required this.status,
    required this.landtype,
    required this.ipfsCIDs,
    required this.imageCIDs,
    this.imageUrls = const [], // Valeur par défaut
    this.documentUrls = const [], // Valeur par défaut
    this.coverImageUrl,
    this.metadataCID,
    this.blockchainTxHash,
    required this.blockchainLandId,
    required this.validations,
    this.createdAt,
    this.updatedAt,
    this.amenities,
  });

  factory LandModel.fromJson(Map<String, dynamic> json) {
    return LandModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      location: json['location'] ?? '',
      surface: _parseDouble(json['surface']),
      totalTokens: json['totalTokens'],
      pricePerToken: json['pricePerToken'],
      priceland: json['priceland'],
      ownerId: json['ownerId'] ?? '',
      ownerAddress: json['ownerAddress'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: _parseValidationStatus(json['status'] ?? 'pending_validation'),
      landtype: json['landtype'] ?? 'unknown',
      ipfsCIDs: _parseStringList(json['ipfsCIDs']),
      imageCIDs: _parseStringList(json['imageCIDs']),
      // Utiliser les nouvelles URLs d'images si disponibles, sinon tableau vide
      imageUrls: _parseStringList(json['imageUrls']),
      // Utiliser les nouvelles URLs de documents si disponibles, sinon tableau vide
      documentUrls: _parseStringList(json['documentUrls']),
      // Image de couverture
      coverImageUrl: json['coverImageUrl'],
      metadataCID: json['metadataCID'],
      blockchainTxHash: json['blockchainTxHash'],
      blockchainLandId: json['blockchainLandId']?.toString() ?? '0',
      validations: _parseValidations(json['validations']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      amenities: _parseAmenities(json['amenities']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'location': location,
      'surface': surface,
      'totalTokens': totalTokens,
      'pricePerToken': pricePerToken,
      'priceland': priceland,
      'ownerId': ownerId,
      'ownerAddress': ownerAddress,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString().split('.').last.toLowerCase(),
      'landtype': landtype,
      'ipfsCIDs': ipfsCIDs,
      'imageCIDs': imageCIDs,
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      'coverImageUrl': coverImageUrl,
      'metadataCID': metadataCID,
      'blockchainTxHash': blockchainTxHash,
      'blockchainLandId': blockchainLandId,
      'validations': validations.map((v) => v.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'amenities': amenities,
    };
  }

  // Méthodes utilitaires pour le parsing robuste
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  static List<ValidationModel> _parseValidations(dynamic validations) {
    if (validations == null) return [];
    if (validations is List) {
      return validations.map((v) => ValidationModel.fromJson(v)).toList();
    }
    return [];
  }

  static Map<String, bool>? _parseAmenities(dynamic amenities) {
    // Si null, retourner null
    if (amenities == null) return null;

    print("Type d'aménités reçu: ${amenities.runtimeType}");
    print("Contenu des aménités: $amenities");

    // Gérer le cas où amenities est un tableau de paires [clé, valeur]
    if (amenities is List) {
      Map<String, bool> result = {};

      try {
        for (var item in amenities) {
          if (item is List && item.length == 2) {
            String key = item[0].toString();
            var value = item[1];

            // Convertir la valeur en booléen
            bool boolValue = false;
            if (value is bool) {
              boolValue = value;
            } else if (value is String) {
              boolValue = value.toLowerCase() == 'true';
            } else if (value is num) {
              boolValue = value != 0;
            }

            result[key] = boolValue;
          }
        }
        return result.isNotEmpty ? result : null;
      } catch (e) {
        print("Erreur lors du parsing des aménités (format liste): $e");
        return null;
      }
    }

    // Si c'est déjà une Map<String, bool>
    if (amenities is Map<String, bool>) return amenities;

    // Si c'est une Map mais pas du bon type
    if (amenities is Map) {
      try {
        final resultMap = <String, bool>{};

        amenities.forEach((key, value) {
          if (key is String) {
            // Convertir différents types en booléen
            if (value is bool) {
              resultMap[key] = value;
            } else if (value is String) {
              resultMap[key] = value.toLowerCase() == 'true';
            } else if (value is num) {
              resultMap[key] = value != 0;
            } else {
              // Si on ne peut pas déterminer, considérer comme false
              resultMap[key] = false;
            }
          }
        });

        return resultMap.isNotEmpty ? resultMap : null;
      } catch (e) {
        print("Erreur lors du parsing des aménités (format map): $e");
        return null;
      }
    }

    return null;
  }

  static LandValidationStatus _parseValidationStatus(String status) {
    return LandValidationStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
      orElse: () => LandValidationStatus.PENDING_VALIDATION,
    );
  }
}
