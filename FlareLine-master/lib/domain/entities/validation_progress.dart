// lib/features/geometre/domain/entities/validation_progress.dart
class ValidationProgress {
  final int total;
  final int completed;
  final double percentage;
  final List<ValidationProgressItem> validations;

  ValidationProgress({
    required this.total,
    required this.completed,
    required this.percentage,
    required this.validations,
  });
}

class ValidationProgressItem {
  final String role;
  final bool validated;
  final int? timestamp;
  final String? validator;

  ValidationProgressItem({
    required this.role,
    required this.validated,
    this.timestamp,
    this.validator,
  });
}