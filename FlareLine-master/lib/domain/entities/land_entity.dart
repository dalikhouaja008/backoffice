import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:flareline/domain/enums/validation_enums.dart';

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

  Land copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? surface,
    int? totalTokens,
    String? pricePerToken,
    String? ownerId,
    String? ownerAddress,
    double? latitude,
    double? longitude,
    LandValidationStatus? status,
    List<String>? ipfsCIDs,
    List<String>? imageCIDs,
    String? metadataCID,
    String? blockchainTxHash,
    String? blockchainLandId,
    List<ValidationEntity>? validations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Land(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      surface: surface ?? this.surface,
      totalTokens: totalTokens ?? this.totalTokens,
      pricePerToken: pricePerToken ?? this.pricePerToken,
      ownerId: ownerId ?? this.ownerId,
      ownerAddress: ownerAddress ?? this.ownerAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      ipfsCIDs: ipfsCIDs ?? this.ipfsCIDs,
      imageCIDs: imageCIDs ?? this.imageCIDs,
      metadataCID: metadataCID ?? this.metadataCID,
      blockchainTxHash: blockchainTxHash ?? this.blockchainTxHash,
      blockchainLandId: blockchainLandId ?? this.blockchainLandId,
      validations: validations ?? this.validations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}