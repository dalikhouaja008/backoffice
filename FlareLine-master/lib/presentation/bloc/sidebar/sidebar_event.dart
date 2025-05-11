import 'package:equatable/equatable.dart';

abstract class SidebarEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSidebar extends SidebarEvent {
  final String assetPath;

  LoadSidebar(this.assetPath);

  @override
  List<Object?> get props => [assetPath];
}

class RefreshSidebar extends SidebarEvent {}

class ToggleMenuItem extends SidebarEvent {
  final String menuName;

  ToggleMenuItem(this.menuName);

  @override
  List<Object?> get props => [menuName];
}