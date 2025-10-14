import 'package:coui_flutter/coui_flutter.dart';

class CalendarExample1 extends StatefulWidget {
  const CalendarExample1({super.key});

  @override
  State<CalendarExample1> createState() => _CalendarExample1State();
}

class _CalendarExample1State extends State<CalendarExample1> {
  CalendarValue? _value;
  CalendarView _view = CalendarView.now();
  @override
  Widget build(BuildContext context) {
    CoUILocalizations localizations = CoUILocalizations.of(context);
    return Card(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                OutlineButton(
                  onPressed: () {
                    setState(() {
                      _view = _view.previous;
                    });
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.arrow_back).iconXSmall(),
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
                  child: const Icon(Icons.arrow_forward).iconXSmall(),
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
