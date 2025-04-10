import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/enums/validation_enums.dart';
import 'package:flareline/domain/repositories/geometre_repository.dart';
import 'package:flareline/domain/entities/validation_entity.dart';
import 'package:flareline/data/datasources/geometre_remote_data_source.dart';

class GeometreRepositoryImpl implements GeometreRepository {
  final GeometreRemoteDataSource remoteDataSource;

  GeometreRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Land>> getPendingLands() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Land(
        id: 'LAND001',
        title: 'Terrain Agricole - Sousse',
        location: 'Sousse Nord',
        surface: 5000.0,
        status: LandValidationStatus.PENDING_VALIDATION,
        blockchainLandId: '0x1234567890abcdef',
        ownerId: 'OWNER001',
        ownerAddress: '0xowner1',
        totalTokens: 5000,
        pricePerToken: '1.0',
        ipfsCIDs: [],
        imageCIDs: [],
        validations: [],
        updatedAt: DateTime.parse('2025-04-09'),
        latitude: 35.8245, // Coordonnées de Sousse
        longitude: 10.6346,
      ),
      Land(
        id: 'LAND002',
        title: 'Terrain Constructible - Sfax',
        location: 'Sfax Centre',
        surface: 2500.0,
        status: LandValidationStatus.PARTIALLY_VALIDATED,
        blockchainLandId: '0xabcdef1234567890',
        ownerId: 'OWNER002',
        ownerAddress: '0xowner2',
        totalTokens: 2500,
        pricePerToken: '2.0',
        ipfsCIDs: [],
        imageCIDs: [],
        validations: [],
        updatedAt: DateTime.parse('2025-04-09'),
        latitude: 34.7406, // Coordonnées de Sfax
        longitude: 10.7603,
      ),
      Land(
        id: 'LAND003',
        title: 'Terrain Industrial - Tunis',
        location: 'Zone Industrielle',
        surface: 10000.0,
        status: LandValidationStatus.PENDING_VALIDATION,
        blockchainLandId: '0x9876543210fedcba',
        ownerId: 'OWNER003',
        ownerAddress: '0xowner3',
        totalTokens: 10000,
        pricePerToken: '1.5',
        ipfsCIDs: [],
        imageCIDs: [],
        validations: [],
        updatedAt: DateTime.parse('2025-04-09'),
        latitude: 35.8245, // Coordonnées de Sousse
        longitude: 10.6346,
      ),
    ];
  }

  @override
  Future<ValidationEntity> validateLand({
    required String landId,
    required ValidationEntity validation,
  }) {
    return remoteDataSource.validateLand(
      landId: landId,
      isValidated: validation.isValidated,
      comments: validation.comments,
    );
  }
}
