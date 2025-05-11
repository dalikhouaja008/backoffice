import 'package:equatable/equatable.dart';
import 'package:flareline/core/services/sidebar_service.dart';

abstract class SidebarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SidebarInitial extends SidebarState {}

class SidebarLoading extends SidebarState {}

class SidebarLoaded extends SidebarState {
  final List<MenuGroup> menuGroups;

  SidebarLoaded(this.menuGroups);

  @override
  List<Object?> get props => [menuGroups];
}

class SidebarError extends SidebarState {
  final String error;

  SidebarError(this.error);

  @override
  List<Object?> get props => [error];
}