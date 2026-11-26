// The ChipGroup header stacks the title over the selection hint (two lines,
// 2 apart); the title is the 15px label role in SemiBold and the hint the
// 12px body role in `onSurfaceVariant`. The scroll layout keeps its chips on
// one line. Every expectation is read off what the engine laid out and
// painted, not off the resolver — the Web twin pins the same values.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Widget _chip(
  String item, {
  required bool selected,
  required bool enabled,
  required VoidCallback onTap,
}) => Chip(
  onTap: onTap,
  label: item,
  enabled: enabled,
  selected: selected,
);

Future<BuildContext> _pump(
  WidgetTester tester, {
  required double width,
  required ChipGroup<String> group,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: .topLeft,
        child: SizedBox(
          width: width,
          child: Builder(
            builder: (context) {
              captured = context;
              return group;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return captured;
}

ChipGroup<String> _headed() => const ChipGroup<String>(
  items: ['A', 'B', 'C'],
  chipBuilder: _chip,
  title: Text('Filter'),
  selectionHint: Text('Pick up to two'),
);

TextStyle _painted(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('the hint sits under the title, 2 apart, start-aligned', (
    tester,
  ) async {
    await _pump(tester, width: 240, group: _headed());
    final title = tester.getRect(find.text('Filter'));
    final hint = tester.getRect(find.text('Pick up to two'));

    expect(hint.top - title.bottom, CoreSpace.space2);
    expect(hint.left, title.left);
  });

  testWidgets('title is 15 SemiBold, hint is 12 regular onSurfaceVariant', (
    tester,
  ) async {
    final context = await _pump(tester, width: 240, group: _headed());
    final scheme = Theme.of(context).colorScheme;

    final title = _painted(tester, 'Filter');
    expect(title.fontSize, CoreFontSize.s15);
    expect(title.fontWeight, FontWeight.w600);
    expect(
      title.color,
      scheme.resolve(const CoreColor.token(CoreColors.onSurface)).toValue(),
    );

    final hint = _painted(tester, 'Pick up to two');
    expect(hint.fontSize, CoreFontSize.s12);
    expect(hint.fontWeight, FontWeight.w400);
    expect(
      hint.color,
      scheme
          .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
          .toValue(),
    );
  });

  testWidgets('the scroll layout keeps every chip on one line', (
    tester,
  ) async {
    const labels = ['Design', 'Develop', 'Plan', 'Research'];
    await _pump(
      tester,
      width: 120,
      group: const ChipGroup<String>(
        items: labels,
        chipBuilder: _chip,
        layout: .scroll,
      ),
    );
    final tops = {for (final t in labels) tester.getRect(find.text(t)).top};
    expect(tops, hasLength(1));
  });
}
