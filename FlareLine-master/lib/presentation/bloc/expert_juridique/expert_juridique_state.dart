import 'package:equatable/equatable.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/domain/entities/validation_progress.dart';

abstract class ExpertJuridiqueState extends Equatable {
  const ExpertJuridiqueState();
  
  @override
  List<Object?> get props => [];
}

class ExpertJuridiqueInitial extends ExpertJuridiqueState {}

class ExpertJuridiqueLoading extends ExpertJuridiqueState {}

class ExpertJuridiqueLoaded extends ExpertJuridiqueState {
  final List<Land> lands;
  final Land? selectedLand;
  final String? searchQuery;
  final bool isValidating;
  final String? errorMessage;
  final ValidationProgress? validationProgress;

  const ExpertJuridiqueLoaded({
    required this.lands,
    this.selectedLand,
    this.searchQuery,
    this.isValidating = false,
    this.errorMessage,
    this.validationProgress,
  });

  ExpertJuridiqueLoaded copyWith({
    List<Land>? lands,
    Land? selectedLand,
    String? searchQuery,
    bool? isValidating,
    String? errorMessage,
    ValidationProgress? validationProgress,
  }) {
    return ExpertJuridiqueLoaded(
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

class ExpertJuridiqueError extends ExpertJuridiqueState {
  final String message;
  
  const ExpertJuridiqueError({required this.message});

  @override
  List<Object> get props => [message];
}

class ValidationInProgress extends ExpertJuridiqueState {
  final String landId;
  
  const ValidationInProgress({required this.landId});

  @override
  List<Object> get props => [landId];
}

class ValidationSuccess extends ExpertJuridiqueState {
  final Land land;
  final String message;
  final Map<String, dynamic>? transactionInfo; 

  const ValidationSuccess({
    required this.land,
    required this.message,
    this.transactionInfo,
  });

  @override
  List<Object?> get props => [land, message, transactionInfo];
}

class ValidationFailure extends ExpertJuridiqueState {
  final String message;
  final String landId;

  const ValidationFailure({
    required this.message,
    required this.landId,
  });

  @override
  List<Object> get props => [message, landId];
}