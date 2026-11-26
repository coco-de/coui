// #6470 — DescriptionCard redesign, read back from the rendered tree.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const List<DescriptionRow> _rows = [
  DescriptionRow(label: '요금제', value: 'Pro'),
  DescriptionRow(label: '좌석', value: '10석 중 5석'),
  DescriptionRow(label: '갱신일', value: '2027년 6월'),
];

const List<CoreDescriptionCardSize> _sizes = CoreDescriptionCardSize.values;
const _padding = [12.0, 14.0, 16.0, 18.0, 20.0];
const _radius = [12.0, 14.0, 16.0, 16.0, 16.0];
const _rowInset = [6.0, 6.0, 8.0, 8.0, 10.0];
const _iconSize = [16.0, 16.0, 18.0, 20.0, 20.0];

late ResolvedDescriptionCard _resolved;

Rect _titleRow(WidgetTester tester) => tester.getRect(
  find.ancestor(of: find.text('구독'), matching: find.byType(widgets.Row)).first,
);

Future<void> _pump(
  WidgetTester tester, {
  CoreDescriptionCardSize size = .md,
  CoreDescriptionCardVariant variant = .outlined,
}) async {
  await pumpTestApp(
    tester,
    widgets.SizedBox(
      width: 320,
      child: widgets.Builder(
        builder: (context) {
          _resolved = resolveDescriptionCard(
            context,
            variant: variant,
            size: size,
          );
          return DescriptionCard(
            title: '구독',
            titleLeading: const Icon(LucideIcons.creditCard),
            size: size,
            variant: variant,
            rows: _rows,
          );
        },
      ),
    ),
  );
}

