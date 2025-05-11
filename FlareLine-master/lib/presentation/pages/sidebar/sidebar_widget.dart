import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flareline/core/services/sidebar_service.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_bloc.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_state.dart';

class SidebarWidget extends StatelessWidget {
  final Function(String) onNavigate;

  const SidebarWidget({Key? key, required this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<SidebarBloc, SidebarState>(
      builder: (context, state) {
        if (state is SidebarLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SidebarLoaded) {
          return Container(
            color: isDark ? Colors.grey[900] : Colors.white,
            width: 280, // Largeur fixe pour la sidebar
            height: double.infinity,
            child: Column(
              children: [
                // Logo et en-tête
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildLogo(context), // Utiliser la méthode helper
                      const SizedBox(width: 12),
                      // Utiliser Expanded pour éviter les débordements
                      Expanded(
                        child: Text(
                          'TheBoost',
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                          ),
                          // Tronquer le texte si nécessaire
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Liste des menus
                Expanded(
                  child: state.menuGroups.isEmpty 
                    ? Center(child: Text('Aucun menu disponible pour ce rôle'))
                    : ListView.builder(
                        itemCount: state.menuGroups.length,
                        itemBuilder: (context, groupIndex) {
                          final group = state.menuGroups[groupIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Text(
                                  group.groupName,
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...group.menuList.map((menuItem) {
                                return _buildMenuItem(context, menuItem, isDark);
                              }).toList(),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        } else if (state is SidebarError) {
          return Center(child: Text('Erreur: ${state.error}'));
        }
        
        // État initial ou autre
        return const Center(child: Text('Chargement du menu...'));
      },
    );
  }

  // Méthode pour construire le logo
  Widget _buildLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    try {
      return SvgPicture.asset(
        'assets/logo/logo_${isDark ? 'white' : 'dark'}.svg',
        height: 32,
        placeholderBuilder: (BuildContext context) => Container(
          height: 32,
          width: 32,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 20),
        ),
      );
    } catch (e) {
      // Fallback au cas où le SVG ne peut pas être chargé
      return Container(
        height: 32,
        width: 32,
        color: isDark ? Colors.white : Colors.black,
        child: const Center(child: Text('FL', style: TextStyle(fontSize: 14))),
      );
    }
  }

  // Méthode pour construire un icône (SVG ou image normale)
  Widget _buildIcon(String iconPath) {
    if (iconPath.isEmpty) {
      return const SizedBox(width: 20, height: 20);
    }
    
    try {
      if (iconPath.endsWith('.svg')) {
        return SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          placeholderBuilder: (BuildContext context) => const SizedBox(
            width: 20,
            height: 20,
            child: Center(child: Icon(Icons.image, size: 14)),
          ),
        );
      } else {
        return Image.asset(
          iconPath,
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 20,
              height: 20,
              child: Center(child: Icon(Icons.broken_image, size: 14)),
            );
          },
        );
      }
    } catch (e) {
      // Fallback sur une icône matérielle
      return const Icon(Icons.folder, size: 20);
    }
  }

  // Méthode pour construire un élément de menu
  Widget _buildMenuItem(BuildContext context, MenuItem menuItem, bool isDark) {
    // Si l'élément a des enfants, construire un menu déroulant
    if (menuItem.childList != null && menuItem.childList!.isNotEmpty) {
      return _buildExpandableMenuItem(context, menuItem, isDark);
    }
    
    // Sinon, construire un élément normal
    return ListTile(
      leading: _buildIcon(menuItem.icon),
      title: Text(
        menuItem.menuName,
        overflow: TextOverflow.ellipsis, // Éviter les débordements
      ),
      onTap: () {
        if (menuItem.path != null) {
          onNavigate(menuItem.path!);
        }
      },
    );
  }

  // Méthode pour construire un élément de menu expandable
  Widget _buildExpandableMenuItem(BuildContext context, MenuItem menuItem, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: _buildIcon(menuItem.icon),
        title: Text(
          menuItem.menuName,
          overflow: TextOverflow.ellipsis,
        ),
        children: menuItem.childList!.map((childItem) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 56, right: 16),
            title: Text(
              childItem.menuName,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              if (childItem.path != null) {
                onNavigate(childItem.path!);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}