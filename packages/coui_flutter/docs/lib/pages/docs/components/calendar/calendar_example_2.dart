import 'package:coui_flutter/coui_flutter.dart';

class CalendarExample2 extends StatefulWidget {
  const CalendarExample2({super.key});

  @override
  State<CalendarExample2> createState() => _CalendarExample2State();
}

class _CalendarExample2State extends State<CalendarExample2> {
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
              now: DateTime.now(),
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              },
              selectionMode: CalendarSelectionMode.single,
              value: _value,
              view: _view,
            ),
          ],
        ),
      ),
    );
  }
}
