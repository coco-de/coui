import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

const _kViewport = 200.0;
const _kRowCount = 16;
const _kSelectionAreaKey = Key('fade-scroll-selection-area');

/// A `FadeScroll` under a `SelectionArea` the way `CoUIApp` installs it on
/// Web — same selection colour, derived from the theme — on the theme's
/// surface, so the golden shows the highlight the app would paint.
Widget _selectableFade() => Builder(
  builder: (context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface.toValue(),
      child: DefaultSelectionStyle(
        selectionColor: scheme
            .resolve(CoreSelectableTextStyle.defaultSelectionColor)
            .toValue(),
        child: SizedBox.square(
          dimension: _kViewport,
          child: material.SelectionArea(
            key: _kSelectionAreaKey,
            child: FadeScroll(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  for (var i = 0; i < _kRowCount; i++)
                    Text('Row $i text').bodyMedium.onSurface,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  },
);

/// Drags a mouse selection from the first row through the end fade, then
/// releases — the selection stays on screen for the capture.
Future<AsyncCallback?> _selectAcrossFade(WidgetTester tester) async {
  final area = tester.getRect(find.byKey(_kSelectionAreaKey));
  final gesture = await tester.startGesture(
    area.topLeft + const Offset(1, 1),
    kind: .mouse,
  );
  await tester.pump();
  await gesture.moveTo(area.bottomRight - const Offset(1, 1));
  await tester.pump();
  await gesture.up();
  await tester.pump();

  return null;
}

void main() {
  // One capture per brightness: a second `SelectionArea` taking focus would
  // clear the first one's selection, so the two cannot share a group.
  //
  // In the CI golden set alchemist paints every `RenderParagraph` as a
  // solid block, which draws over the highlight — only the platform set
  // shows it. The highlight's fade is pinned independently by
  // `test/components/display/fade_scroll_selection_test.dart`.
  group('FadeScroll Golden', () {
    for (final (name, preset) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      goldenTest(
        'selection across the fade — $name',
        fileName: 'fade_scroll_selection_$name',
        whilePerforming: _selectAcrossFade,
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 240),
          children: [
            GoldenTestScenario(
              name: 'selection active ($name)',
              child: buildGoldenTestApp(
                _selectableFade(),
                theme: ThemeData.fromCore(preset),
              ),
            ),
          ],
        ),
      ).ignore();
    }
  });
}
