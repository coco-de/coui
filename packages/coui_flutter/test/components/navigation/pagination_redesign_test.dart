import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// The navigation-position redesign (#5965) for Pagination, read back from what
// the screen paints: cell box, gap, text roles and colours, chevron size, the
// `enabled` rule and the disabled treatment.

const _kViewSize = Size(1600, 400);

// Page 5 of 10 at the default window shows every kind of cell:
// ‹ 1 … 4 [5] 6 … 10 ›.
Future<void> _pump(
  WidgetTester tester, {
  CoreValueChanged<int>? onPageChanged,
  bool? enabled,
  bool withHandler = true,
}) async {
  tester.view
    ..physicalSize = _kViewSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(
        child: Pagination(
          page: 5,
          totalPages: 10,
          enabled: enabled,
          onPageChanged: withHandler ? (onPageChanged ?? (_) {}) : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _face(Finder content) =>
    find.ancestor(of: content, matching: find.byType(OutlinedContainer)).first;

material.TextStyle _textStyle(WidgetTester tester, String label) => tester
    .widget<material.DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(material.DefaultTextStyle),
          )
          .first,
    )
    .style;

Color _scheme(WidgetTester tester, CoreColorToken token) => Theme.of(
  tester.element(find.byType(Pagination)),
).colorScheme.resolve(CoreColor.token(token)).toValue();

BoxDecoration _decoration(WidgetTester tester, Finder content) {
  final box = find
      .descendant(
        of: _face(content),
        matching: find.byType(AnimatedContainer),
      )
      .first;
  return tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
}

void main() {
  group('Pagination redesign (#5965)', () {
    testWidgets('a cell is 36 square and cells sit 4 apart', (tester) async {
      await _pump(tester);

      final one = tester.getRect(_face(find.text('1')));
      final four = tester.getRect(_face(find.text('4')));
      expect(one.size, const Size(36, 36));
      expect(four.size, const Size(36, 36));
      final ellipsis = tester.getRect(_face(find.text('…')).first);
      expect(ellipsis.size, const Size(36, 36));
      // `1`, `…`, `4` are consecutive cells.
      expect(ellipsis.left - one.right, closeTo(4, 0.01));
      expect(four.left - ellipsis.right, closeTo(4, 0.01));
    });

    testWidgets('numbers are 14 Regular on-surface-variant, the current '
        'page 14 SemiBold on-primary', (tester) async {
      await _pump(tester);

      final regular = _textStyle(tester, '4');
      expect(regular.fontSize, 14);
      expect(regular.fontWeight, material.FontWeight.w400);
      expect(regular.height, closeTo(1.5, 1e-6));
      expect(regular.color, _scheme(tester, CoreColors.onSurfaceVariant));

      final current = _textStyle(tester, '5');
      expect(current.fontSize, 14);
      expect(current.fontWeight, material.FontWeight.w600);
      expect(current.color, _scheme(tester, CoreColors.onPrimary));
      expect(
        _decoration(tester, find.text('5')).color,
        _scheme(tester, CoreColors.primary),
      );
    });

    testWidgets('the ellipsis is on-surface-subtle in the same typography', (
      tester,
    ) async {
      await _pump(tester);

      final dots = _textStyle(tester, '…');
      expect(dots.fontWeight, material.FontWeight.w400);
      expect(dots.fontSize, 14);
      expect(dots.color, _scheme(tester, CoreColors.onSurfaceSubtle));
    });

    testWidgets('a hovered number reads on-surface over the hover fill', (
      tester,
    ) async {
      // The pointer exists before the tree does, the way a real mouse does.
      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await _pump(tester);

      await gesture.moveTo(tester.getCenter(find.text('6')));
      await tester.pumpAndSettle();

      expect(
        _textStyle(tester, '6').color,
        _scheme(tester, CoreColors.onSurface),
      );
      expect(
        _decoration(tester, find.text('6')).color,
        _scheme(tester, CoreColors.surfaceContainerHigh),
      );
    });

    testWidgets('the chevrons are 16 and on-surface-variant', (tester) async {
      await _pump(tester);

      final icons = find.byType(Icon);
      expect(icons, findsNWidgets(2));
      for (final size in [
        for (final e in icons.evaluate())
          tester.getSize(find.byWidget(e.widget)),
      ]) {
        expect(size, const Size(16, 16));
      }
      final themed = tester.widget<material.IconTheme>(
        find
            .ancestor(
              of: icons.first,
              matching: find.byType(material.IconTheme),
            )
            .first,
      );
      expect(themed.data.color, _scheme(tester, CoreColors.onSurfaceVariant));
    });

    testWidgets('the focus ring is drawn around the cell: corner 8 + reach 4', (
      tester,
    ) async {
      await _pump(tester);
      final resolved = resolvePagination(
        tester.element(find.byType(Pagination)),
        variant: CorePaginationVariant.defaultVariant,
      );
      expect(
        resolved.clickableStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });
  });

  group('Pagination enabled (#5965)', () {
    testWidgets('follows the handler when unstated', (tester) async {
      await _pump(tester, withHandler: false);
      // No handler → disabled: nothing is wrapped in a Clickable and every
      // number takes the disabled content colour.
      expect(find.byType(Clickable), findsNothing);
      expect(
        _textStyle(tester, '4').color,
        _scheme(tester, CoreColors.disabledContent),
      );
    });

    testWidgets('disabled: one foreground for everything, the current page on '
        'the disabled container', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        enabled: false,
        onPageChanged: (_) => tapped++,
      );
      final disabled = _scheme(tester, CoreColors.disabledContent);

      for (final label in ['1', '…', '4', '5', '6', '10']) {
        expect(_textStyle(tester, label).color, disabled, reason: label);
      }
      expect(_textStyle(tester, '5').fontWeight, material.FontWeight.w600);
      expect(
        _decoration(tester, find.text('5')).color,
        _scheme(tester, CoreColors.disabledContainer),
      );
      final themed = tester.widget<material.IconTheme>(
        find
            .ancestor(
              of: find.byType(Icon).first,
              matching: find.byType(material.IconTheme),
            )
            .first,
      );
      expect(themed.data.color, disabled);

      expect(find.byType(Clickable), findsNothing);
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(tapped, 0);
    });

    testWidgets('an explicit enabled: true keeps a handler-less control '
        'coloured', (tester) async {
      await _pump(tester, enabled: true, withHandler: false);
      expect(
        _textStyle(tester, '4').color,
        _scheme(tester, CoreColors.onSurfaceVariant),
      );
    });

    testWidgets('an enabled control still pages', (tester) async {
      int? page;
      await _pump(tester, onPageChanged: (p) => page = p);
      await tester.tap(find.text('6'));
      await tester.pump();
      expect(page, 6);
    });
  });
}
