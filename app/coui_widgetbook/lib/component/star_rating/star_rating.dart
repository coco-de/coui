import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: coui.StarRating)
Widget buildStarRatingDefaultUseCase(BuildContext context) {
  return coui.StarRating(
    max: 5,
    onChanged: (value) => print('Rating: $value'),
    step: 0.5,
    value: context.knobs.double.slider(
      initialValue: 3,
      label: 'rating',
      max: 5,
      min: 0,
    ),
  );
}
