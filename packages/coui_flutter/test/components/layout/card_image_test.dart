import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) =>
    CoUIApp(theme: const ThemeData(), home: child);

void main() {
  _redesignTests();

  group('CardImage', () {
    testWidgets('renders with image', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const CardImage(
            image: material.Placeholder(),
          ),
        ),
      );

      expect(find.byType(CardImage), findsOneWidget);
    });

    testWidgets('renders with title', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const CardImage(
            image: material.Placeholder(),
            title: material.Text('Card title'),
          ),
        ),
      );

      expect(find.byType(CardImage), findsOneWidget);
      expect(find.text('Card title'), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const CardImage(
            image: material.Placeholder(),
            subtitle: material.Text('Card subtitle'),
            title: material.Text('Card title'),
          ),
        ),
      );

      expect(find.text('Card title'), findsOneWidget);
      expect(find.text('Card subtitle'), findsOneWidget);
    });

    testWidgets('renders with leading', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const CardImage(
            image: material.Placeholder(),
            leading: Icon(LucideIcons.image),
            title: material.Text('With leading'),
          ),
        ),
      );

      expect(find.text('With leading'), findsOneWidget);
    });

    testWidgets('renders with trailing', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const CardImage(
            image: material.Placeholder(),
            title: material.Text('With trailing'),
            trailing: Icon(LucideIcons.arrowRight),
          ),
        ),
      );

      expect(find.text('With trailing'), findsOneWidget);
    });

    testWidgets('onPressed callback is invoked on tap', (tester) async {
      var pressed = false;

      final _ = await tester.pumpWidget(
        _buildApp(
          CardImage(
            onPressed: () {
              pressed = true;
            },
            image: const material.Placeholder(),
            title: const material.Text('Tappable card'),
          ),
        ),
      );

      await tester.tap(find.byType(CardImage));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('enabled param controls interactivity', (tester) async {
      var pressed = false;

      final _ = await tester.pumpWidget(
        _buildApp(
          CardImage(
            onPressed: () {
              pressed = true;
            },
            enabled: false,
            image: const material.Placeholder(),
            title: const material.Text('Disabled card'),
          ),
        ),
      );

      await tester.tap(find.byType(CardImage));
      await tester.pump();

      expect(pressed, isFalse);
    });

    // The pressable card is wrapped in a `fixed` button for press, focus and
    // the role. That button's size row carries padding, which used to inset
    // the image and the text a second time: the card drew 16 px wider on the
    // inside and 16 px taller than the same card without `onPressed`, and than
    // the Web twin, whose role="button" `<div>` adds no inset.
    testWidgets('a pressable card is the size of one that is not', (
      tester,
    ) async {
      Future<Size> sizeOf({required bool pressable}) async {
        await tester.pumpWidget(
          _buildApp(
            material.Align(
              alignment: material.Alignment.topLeft,
              child: material.SizedBox(
                width: 240,
                child: CardImage(
                  image: const material.SizedBox(width: 240, height: 160),
                  onPressed: pressable ? () {} : null,
                  subtitle: const material.Text('해 뜰 무렵 촬영'),
                  title: const material.Text('산 풍경'),
                ),
              ),
            ),
          ),
        );
        return tester.getSize(find.byType(CardImage));
      }

      final plain = await sizeOf(pressable: false);
      final pressable = await sizeOf(pressable: true);

      expect(pressable, plain);
      expect(pressable.width, 240);
    });

    // The same wrapper's icon theme redrew every icon inside at the button's
    // own glyph size (16), so the built-in chevron came out smaller than the
    // Web twin's, which keeps the ambient size.
    testWidgets('the chevron of a pressable card keeps the ambient icon size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Align(
            alignment: material.Alignment.topLeft,
            child: material.SizedBox(
              width: 240,
              child: CardImage(
                image: const material.SizedBox(width: 240, height: 160),
                onPressed: () {},
                title: const material.Text('산 풍경'),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(Icon)),
        const Size.square(CoreIconStyle.defaultAmbientSize),
      );
    });

    testWidgets('the image of a pressable card starts at the card edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Align(
            alignment: material.Alignment.topLeft,
            child: CardImage(
              image: const material.SizedBox(
                key: material.ValueKey('img'),
                width: 240,
                height: 160,
              ),
              onPressed: () {},
              title: const material.Text('산 풍경'),
            ),
          ),
        ),
      );

      // Inside the card's own 1px edge and nothing more — no button inset.
      final card = tester.getTopLeft(find.byType(CardImage));
      final image = tester.getTopLeft(
        find.byKey(const material.ValueKey('img')),
      );
      const edge = CoreOutlinedContainerStyle.defaultBorderWidth;
      expect(image - card, const material.Offset(edge, edge));
    });

    testWidgets('renders in horizontal direction', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const CardImage(
            cardImageStyle: CoreCardImageStyle(direction: CoreAxis.horizontal),
            image: material.Placeholder(),
            title: material.Text('Horizontal card'),
          ),
        ),
      );

      expect(find.byType(CardImage), findsOneWidget);
    });
  });
}

