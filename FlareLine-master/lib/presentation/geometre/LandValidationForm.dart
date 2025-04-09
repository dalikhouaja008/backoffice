import 'package:flareline/presentation/pages/form/date_picker_widget.dart';
import 'package:flareline/presentation/pages/form/single_checkbox_widget.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/drop_zone_widget.dart';
import 'package:flareline_uikit/components/forms/form_file_picker.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flutter/widgets.dart';

class LandValidationForm extends StatelessWidget {
  const LandValidationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        children: [
          OutBorderTextFormField(
            labelText: "Surface déclarée",
            hintText: "Surface en m²",
            enabled: false,
          ),
          SizedBox(height: 16),
          
          OutBorderTextFormField(
            labelText: "Surface mesurée",
            hintText: "Entrer la surface mesurée",
          ),
          SizedBox(height: 16),

          FormFilePicker(
            title: "Photos du terrain",
            allowExtention: ['jpg', 'jpeg', 'png'],
          ),
          SizedBox(height: 16),

          DropZoneWidget(),
          SizedBox(height: 16),

          DatePickerWidget(),
          SizedBox(height: 16),

          OutBorderTextFormField(
            labelText: "Commentaires",
            hintText: "Ajouter vos observations",
            maxLines: 5,
          ),
          SizedBox(height: 16),

          SingleCheckboxWidget(),
          
          ButtonWidget(
            btnText: "Valider le terrain",
            type: ButtonType.primary.type,
          ),
        ],
      ),
    );
  }
}