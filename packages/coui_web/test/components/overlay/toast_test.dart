import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The toast's root `<div role="status">` — its children are the glyph and
/// its gap (when drawn), the content column, then the action and the dismiss
/// wrapper.
DomComponent _root() => find
    .tag('div')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .firstWhere((node) => node.attributes?['role'] == 'status');

/// The `data-icon` names of every glyph on screen.
Iterable<String> _glyphs() => find
    .tag('svg')
    .evaluate()
    .map((element) => element.component)
    .whereType<DomComponent>()
    .map((c) => c.attributes?['data-icon'])
    .whereType<String>();

/// The inline width of the `lucide:x` glyph (#6214) — the close affordance
/// states no glyph size, so it is the `md` square button's (18 → 1.125rem).
String? _closeGlyphWidth() => find
    .tag('svg')
    .evaluate()
    .map((element) => element.component)
    .whereType<DomComponent>()
    .firstWhere((c) => c.attributes?['data-icon'] == 'lucide:x')
    .styles
    ?.properties['width'];

void main() {
  testComponents('#6214: the close glyph is the md square button glyph (18)', (
    tester,
  ) async {
    pumpWithTheme(tester, Toast(message: 'Saved', onDismiss: () {}));
    expect(_closeGlyphWidth(), '1.125rem');
  });

  // `showIcon` is the caller's off switch for the glyph the variant picked.
  // The glyph and the gap after it leave together, so the content column
  // opens the row — the twin of the Flutter branch.
  group('Toast showIcon', () {
    testComponents('is on by default, from the contract', (tester) async {
      expect(Toast(message: 'Saved').showIcon, isTrue);
      expect(CoreToastContract.defaultShowIcon, isTrue);

      pumpWithTheme(
        tester,
        Toast(message: 'Saved', variant: CoreToastVariant.success),
      );

      expect(_glyphs(), contains('lucide:circle-check'));
      // The glyph, then the gap, then the content column.
      final row = _root().children!;
      expect(row[0], isA<Icon>());
      expect(row[1], isA<Gap>());
    });

    for (final (variant, glyph) in [
      (CoreToastVariant.success, 'lucide:circle-check'),
      (CoreToastVariant.destructive, 'lucide:circle-alert'),
    ]) {
      testComponents('false drops the ${variant.name} glyph and the gap after '
          'it — the content column opens the row', (tester) async {
        pumpWithTheme(
          tester,
          Toast(message: 'Saved', variant: variant, showIcon: false),
        );

        expect(_glyphs(), isNot(contains(glyph)));
        expect(_glyphs(), isEmpty);
        expect(find.byType(Gap), findsNothing);
        final row = _root().children!;
        expect(row, hasLength(1));
        expect(row.first, isNot(isA<Icon>()));
        expect(
          find.descendant(
            of: find.byComponent(row.first),
            matching: find.text('Saved'),
          ),
          findsOneComponent,
        );
      });
    }

    testComponents('an explicit true draws what the default draws', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Toast(
          message: 'Saved',
          variant: CoreToastVariant.success,
        ).copyWith(showIcon: true),
      );
      final explicit = _root().children!.map((c) => c.runtimeType).toList();

      pumpWithTheme(
        tester,
        Toast(message: 'Saved', variant: CoreToastVariant.success),
      );
      final byDefault = _root().children!.map((c) => c.runtimeType).toList();

      expect(explicit, byDefault);
      expect(_glyphs(), contains('lucide:circle-check'));
    });

    testComponents('changes nothing on neutral — it has no glyph to drop', (
      tester,
    ) async {
      pumpWithTheme(tester, Toast(message: 'Saved'));
      final on = _root().children!.map((c) => c.runtimeType).toList();

      pumpWithTheme(tester, Toast(message: 'Saved', showIcon: false));
      final off = _root().children!.map((c) => c.runtimeType).toList();

      expect(off, on);
      expect(_glyphs(), isEmpty);
    });

    testComponents('keeps the description, the action and the dismiss button', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Toast(
          message: 'Saved',
          description: 'Your changes have been saved.',
          variant: CoreToastVariant.success,
          showIcon: false,
          action: const Component.text('UNDO'),
          onDismiss: () {},
        ),
      );

      expect(find.text('Saved'), findsOneComponent);
      expect(find.text('Your changes have been saved.'), findsOneComponent);
      expect(find.text('UNDO'), findsOneComponent);
      expect(_glyphs(), contains('lucide:x'));
      expect(_glyphs(), isNot(contains('lucide:circle-check')));
    });

    testComponents('copyWith carries showIcon', (tester) async {
      final toast = Toast(message: 'Saved', showIcon: false);

      expect(toast.copyWith(message: 'New').showIcon, isFalse);
      expect(toast.copyWith(showIcon: true).showIcon, isTrue);
    });
  });

  // The dark bubble, as the browser receives it: the fill and text are the
  // inverse pair on classes, the description is the text colour at 75 % (a
  // Tailwind alpha modifier on the same token), and the message's bold
  // overlay rides inline beside its role class.
  group('Toast inverse bubble', () {
    Iterable<DomComponent> divs() => find
        .tag('div')
        .evaluate()
        .map((element) => element.component as DomComponent);

    testComponents('fill and text are the inverse pair', (tester) async {
      pumpWithTheme(tester, Toast(message: 'Saved'));
      final classes = _root().classes!.split(' ');
      expect(classes, contains('bg-inverse-surface'));
      expect(classes, contains('text-inverse-on-surface'));
    });

    testComponents('the description is inverse-on-surface at 75 %', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Toast(message: 'Saved', description: 'Your changes are saved.'),
      );
      final description = divs().where(
        (d) => (d.classes ?? '').contains('text-body-small'),
      );
      expect(
        description.single.classes!.split(' '),
        contains('text-inverse-on-surface/75'),
      );
    });

    testComponents('the message is labelLarge, semibold', (tester) async {
      pumpWithTheme(tester, Toast(message: 'Saved'));
      final message = divs().singleWhere(
        (d) => (d.classes ?? '').split(' ').contains('text-label-large'),
      );
      expect(message.styles?.properties['font-weight'], '600');
    });
  });
}
