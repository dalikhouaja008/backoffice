import 'package:flareline/presentation/geometre/GeometreDashboard.dart';
import 'package:flareline/presentation/geometre/LandValidationForm.dart';
import 'package:flareline/presentation/geometre/LandsList.dart';
import 'package:flareline/presentation/pages/layout.dart';
import 'package:flutter/widgets.dart';

class GeometrePage extends LayoutWidget {
  const GeometrePage({Key? key}) : super(key: key);
  @override
  Widget contentDesktopWidget(BuildContext context) {
    return Column(
      children: [
        GeometreDashboard(),
        SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: LandsList(),
            ),
            SizedBox(width: 16),
            
            Expanded(
              flex: 2,
              child: LandValidationForm(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return Column(
      children: [
        GeometreDashboard(),
        SizedBox(height: 16),
        LandsList(),
        SizedBox(height: 16),
        LandValidationForm(),
      ],
    );
  }
}