void main() {
  for (var i = 0; i < _sizes.length; i += 1) {
    final size = _sizes[i];
    testWidgets('${size.name}: padding, corner, row inset, icon', (
      tester,
    ) async {
      await _pump(tester, size: size);

      final card = tester.getRect(find.byType(OutlinedContainer));
      final icon = tester.getRect(find.byType(Icon));
      // Outlined card: 1 px border inside the box, then the size padding.
      expect(icon.left - card.left, _padding[i] + 1);
      expect(_titleRow(tester).top - card.top, _padding[i] + 1);
      expect(
        _resolved.containerStyle.borderRadius,
        CoreBorderRadius.all(_radius[i]),
      );

      // Title leading icon — per-size glyph, on-surface-variant.
      expect(icon.size, Size.square(_iconSize[i]));
      final scheme = CoreThemePresets.light.colorScheme;
      expect(
        IconTheme.of(tester.element(find.byType(Icon))).color,
        scheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue(),
      );

      // Every row carries the vertical inset, rows touch (spacing 0).
      for (final row in _rows) {
        final padding = tester.widget<widgets.Padding>(
          find
              .ancestor(
                of: find.text(row.label),
                matching: find.byType(widgets.Padding),
              )
              .first,
        );
        expect(padding.padding, EdgeInsets.symmetric(vertical: _rowInset[i]));
      }
      expect(_resolved.rowSpacing, 0);
    });
  }

  testWidgets('divider under every row but the last (+ the title rule)', (
    tester,
  ) async {
    await _pump(tester);
    // 1 title rule + (rows − 1) row rules.
    expect(find.byType(Divider), findsNWidgets(1 + _rows.length - 1));
    final last = tester.getRect(find.text(_rows.last.label));
    for (final divider in find.byType(Divider).evaluate()) {
      final rect = tester.getRect(find.byWidget(divider.widget));
      expect(rect.top, lessThan(last.top));
    }
  });

  testWidgets('value text is right-aligned Medium, row centred', (
    tester,
  ) async {
    await _pump(tester);
    final value = tester.widget<widgets.RichText>(
      find.byWidgetPredicate(
        (w) => w is widgets.RichText && w.text.toPlainText() == 'Pro',
      ),
    );
    expect(value.textAlign, TextAlign.end);
    expect(value.text.style!.fontWeight, FontWeight.w500);
    final row = tester.widget<widgets.Row>(
      find
          .ancestor(of: find.text('요금제'), matching: find.byType(widgets.Row))
          .first,
    );
    expect(row.crossAxisAlignment, CrossAxisAlignment.center);
    // The value hugs the card's trailing edge.
    final card = tester.getRect(find.byType(OutlinedContainer));
    final valueRect = tester.getRect(find.text('Pro'));
    expect(card.right - valueRect.right, 16 + 1);
  });

  testWidgets('title is SemiBold', (tester) async {
    await _pump(tester);
    final title = tester.widget<widgets.RichText>(
      find.byWidgetPredicate(
        (w) => w is widgets.RichText && w.text.toPlainText() == '구독',
      ),
    );
    expect(title.text.style!.fontWeight, FontWeight.w600);
  });

  testWidgets('ghost: no fill, no border, no left / right inset', (
    tester,
  ) async {
    await _pump(tester, variant: .ghost);
    final card = tester.getRect(find.byType(OutlinedContainer));
    final icon = tester.getRect(find.byType(Icon));
    expect(icon.left - card.left, 0);
    expect(_titleRow(tester).top - card.top, 16);
    expect(_resolved.backgroundColor.a, 0);
    expect(_resolved.containerStyle.borderWidth, 0);
  });

  testWidgets('filled: surface-container face, no border', (tester) async {
    await _pump(tester, variant: .filled);
    final scheme = CoreThemePresets.light.colorScheme;
    expect(
      _resolved.containerStyle.backgroundColor,
      const CoreColor.token(CoreColors.surfaceContainer),
    );
    expect(_resolved.containerStyle.borderWidth, 0);
    expect(
      _resolved.backgroundColor,
      scheme
          .resolve(const CoreColor.token(CoreColors.surfaceContainer))
          .toValue(),
    );
  });

  group('enabled', () {
    // Product of every `Opacity` between [finder] and the root — what the
    // node is actually painted at.
    double paintedOpacity(WidgetTester tester, Finder finder) {
      var product = 1.0;
      for (final w in tester.widgetList<widgets.Opacity>(
        find.ancestor(of: finder, matching: find.byType(widgets.Opacity)),
      )) {
        product *= w.opacity;
      }
      return product;
    }

    Future<void> pumpCard(
      WidgetTester tester, {
      bool? enabled,
      void Function()? onTap,
      List<DescriptionRow> rows = _rows,
      Widget? bottomAction,
    }) => pumpTestApp(
      tester,
      widgets.SizedBox(
        width: 320,
        child: widgets.Builder(
          builder: (context) {
            _resolved = resolveDescriptionCard(
              context,
              variant: .outlined,
              size: .md,
            );
            return DescriptionCard(
              title: '구독',
              titleLeading: const Icon(LucideIcons.creditCard),
              rows: rows,
              onTap: onTap,
              enabled: enabled,
              bottomAction: bottomAction,
            );
          },
        ),
      ),
    );

    testWidgets('disabled: content at opacity/disabled, box at full', (
      tester,
    ) async {
      var taps = 0;
      await pumpCard(
        tester,
        enabled: false,
        onTap: () => taps += 1,
        bottomAction: const Text('요금제 관리'),
      );

      for (final text in ['구독', '요금제', 'Pro', '2027년 6월', '요금제 관리']) {
        expect(paintedOpacity(tester, find.text(text)), CoreOpacity.disabled);
      }
      expect(paintedOpacity(tester, find.byType(Icon)), CoreOpacity.disabled);
      // Every rule — title, rows, above the bottom action.
      for (final divider in find.byType(Divider).evaluate()) {
        expect(
          paintedOpacity(tester, find.byWidget(divider.widget)),
          CoreOpacity.disabled,
        );
      }
      // The box itself — background and border — is not dimmed.
      expect(paintedOpacity(tester, find.byType(OutlinedContainer)), 1);
      expect(_resolved.containerStyle.borderWidth, CoreStrokeWidth.stroke1);
      expect(
        _resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );

      // No press.
      await tester.tap(find.text('요금제'));
      await tester.pump();
      expect(taps, 0);
      expect(
        tester.widget<Clickable>(find.byType(Clickable)).enabled,
        isFalse,
      );
    });

    testWidgets('enabled by default with a tap target: not dimmed, presses', (
      tester,
    ) async {
      var taps = 0;
      await pumpCard(
        tester,
        onTap: () => taps += 1,
        bottomAction: const Text('요금제 관리'),
      );
      expect(paintedOpacity(tester, find.text('요금제')), 1);
      expect(paintedOpacity(tester, find.text('요금제 관리')), 1);
      await tester.tap(find.text('요금제'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a plain card (no tap target) never dims', (tester) async {
      await pumpCard(
        tester,
        enabled: false,
        bottomAction: const Text('요금제 관리'),
      );
      expect(paintedOpacity(tester, find.text('요금제')), 1);
      expect(paintedOpacity(tester, find.text('요금제 관리')), 1);
      expect(paintedOpacity(tester, find.byType(Icon)), 1);
      expect(find.byType(Clickable), findsNothing);
    });

    testWidgets('disabled row taps do not fire', (tester) async {
      var taps = 0;
      await pumpCard(
        tester,
        enabled: false,
        rows: [DescriptionRow(label: '좌석', value: '5', onTap: () => taps += 1)],
      );
      expect(paintedOpacity(tester, find.text('좌석')), CoreOpacity.disabled);
      await tester.tap(find.text('좌석'));
      await tester.pump();
      expect(taps, 0);
    });
  });
}
