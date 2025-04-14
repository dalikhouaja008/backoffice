import 'package:flutter/material.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline/presentation/pages/layout.dart';
import 'package:flareline/presentation/geometre/widgets/land_validation_form.dart';

class LandValidationFormPage extends LayoutWidget {
  final Land? land;

  const LandValidationFormPage({super.key, this.land});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Validation de terrain';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: LandValidationForm(),
    );
  }
}