// ─── The redesigned card, read off the rendered tree ────────────────────────
//
// Every expected value is built from the Core default it comes from, never a
// literal, so a retuned token moves the expectation with it — and every value
// is read from what was laid out or painted, so a value that is resolved but
// never reaches the widget still fails.

const material.ValueKey<String> _imageKey = material.ValueKey('img');
const material.ValueKey<String> _trailingKey = material.ValueKey('trailing');

material.Widget _card({
  bool? enabled,
  material.TextDirection direction = material.TextDirection.ltr,
}) => _buildApp(
  material.Directionality(
    textDirection: direction,
    child: material.Align(
      alignment: material.Alignment.topLeft,
      child: CardImage(
        image: const material.SizedBox(key: _imageKey, width: 238, height: 134),
        enabled: enabled,
        onPressed: () {},
        title: const material.Text('산 풍경'),
        subtitle: const material.Text('해 뜰 무렵 촬영'),
        trailing: const material.SizedBox(
          key: _trailingKey,
          width: 20,
          height: 20,
        ),
      ),
    ),
  ),
);

/// The painted decoration of the [index]-th composed `OutlinedContainer`
/// under the card — 0 is the card's box, 1 the image frame.
material.BoxDecoration _boxOf(WidgetTester tester, int index) {
  final box = find
      .descendant(
        of: find.byType(CardImage),
        matching: find.byType(OutlinedContainer),
      )
      .at(index);
  final container = tester.widget<material.AnimatedContainer>(
    find
        .descendant(of: box, matching: find.byType(material.AnimatedContainer))
        .first,
  );
  return container.decoration! as material.BoxDecoration;
}

material.Clip _clipOf(WidgetTester tester, int index) {
  final box = find
      .descendant(
        of: find.byType(CardImage),
        matching: find.byType(OutlinedContainer),
      )
      .at(index);
  return tester
      .widget<material.AnimatedContainer>(
        find
            .descendant(
              of: box,
              matching: find.byType(material.AnimatedContainer),
            )
            .first,
      )
      .clipBehavior;
}

material.Color _token(WidgetTester tester, CoreColorToken token) {
  final theme = Theme.of(tester.element(find.byType(CardImage)));
  return theme.colorScheme.resolve(CoreColor.token(token)).toValue();
}

