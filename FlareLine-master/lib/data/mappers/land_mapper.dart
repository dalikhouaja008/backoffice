import 'package:flareline/data/models/land_model.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/data/mappers/validation_mapper.dart';


class LandMapper {
  static Land toEntity(LandModel model) {
    return Land(
      id: model.id,
      title: model.title,
      description: model.description,
      location: model.location,
      surface: model.surface,
      totalTokens: model.totalTokens,
      pricePerToken: model.pricePerToken,
      priceland: model.priceland,
      ownerId: model.ownerId,
      ownerAddress: model.ownerAddress,
      latitude: model.latitude,
      longitude: model.longitude,
      status: model.status,
      landtype: model.landtype,
      ipfsCIDs: model.ipfsCIDs,
      imageCIDs: model.imageCIDs,
      imageUrls: model.imageUrls,         // Ajouter les nouvelles propriétés
      documentUrls: model.documentUrls,   // Ajouter les nouvelles propriétés
      coverImageUrl: model.coverImageUrl, // Ajouter les nouvelles propriétés
      metadataCID: model.metadataCID,
      blockchainTxHash: model.blockchainTxHash,
      blockchainLandId: model.blockchainLandId,
      validations: model.validations.map(ValidationMapper.toEntity).toList(),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      amenities: model.amenities,
    );
  }

  static LandModel toModel(Land entity) {
    return LandModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      location: entity.location,
      surface: entity.surface,
      totalTokens: entity.totalTokens,
      pricePerToken: entity.pricePerToken,
      priceland: entity.priceland,
      ownerId: entity.ownerId,
      ownerAddress: entity.ownerAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      status: entity.status,
      landtype: entity.landtype,
      ipfsCIDs: entity.ipfsCIDs,
      imageCIDs: entity.imageCIDs,
      imageUrls: entity.imageUrls,         // Ajouter les nouvelles propriétés
      documentUrls: entity.documentUrls,   // Ajouter les nouvelles propriétés
      coverImageUrl: entity.coverImageUrl, // Ajouter les nouvelles propriétés
      metadataCID: entity.metadataCID,
      blockchainTxHash: entity.blockchainTxHash,
      blockchainLandId: entity.blockchainLandId,
      validations: entity.validations.map(ValidationMapper.toModel).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      amenities: entity.amenities,
    );
  }

  static List<Land> toEntityList(List<LandModel> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  static List<LandModel> toModelList(List<Land> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }
}