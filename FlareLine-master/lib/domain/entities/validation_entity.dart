class ValidationEntity {
  final bool isValidated;
  final String? comments;

  const ValidationEntity({
    required this.isValidated,
    this.comments,
  });
}