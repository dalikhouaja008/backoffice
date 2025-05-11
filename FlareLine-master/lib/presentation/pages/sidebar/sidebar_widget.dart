import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_bloc.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_state.dart';
import 'package:flareline/core/services/sidebar_service.dart';

class SidebarWidget extends StatelessWidget {
  final Function(String) onNavigate;

  const SidebarWidget({Key? key, required this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarBloc, SidebarState>(
      builder: (context, state) {
        if (state is SidebarLoading) {
          return Container(
            width: 250,
            color: Theme.of(context).primaryColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SidebarError) {
          return Container(
            width: 250,
            color: Theme.of(context).primaryColor,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erreur de chargement du menu: ${state.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (state is SidebarLoaded) {
          return _buildSidebar(context, state.menuGroups);
        }

        // État initial ou non géré
        return Container(
          width: 250,
          color: Theme.of(context).primaryColor,
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, List<MenuGroup> menuGroups) {
    return Container(
      width: 250,
      color: Theme.of(context).primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: menuGroups.map<Widget>((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  group.groupName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...group.menuList.map<Widget>((item) {
                if (item.childList != null && item.childList!.isNotEmpty) {
                  // Menu avec sous-menus
                  return ExpansionTile(
                    title: Row(
                      children: [
                        if (item.icon.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SvgPicture.asset(
                              item.icon,
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                          ),
                        Text(
                          item.menuName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    children: item.childList!.map<Widget>((child) {
                      return ListTile(
                        title: Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text(
                            child.menuName,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        onTap: () {
                          if (child.path != null) {
                            onNavigate(child.path!);
                          }
                        },
                      );
                    }).toList(),
                  );
                } else {
                  // Menu simple
                  return ListTile(
                    leading: item.icon.isNotEmpty
                        ? SvgPicture.asset(
                            item.icon,
                            width: 20,
                            height: 20,
                            color: Colors.white,
                          )
                        : null,
                    title: Text(
                      item.menuName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      if (item.path != null) {
                        onNavigate(item.path!);
                      }
                    },
                  );
                }
              }).toList(),
              const Divider(color: Colors.white24),
            ],
          );
        }).toList(),
      ),
    );
  }
}