material.TextStyle _textStyleOf(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

/// The opacities inside the card's box — the image layer's and the text
/// row's (the `fixed` button around a pressable card adds one of its own).
List<double> _opacities(WidgetTester tester) => [
  for (final o in tester.widgetList<material.Opacity>(
    find.descendant(
      of: find
          .descendant(
            of: find.byType(CardImage),
            matching: find.byType(OutlinedContainer),
          )
          .first,
      matching: find.byType(material.Opacity),
    ),
  ))
    o.opacity,
];

void _redesignTests() {
  group('CardImage — the card is a box', () {
    testWidgets('the box is surface with a 1px outline-variant edge, 16 '
        'corners and a clip', (tester) async {
      await tester.pumpWidget(_card());
      final box = _boxOf(tester, 0);
      final border = box.border! as material.Border;

      expect(box.color, _token(tester, CoreColors.surface));
      expect(border.top.color, _token(tester, CoreColors.outlineVariant));
      expect(border.top.width, CoreOutlinedContainerStyle.defaultBorderWidth);
      expect(
        box.borderRadius,
        material.BorderRadius.circular(
          CoreOutlinedContainerStyle.defaultBorderRadius.topLeft,
        ),
      );
      expect(_clipOf(tester, 0), isNot(material.Clip.none));
    });

    testWidgets('the box leaves 14 under the text row', (tester) async {
      await tester.pumpWidget(_card());
      final card = tester.getRect(find.byType(CardImage));
      final row = tester.getRect(find.byType(Basic));
      const edge = CoreOutlinedContainerStyle.defaultBorderWidth;

      expect(
        CoreCardImageStyle.defaultContainerStyle.padding!.bottom,
        CoreSpace.space14,
      );
      expect(card.bottom - row.bottom, CoreSpace.space14 + edge);
    });

    testWidgets('the image frame is a square surface-container fill', (
      tester,
    ) async {
      await tester.pumpWidget(_card());
      final frame = _boxOf(tester, 1);

      expect(frame.color, _token(tester, CoreColors.surfaceContainer));
      expect(frame.borderRadius, material.BorderRadius.zero);
      final border = frame.border as material.Border?;
      expect(
        border == null || border.top.width == 0 || border.top.color.a == 0,
        isTrue,
      );
    });

    testWidgets('the text row is set 14 from the start and 10 from the end', (
      tester,
    ) async {
      await tester.pumpWidget(_card());
      final card = tester.getRect(find.byType(CardImage));
      final title = tester.getRect(find.text('산 풍경'));
      final trailing = tester.getRect(find.byKey(_trailingKey));
      const edge = CoreOutlinedContainerStyle.defaultBorderWidth;

      expect(title.left - card.left, edge + CoreSpace.space14);
      expect(card.right - trailing.right, edge + CoreSpace.space10);
    });

    testWidgets('the insets follow the reading direction', (tester) async {
      await tester.pumpWidget(_card(direction: material.TextDirection.rtl));
      final basic = tester.getRect(find.byType(Basic));
      final row = tester.getRect(
        find
            .descendant(
              of: find.byType(Basic),
              matching: find.byType(material.Row),
            )
            .first,
      );

      // Start is the right in a right-to-left locale.
      expect(basic.right - row.right, CoreSpace.space14);
      expect(row.left - basic.left, CoreSpace.space10);
    });

    testWidgets('the title is 15 at semibold, the subtitle 13 in '
        'on-surface-variant', (tester) async {
      await tester.pumpWidget(_card());
      final title = _textStyleOf(tester, '산 풍경');
      final subtitle = _textStyleOf(tester, '해 뜰 무렵 촬영');

      expect(title.fontSize, CoreTypography.coui.labelXl.fontSize);
      expect(title.fontSize, CoreFontSize.s15);
      expect(title.fontWeight, material.FontWeight.w600);
      expect(subtitle.fontSize, CoreTypography.coui.bodySmall.fontSize);
      expect(subtitle.fontSize, CoreFontSize.s13);
      expect(subtitle.color, _token(tester, CoreColors.onSurfaceVariant));
    });

    testWidgets('a disabled card dims the image and the text row', (
      tester,
    ) async {
      await tester.pumpWidget(_card(enabled: false));

      expect(_opacities(tester), [CoreOpacity.disabled, CoreOpacity.disabled]);
      // The box itself keeps its fill and edge at full strength.
      expect(_boxOf(tester, 0).color, _token(tester, CoreColors.surface));
    });

    testWidgets('an enabled card dims nothing', (tester) async {
      await tester.pumpWidget(_card());

      expect(_opacities(tester), [1.0, 1.0]);
    });

    testWidgets('a card with no onPressed is content, and enabled: false '
        'does not dim it', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CardImage(
            image: material.SizedBox(width: 10, height: 10),
            enabled: false,
          ),
        ),
      );

      expect(_opacities(tester), [1.0, 1.0]);
    });

    testWidgets('an enabled card casts the xs stack from its box', (
      tester,
    ) async {
      await tester.pumpWidget(_card());
      final shadows = _boxOf(tester, 0).boxShadow!;
      final theme = Theme.of(tester.element(find.byType(CardImage)));

      expect(
        CoreCardImageStyle.defaultContainerStyle.boxShadow,
        CoreShadow.xs,
      );
      // Built through the kit's own conversion — the one that turns the
      // token's CSS blur into Flutter's and lets the active style bend it.
      expect(
        shadows,
        CoreShadow.xs.toValue(
          base: _token(tester, CoreColors.shadow),
          geometry: theme.geometry,
        ),
      );
    });

    testWidgets('a disabled card drops its cast', (tester) async {
      await tester.pumpWidget(_card(enabled: false));

      expect(_boxOf(tester, 0).boxShadow ?? const [], isEmpty);
      expect(
        find.descendant(
          of: find.byType(CardImage),
          matching: find.byType(InjectedCast),
        ),
        findsNothing,
      );
    });

    testWidgets('the disabled opacity is overridable', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          CardImage(
            image: const material.SizedBox(width: 10, height: 10),
            enabled: false,
            onPressed: () {},
            cardImageStyle: const CoreCardImageStyle(
              disabledContentOpacity: 0.5,
            ),
          ),
        ),
      );

      expect(_opacities(tester), [0.5, 0.5]);
    });
  });
}
