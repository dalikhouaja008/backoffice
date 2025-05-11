import 'package:flareline/core/injection/injection.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_bloc.dart';
import 'package:flareline/presentation/bloc/sidebar/sidebar_event.dart';
import 'package:flareline/presentation/pages/sidebar/sidebar_widget.dart';
import 'package:flareline_uikit/components/toolbar/toolbar.dart';
import 'package:flareline_uikit/service/localization_provider.dart';
import 'package:flareline_uikit/widget/flareline_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LayoutWidget extends FlarelineLayoutWidget {
  const LayoutWidget({super.key});

  @override
  String sideBarAsset(BuildContext context) {
    return 'assets/routes/menu_route_${context.watch<LocalizationProvider>().languageCode}.json';
  }

  @override
  Widget? toolbarWidget(BuildContext context, bool showDrawer) {
    return ToolBarWidget(
      showMore: showDrawer,
      showChangeTheme: true,
      userInfoWidget: _userInfoWidget(context),
    );
  }

  // IMPORTANT : Remplacer la méthode sideBarWidget par défaut
  @override
  Widget sideBarWidget(BuildContext context) {
    final assetPath = sideBarAsset(context);
    return BlocProvider(
      create: (context) => getIt<SidebarBloc>()..add(LoadSidebar(assetPath)),
      child: SidebarWidget(
        onNavigate: (path) {
          // Implémentez la navigation ici si nécessaire
          Navigator.of(context).pushNamed(path);
        },
      ),
    );
  }

  Widget _userInfoWidget(BuildContext context) {
    return const Row(
      children: [
        Column(
          children: [
            Text('Demo'),
          ],
        ),
        SizedBox(
          width: 10,
        ),
        CircleAvatar(
          backgroundImage: AssetImage('assets/user/user-02.png'),
          radius: 22,
        )
      ],
    );
  }
}