import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'color', type: coui.ItemPicker)
Widget buildItemPickerColorUseCase(BuildContext _) {
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];

  return coui.ItemPicker<Color>(
    builder: (context, color) => coui.ItemPickerOption<Color>(
      value: color,
      child: Container(
        color: color,
        height: 48,
        width: 48,
      ),
    ),
    items: coui.ItemList(colors),
    layout: coui.ItemPickerLayout.grid(crossAxisCount: 4),
    onChanged: (c) {
      final value = c;
      if (value != null) {
        debugPrint('Color: $value');
      }
    },
  );
}

@UseCase(name: 'icon', type: coui.ItemPicker)
Widget buildItemPickerIconUseCase(BuildContext _) {
  final icons = [Icons.home, Icons.star, Icons.favorite, Icons.search];

  return coui.ItemPicker<IconData>(
    builder: (context, icon) => coui.ItemPickerOption<IconData>(
      value: icon,
      child: Icon(icon),
    ),
    items: coui.ItemList(icons),
    layout: coui.ItemPickerLayout.grid(crossAxisCount: 4),
    onChanged: (i) {
      final value = i;
      if (value != null) {
        debugPrint('Icon: $value');
      }
    },
  );
}
