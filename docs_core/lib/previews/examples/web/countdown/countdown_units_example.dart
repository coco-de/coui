import 'package:coui_web/coui_web.dart';
import 'package:docs_core/shared/countdown_units_sample.dart';

/// Four caller-owned boxes sharing one intrinsic fraction, not a full row.
class CountdownUnitsExample extends StatelessComponent {
  const CountdownUnitsExample({super.key, this.days = 100});

  final int days;

  @override
  Component build(BuildContext context) {
    final values = [days, 8, 30, 15];
    return div(
      [
        for (var i = 0; i < values.length; i++)
          div(
            [
              OutlinedContainer(
                containerStyle: countdownUnitContainerStyle,
                child: div(
                  [
                    // The default max is 99; days must explicitly allow 100+.
                    Countdown(value: values[i], max: i == 0 ? 365 : 59),
                    Text(countdownUnitLabels[i]).bodyXs.onSurfaceVariant,
                  ],
                  classes: 'flex flex-col items-center gap-${CoreSpace.scale.space2}',
                ),
              ),
            ],
            attributes: {'data-countdown-unit': '$i'},
            styles: const Styles(raw: {'min-width': '${CoreSize.size56}px'}),
          ),
      ],
      classes: 'gap-${CoreSpace.scale.space8}',
      // An indefinite max-content grid resolves equal fr tracks from the
      // largest contribution. A full-width grid would expand to its parent.
      styles: const Styles(
        raw: {
          'display': 'inline-grid',
          'width': 'max-content',
          'grid-template-columns': 'repeat(4, 1fr)',
        },
      ),
    );
  }
}
