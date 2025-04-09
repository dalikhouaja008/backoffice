import 'package:flareline/domain/entities/validation_entity.dart';

class Land {
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
  final List<ValidationEntity> validations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Land({
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
}

enum LandValidationStatus {
  PENDING_VALIDATION,
  PARTIALLY_VALIDATED,
  VALIDATED,
  REJECTED,
  TOKENIZED
}