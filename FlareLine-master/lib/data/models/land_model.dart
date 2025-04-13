import 'package:flareline/data/models/validation_model.dart';
import 'package:flareline/domain/enums/validation_enums.dart';

class LandModel {
  final String id;
  final String title;
  final String? description;
  final String location;
  final double surface;
  final int totalTokens;
  final String pricePerToken;
  final String ownerId;
  final String ownerAddress;
  final double? latitude;
  final double? longitude;
  final LandValidationStatus status;
  final List<String> ipfsCIDs;
  final List<String> imageCIDs;
  final String? metadataCID;
  final String? blockchainTxHash;
  final String blockchainLandId;
  final List<ValidationModel> validations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LandModel({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.surface,
    required this.totalTokens,
    required this.pricePerToken,
    required this.ownerId,
    required this.ownerAddress,
    this.latitude,
    this.longitude,
    required this.status,
    required this.ipfsCIDs,
    required this.imageCIDs,
    this.metadataCID,
    this.blockchainTxHash,
    required this.blockchainLandId,
    required this.validations,
    this.createdAt,
    this.updatedAt,
  });

  factory LandModel.fromJson(Map<String, dynamic> json) {
    return LandModel(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      surface: json['surface'].toDouble(),
      totalTokens: json['totalTokens'],
      pricePerToken: json['pricePerToken'],
      ownerId: json['ownerId'],
      ownerAddress: json['ownerAddress'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: _parseValidationStatus(json['status']),
      ipfsCIDs: List<String>.from(json['ipfsCIDs'] ?? []),
      imageCIDs: List<String>.from(json['imageCIDs'] ?? []),
      metadataCID: json['metadataCID'],
      blockchainTxHash: json['blockchainTxHash'],
      blockchainLandId: json['blockchainLandId'],
      validations: _parseValidations(json['validations'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
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
      'ownerId': ownerId,
      'ownerAddress': ownerAddress,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString().split('.').last.toLowerCase(),
      'ipfsCIDs': ipfsCIDs,
      'imageCIDs': imageCIDs,
      'metadataCID': metadataCID,
      'blockchainTxHash': blockchainTxHash,
      'blockchainLandId': blockchainLandId,
      'validations': validations.map((v) => v.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static List<ValidationModel> _parseValidations(List<dynamic> validations) {
    return validations.map((v) => ValidationModel.fromJson(v)).toList();
  }

  static LandValidationStatus _parseValidationStatus(String status) {
    return LandValidationStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
      orElse: () => LandValidationStatus.PENDING_VALIDATION,
    );
  }
}