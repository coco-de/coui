import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Calendar)
material.Widget buildCalendarUseCase(material.BuildContext context) {
  return const _CalendarExample();
}

class _CalendarExample extends material.StatefulWidget {
  const _CalendarExample();

  @override
  material.State<_CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends material.State<_CalendarExample> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();

  @override
  material.Widget build(material.BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return Card(
      child: material.IntrinsicWidth(
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.stretch,
          mainAxisSize: material.MainAxisSize.min,
          children: [
            material.Row(
              children: [
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.previous;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const material.Icon(
                    material.Icons.arrow_back,
                  ).iconXSmall(),
                ),
                Text(
                  '${localizations.getMonth(_view.month)} ${_view.year}',
                ).small().medium().center().expanded(),
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.next;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const material.Icon(
                    material.Icons.arrow_forward,
                  ).iconXSmall(),
                ),
              ],
            ),
            const Gap(16),
            Calendar(
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
              selectionMode: CalendarSelectionMode.range,
              value: _value,
              view: _view,
            ),
          ],
        ),
      ),
    );
  }
}
