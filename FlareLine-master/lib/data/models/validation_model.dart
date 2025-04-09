class ValidationModel {
  final bool isValidated;
  final String? comments;

  const ValidationModel({
    required this.isValidated,
    this.comments,
  });

  factory ValidationModel.fromJson(Map<String, dynamic> json) {
    return ValidationModel(
      isValidated: json['isValidated'] ?? false,
      comments: json['comments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValidated': isValidated,
      'comments': comments,
    };
  }

  @override
  String toString() {
    return 'ValidationModel(isValidated: $isValidated, comments: $comments)';
  }
}