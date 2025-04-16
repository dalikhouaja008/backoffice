// lib/data/models/validation_response_model.dart

class ValidationResponseModel {
  final bool success;
  final String message;
  final ValidationResponseData data;

  ValidationResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ValidationResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidationResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ValidationResponseData.fromJson(json['data'] ?? {}),
    );
  }
}

class ValidationResponseData {
  final TransactionData transaction;
  final ValidationData validation;
  final LandStatusData land;

  ValidationResponseData({
    required this.transaction,
    required this.validation,
    required this.land,
  });

  factory ValidationResponseData.fromJson(Map<String, dynamic> json) {
    return ValidationResponseData(
      transaction: TransactionData.fromJson(json['transaction'] ?? {}),
      validation: ValidationData.fromJson(json['validation'] ?? {}),
      land: LandStatusData.fromJson(json['land'] ?? {}),
    );
  }
}

class TransactionData {
  final String hash;
  final int blockNumber;
  final int timestamp;

  TransactionData({
    required this.hash,
    required this.blockNumber,
    required this.timestamp,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      hash: json['hash'] ?? '',
      blockNumber: json['blockNumber'] ?? 0,
      timestamp: json['timestamp'] ?? 0,
    );
  }
}

class ValidationData {
  final String landId;
  final String blockchainLandId;
  final String validator;
  final int timestamp;
  final String cidComments;
  final bool isValidated;
  final String txHash;
  final int blockNumber;
  final String id;
  final String createdAt;
  final String updatedAt;

  ValidationData({
    required this.landId,
    required this.blockchainLandId,
    required this.validator,
    required this.timestamp,
    required this.cidComments,
    required this.isValidated,
    required this.txHash,
    required this.blockNumber,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ValidationData.fromJson(Map<String, dynamic> json) {
    return ValidationData(
      landId: json['landId'] ?? '',
      blockchainLandId: json['blockchainLandId'] ?? '',
      validator: json['validator'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      cidComments: json['cidComments'] ?? '',
      isValidated: json['isValidated'] ?? false,
      txHash: json['txHash'] ?? '',
      blockNumber: json['blockNumber'] ?? 0,
      id: json['_id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class LandStatusData {
  final String id;
  final String blockchainId;
  final String status;
  final String location;
  final LastValidation lastValidation;
  final ValidationProgress validationProgress;

  LandStatusData({
    required this.id,
    required this.blockchainId,
    required this.status,
    required this.location,
    required this.lastValidation,
    required this.validationProgress,
  });

  factory LandStatusData.fromJson(Map<String, dynamic> json) {
    return LandStatusData(
      id: json['id'] ?? '',
      blockchainId: json['blockchainId'] ?? '',
      status: json['status'] ?? '',
      location: json['location'] ?? '',
      lastValidation: LastValidation.fromJson(json['lastValidation'] ?? {}),
      validationProgress: ValidationProgress.fromJson(json['validationProgress'] ?? {}),
    );
  }
}

class LastValidation {
  final String validator;
  final String validatorRole;
  final bool isValid;
  final int timestamp;
  final String cidComments;

  LastValidation({
    required this.validator,
    required this.validatorRole,
    required this.isValid,
    required this.timestamp,
    required this.cidComments,
  });

  factory LastValidation.fromJson(Map<String, dynamic> json) {
    return LastValidation(
      validator: json['validator'] ?? '',
      validatorRole: json['validatorRole'] ?? '',
      isValid: json['isValid'] ?? false,
      timestamp: json['timestamp'] ?? 0,
      cidComments: json['cidComments'] ?? '',
    );
  }
}

class ValidationProgress {
  final int total;
  final int completed;
  final double percentage;
  final List<RoleValidation> validations;

  ValidationProgress({
    required this.total,
    required this.completed,
    required this.percentage,
    required this.validations,
  });

  factory ValidationProgress.fromJson(Map<String, dynamic> json) {
    List<RoleValidation> validationsList = [];
    if (json['validations'] != null) {
      validationsList = List<RoleValidation>.from(
        json['validations'].map((x) => RoleValidation.fromJson(x)),
      );
    }

    return ValidationProgress(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
      validations: validationsList,
    );
  }
}

class RoleValidation {
  final String role;
  final bool validated;
  final int? timestamp;
  final String? validator;

  RoleValidation({
    required this.role,
    required this.validated,
    this.timestamp,
    this.validator,
  });

  factory RoleValidation.fromJson(Map<String, dynamic> json) {
    return RoleValidation(
      role: json['role'] ?? '',
      validated: json['validated'] ?? false,
      timestamp: json['timestamp'],
      validator: json['validator'],
    );
  }
}