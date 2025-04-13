class ValidationRequestModel {
  final String landId;
  final bool isValidated;
  final String? comments;

  ValidationRequestModel({
    required this.landId,
    required this.isValidated,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'landId': landId,
      'isValidated': isValidated,
      'comments': comments,
    };
  }
}