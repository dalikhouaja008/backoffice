// lib/features/geometre/presentation/bloc/geometre_state.dart
import 'package:equatable/equatable.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_progress.dart';

abstract class GeometreState extends Equatable {
  const GeometreState();
  
  @override
  List<Object?> get props => [];
}

class GeometreInitial extends GeometreState {}

class GeometreLoading extends GeometreState {}

class GeometreLoaded extends GeometreState {
  final List<Land> lands;
  final Land? selectedLand;
  final String? searchQuery;
  final bool isValidating;
  final String? errorMessage;
  final ValidationProgress? validationProgress;

  const GeometreLoaded({
    required this.lands,
    this.selectedLand,
    this.searchQuery,
    this.isValidating = false,
    this.errorMessage,
    this.validationProgress,
  });

  GeometreLoaded copyWith({
    List<Land>? lands,
    Land? selectedLand,
    String? searchQuery,
    bool? isValidating,
    String? errorMessage,
    ValidationProgress? validationProgress,
  }) {
    return GeometreLoaded(
      lands: lands ?? this.lands,
      selectedLand: selectedLand ?? this.selectedLand,
      searchQuery: searchQuery ?? this.searchQuery,
      isValidating: isValidating ?? this.isValidating,
      errorMessage: errorMessage,
      validationProgress: validationProgress ?? this.validationProgress,
    );
  }

  @override
  List<Object?> get props => [
    lands, 
    selectedLand, 
    searchQuery, 
    isValidating, 
    errorMessage,
    validationProgress,
  ];
}

class GeometreError extends GeometreState {
  final String message;
  
  const GeometreError({required this.message});

  @override
  List<Object> get props => [message];
}

class ValidationInProgress extends GeometreState {
  final String landId;
  
  const ValidationInProgress({required this.landId});

  @override
  List<Object> get props => [landId];
}

class ValidationSuccess extends GeometreState {
  final Land land;
  final String message;

  const ValidationSuccess({
    required this.land,
    required this.message,
  });

  @override
  List<Object> get props => [land, message];
}

class ValidationFailure extends GeometreState {
  final String message;
  final String landId;

  const ValidationFailure({
    required this.message,
    required this.landId,
  });

  @override
  List<Object> get props => [message, landId];
}