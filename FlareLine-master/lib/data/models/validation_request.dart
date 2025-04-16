class ValidationRequestModel {
  final String landId;
  final bool isValid; 
  final String? comment; 

  ValidationRequestModel({
    required this.landId,
    required this.isValid,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'landId': landId.toString(), 
      'isValid': isValid,
      'comment': comment ?? '',
    };
  }
}