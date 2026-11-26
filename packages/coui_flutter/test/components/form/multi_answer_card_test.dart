import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kBorderWidth = 2.0;
const _kSmallBorderWidth = 1.0;
const _kRadius = 8.0;

material.Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

void main() {
  group('MultiAnswerCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const MultiAnswerCard<String>(
            value: 'a',
            child: Text('Answer A'),
          ),
        ),
      );
      expect(find.text('Answer A'), findsOneWidget);
    });

    testWidgets('tapping fires onChanged with value', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _buildApp(
          MultiAnswerCard<String>(
            onChanged: (v) => picked = v,
            value: 'option-1',
            child: const Text('Option 1'),
          ),
        ),
      );
      await tester.tap(find.text('Option 1'));
      await tester.pump();
      expect(picked, equals('option-1'));
    });

    testWidgets('disabled card does not fire onChanged', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _buildApp(
          MultiAnswerCard<String>(
            onChanged: (v) => picked = v,
            value: 'x',
            enabled: false,
            child: const Text('Disabled'),
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(picked, isNull);
    });

    testWidgets('implements CoreMultiAnswerCardContract', (tester) async {
      const MultiAnswerCard<int> card = MultiAnswerCard(
        value: 1,
        child: Text('1'),
      );
      expect(card, isA<CoreMultiAnswerCardContract<int, Widget>>());
    });

    testWidgets('child text inherits the design-system base typography', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const MultiAnswerCard<String>(
            value: 'a',
            child: Text('Answer A'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // `bodyTextStyle` (bodyLarge, 15px at 150%) flows through
      // `DefaultTextStyle.merge` — without it the child inherits whatever
      // the host provides (this harness: MaterialApp's 48px fallback; under
      // a Material scaffold, Material's own 14px body) while the Web twin
      // inherits the CoUIWeb base, splitting the rendered text. The role now
      // shares Material's body size, so the line-height is pinned as well:
      // in a Material host it is what still tells the role apart.
      final context = tester.element(find.text('Answer A'));
      final style = material.DefaultTextStyle.of(context).style;
      final role = Theme.of(context).typography.bodyLarge;
      expect(style.fontSize, role.fontSize);
      expect(style.fontSize, 15);
      expect(style.height, role.lineHeight);
      expect(style.height, 1.5);
    });

    testWidgets('card size stays constant when selection toggles', (
      tester,
    ) async {
      Future<Size> pumpAndMeasure({required bool selected}) async {
        await tester.pumpWidget(
          _buildApp(
            MultiAnswerCard<String>(
              value: 'a',
              selected: selected,
              child: const Text('Answer A'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(MultiAnswerCard<String>));
      }

      final unselected = await pumpAndMeasure(selected: false);
      final selected = await pumpAndMeasure(selected: true);

      // The border is the same 1 px in every state, so a selection never
      // changes the card's height.
      expect(selected, unselected);
    });

    testWidgets('card size stays constant on hover', (tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pumpWidget(
        _buildApp(
          const MultiAnswerCard<String>(value: 'a', child: Text('Answer A')),
        ),
      );
      await tester.pumpAndSettle();
      final resting = tester.getSize(find.byType(MultiAnswerCard<String>));

      await mouse.moveTo(tester.getCenter(find.text('Answer A')));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(MultiAnswerCard<String>)), resting);
    });
  });

  group('MultiAnswerCard chrome', () {
    CoreOutlinedContainerStyle chromeOf(WidgetTester tester) => tester
        .widget<OutlinedContainer>(find.byType(OutlinedContainer).first)
        .containerStyle!;

    Future<void> pump(
      WidgetTester tester, {
      bool selected = false,
      bool enabled = true,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          MultiAnswerCard<String>(
            value: 'a',
            selected: selected,
            enabled: enabled,
            child: const Text('Answer A'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('resting card: surface fill, outline-variant 1 px, radius 12', (
      tester,
    ) async {
      await pump(tester);
      final chrome = chromeOf(tester);
      expect(
        chrome.backgroundColor,
        CoreMultiAnswerCardStyle.defaultBackgroundColor,
      );
      expect(
        chrome.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(chrome.borderWidth, CoreStrokeWidth.stroke1);
      expect(
        chrome.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
    });

    testWidgets('selected card: primary-container fill, same border width', (
      tester,
    ) async {
      await pump(tester, selected: true);
      final chrome = chromeOf(tester);
      expect(
        chrome.backgroundColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(chrome.borderColor, const CoreColor.token(CoreColors.primary));
      expect(chrome.borderWidth, CoreStrokeWidth.stroke1);
    });

    testWidgets('hovered card: outline border', (tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await pump(tester);
      await mouse.moveTo(tester.getCenter(find.text('Answer A')));
      await tester.pumpAndSettle();
      expect(
        chromeOf(tester).borderColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    testWidgets('disabled card: disabled tokens, no faded opacity', (
      tester,
    ) async {
      await pump(tester, selected: true, enabled: false);
      final chrome = chromeOf(tester);
      expect(
        chrome.backgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        chrome.borderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      final context = tester.element(find.text('Answer A'));
      final style = material.DefaultTextStyle.of(context).style;
      final scheme = Theme.of(context).colorScheme;
      expect(
        style.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.disabledContent))
            .toValue(),
      );
      expect(style.fontWeight, FontWeight.w400);
      // The Clickable's generic disabled fade is off — the dedicated
      // tokens are the only disabled treatment.
      final opacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(MultiAnswerCard<String>),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacities.where((o) => o.opacity < 1), isEmpty);
    });

    testWidgets('selected label takes the medium-weight label role', (
      tester,
    ) async {
      await pump(tester, selected: true);
      final context = tester.element(find.text('Answer A'));
      final style = material.DefaultTextStyle.of(context).style;
      expect(style.fontSize, 15);
      expect(style.fontWeight, FontWeight.w500);
    });

    testWidgets('composes a trailing lg Checkbox that follows selection', (
      tester,
    ) async {
      await pump(tester, selected: true);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.checked, isTrue);
      expect(checkbox.size, CoreComponentSize.lg);
      // Trailing: to the right of the answer text.
      expect(
        tester.getCenter(find.byType(Checkbox)).dx,
        greaterThan(tester.getCenter(find.text('Answer A')).dx),
      );

      await pump(tester, enabled: false);
      final disabled = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(disabled.checked, isFalse);
      expect(disabled.enabled, isFalse);
    });

    testWidgets('tapping the checkbox toggles through the card', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _buildApp(
          MultiAnswerCard<String>(
            value: 'a',
            onChanged: (_) => taps++,
            child: const Text('Answer A'),
          ),
        ),
      );
      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('CoreMultiAnswerCardStyle', () {
    test('merge overrides non-null fields', () {
      const base = CoreMultiAnswerCardStyle(borderWidth: _kSmallBorderWidth);
      const override = CoreMultiAnswerCardStyle(
        selectedBorderWidth: _kBorderWidth,
      );
      final merged = base.merge(override);
      expect(merged.borderWidth, equals(_kSmallBorderWidth));
      expect(merged.selectedBorderWidth, equals(_kBorderWidth));
    });

    test('copyWith replaces fields', () {
      const style = CoreMultiAnswerCardStyle(
        borderRadius: CoreBorderRadius.all(_kRadius),
      );
      final copy = style.copyWith(
        borderRadius: const CoreBorderRadius.all(_kBorderWidth),
      );
      expect(
        copy.borderRadius,
        equals(const CoreBorderRadius.all(_kBorderWidth)),
      );
    });
  });
}
