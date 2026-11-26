/// Read-back tests for the line box a `DescriptionCard` row text style
/// states.
///
/// The row label / value overrides are flattened to CSS by hand rather than
/// through the shared emitter, so a typography field that emitter learns is
/// not learned here by itself. These assert the emitted declaration.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedDescriptionCardRow _resolveRow(
  BuildContext context,
  CoreDescriptionRow<Component> row,
) => resolveDescriptionCardRow(
  context,
  row: row,
  size: .md,
  layout: .horizontal,
  valueOverflow: .wrap,
  rowWeight: .valueProminent,
  isEmptyValue: false,
);

void main() {
  group('DescriptionCard row text-style line box', () {
    testComponents('a stated box reaches the value as a rem length', (
      tester,
    ) async {
      final resolved = _resolveRow(
        _themedContext(tester),
        const CoreDescriptionRow(
          label: 'Path',
          value: 'lib/main.dart',
          valueTextStyle: CoreTextStyle(
            lineHeight: CoreLineHeight.h140,
            lineHeightPx: CoreLineBox.px21,
          ),
        ),
      );
      expect(
        resolved.value.inlineStyles!.properties['line-height'],
        CssVariableGenerator.roundToPixelCss('1.3125rem'),
      );
    });

    // A multiplier draws the box it makes at the label's own size, on the
    // whole pixel Flutter's engine lays the line out in, and hands the
    // multiplier itself to the text below it.
    testComponents('a multiplier alone draws its box and hands it down', (
      tester,
    ) async {
      final resolved = _resolveRow(
        _themedContext(tester),
        const CoreDescriptionRow(
          label: 'Path',
          labelTextStyle: CoreTextStyle(lineHeight: CoreLineHeight.h140),
        ),
      );
      final label = resolved.label.inlineStyles!.properties;
      expect(
        label['line-height'],
        CssVariableGenerator.lineHeightCss(CoreLineHeight.h140),
      );
      expect(label[CssVariableGenerator.leadingVar], '${CoreLineHeight.h140}');
    });
  });
}
