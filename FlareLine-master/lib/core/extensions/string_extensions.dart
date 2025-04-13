// File: lib/core/extensions/string_extensions.dart
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  String get truncatedId {
    return length > 8 ? "${substring(0, 8)}..." : this;
  }
}