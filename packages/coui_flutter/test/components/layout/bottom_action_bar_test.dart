import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const ValueKey<String> _primary = ValueKey('primary');
const ValueKey<String> _secondary = ValueKey('secondary');

/// The width the bar is given, unless a case states another.
const double _width = 400;

/// The inset the bar's own padding leaves on each side, from the same
/// defaults the resolver reads.
const CoreEdgeInsets _inset = CoreBottomActionBarStyle.defaultPadding;
const double _gap = CoreBottomActionBarStyle.defaultSpacing;
const double _line = CoreBottomActionBarStyle.defaultDividerWidth;

/// What the actions have to share, side to side.
final double _inner = _width - _inset.left - _inset.right;

/// A fixed-height action: it takes the width its cell gives it, so the
/// arithmetic of the bar is exact.
SizedBox _action(Key key, {double height = 40}) =>
    SizedBox(key: key, height: height);

BottomActionBar _bar({
  CoreBottomActionBarLayout layout = .vertical,
  bool secondary = true,
  double primaryHeight = 40,
  double secondaryHeight = 40,
  Widget? description,
  bool showDivider = true,
  CoreBottomActionBarStyle? style,
}) => BottomActionBar(
  primaryAction: _action(_primary, height: primaryHeight),
  secondaryAction: secondary
      ? _action(_secondary, height: secondaryHeight)
      : null,
  description: description,
  layout: layout,
  showDivider: showDivider,
  bottomActionBarStyle: style,
);

/// `pumpTestApp` centres its child and gives it a `MediaQuery` with no
/// padding, so the width is stated and the device's insets are injected.
///
/// The harness's `Overlay` keeps the entries it was first given, so a
/// second pump in one case starts from an empty tree.
Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  double width = _width,
  EdgeInsets safeArea = .zero,
  TextDirection textDirection = .ltr,
  CoreComponentTheme? componentTheme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    MediaQuery(
      data: MediaQueryData(padding: safeArea),
      child: SizedBox(width: width, child: bar),
    ),
    theme: ThemeData.fromCore(CoreThemePresets.light),
    textDirection: textDirection,
    componentTheme: componentTheme,
    surfaceStyle: surfaceStyle,
  );
}

Rect _rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

Rect _barRect(WidgetTester tester) =>
    tester.getRect(find.byType(BottomActionBar));

/// The filled box — the outermost `Container` the bar draws.
Container _box(WidgetTester tester) => tester.widget<Container>(
  find
      .descendant(
        of: find.byType(BottomActionBar),
        matching: find.byType(Container),
      )
      .first,
);

BoxDecoration _decoration(WidgetTester tester) =>
    _box(tester).decoration! as BoxDecoration;

BorderSide _hairline(WidgetTester tester) =>
    (_decoration(tester).border! as Border).top;

TextStyle _ambient(WidgetTester tester, String text) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style;

Color _color(WidgetTester tester, CoreColor color) => Theme.of(
  tester.element(find.byType(BottomActionBar)),
).colorScheme.resolve(color).toValue();

void main() {
  group('BottomActionBar defaults', () {
    testWidgets('resolve to the Core default constants', (tester) async {
      late ResolvedBottomActionBar resolved;
      late ColorScheme scheme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveBottomActionBar(context);
            scheme = Theme.of(context).colorScheme;
            return const SizedBox();
          },
        ),
      );

      expect(
        resolved.backgroundColor,
        scheme
            .resolve(CoreBottomActionBarStyle.defaultBackgroundColor)
            .toValue(),
      );
      expect(
        resolved.padding,
        EdgeInsets.fromLTRB(
          _inset.left,
          _inset.top,
          _inset.right,
          _inset.bottom,
        ),
      );
      expect(resolved.spacing, _gap);
      expect(
        resolved.dividerColor,
        scheme.resolve(CoreBottomActionBarStyle.defaultDividerColor).toValue(),
      );
      expect(resolved.dividerWidth, _line);
      expect(resolved.descriptionTextAlign, TextAlign.center);
      expect(
        resolved.descriptionTextStyle.color,
        scheme
            .resolve(
              CoreBottomActionBarStyle.defaultDescriptionTextStyle.color!,
            )
            .toValue(),
      );
      expect(resolved.surfaceBlur, isNull, reason: 'no material by default');
      expect(resolved.surfaceSheen, isNull);
    });

    testWidgets('the surface is the opaque page colour', (tester) async {
      await _pump(tester, _bar());

      expect(
        _decoration(tester).color,
        _color(tester, CoreBottomActionBarStyle.defaultBackgroundColor),
      );
      expect(_decoration(tester).color!.a, 1);
    });

    testWidgets('the default tree draws no surface pass', (tester) async {
      await _pump(tester, _bar());

      expect(
        find.descendant(
          of: find.byType(BottomActionBar),
          matching: find.byType(SurfaceBlur),
        ),
        findsNothing,
      );
    });

    testWidgets('the hairline is outlineVariant, one stroke, on top only', (
      tester,
    ) async {
      await _pump(tester, _bar());

      final border = _decoration(tester).border! as Border;
      expect(border.top.width, _line);
      expect(
        border.top.color,
        _color(tester, CoreBottomActionBarStyle.defaultDividerColor),
      );
      expect(border.bottom, BorderSide.none);
      expect(border.left, BorderSide.none);
      expect(border.right, BorderSide.none);
    });

    testWidgets('copyWith keeps every field it is not given', (tester) async {
      const style = CoreBottomActionBarStyle(spacing: 3);
      const bar = BottomActionBar(
        key: ValueKey('bar'),
        primaryAction: SizedBox(),
        secondaryAction: Text('secondary'),
        description: Text('note'),
        layout: .horizontal,
        showDivider: false,
        bottomActionBarStyle: style,
      );

      final copy = bar.copyWith(showDivider: true);

      expect(copy.key, const ValueKey('bar'));
      expect(copy.primaryAction, same(bar.primaryAction));
      expect(copy.secondaryAction, same(bar.secondaryAction));
      expect(copy.description, same(bar.description));
      expect(copy.layout, CoreBottomActionBarLayout.horizontal);
      expect(copy.showDivider, isTrue);
      expect(copy.bottomActionBarStyle, style);
    });
  });

  group('BottomActionBar vertical layout', () {
    testWidgets('stacks the primary action over the secondary, full width', (
      tester,
    ) async {
      await _pump(tester, _bar());

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);

      expect(primary.left - bar.left, _inset.left);
      expect(bar.right - primary.right, _inset.right);
      expect(primary.width, _inner);
      expect(secondary.left, primary.left);
      expect(secondary.width, _inner);
      expect(primary.top, lessThan(secondary.top));
      expect(secondary.top - primary.bottom, _gap);
    });

    testWidgets('the hairline and the padding frame the actions', (
      tester,
    ) async {
      await _pump(tester, _bar());

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);

      expect(primary.top - bar.top, _line + _inset.top);
      expect(bar.bottom - secondary.bottom, _inset.bottom);
      expect(bar.height, _line + _inset.top + 40 + _gap + 40 + _inset.bottom);
      expect(bar.width, _width);
    });

    testWidgets('a lone primary action fills the column', (tester) async {
      await _pump(tester, _bar(secondary: false));

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);

      expect(primary.width, _inner);
      expect(find.byKey(_secondary), findsNothing);
      expect(bar.height, _line + _inset.top + 40 + _inset.bottom);
    });
  });

  group('BottomActionBar weighted · icon · summary layouts', () {
    const ownWidth = 104.0;
    BottomActionBar ownWidthBar(CoreBottomActionBarLayout layout) =>
        BottomActionBar(
          primaryAction: _action(_primary),
          secondaryAction: const SizedBox(
            key: _secondary,
            width: ownWidth,
            height: 40,
          ),
          layout: layout,
        );

    for (final layout in [
      CoreBottomActionBarLayout.weighted,
      CoreBottomActionBarLayout.icon,
    ]) {
      testWidgets('$layout keeps the secondary action at its own width and '
          'gives the primary action the rest', (tester) async {
        await _pump(tester, ownWidthBar(layout));

        final bar = _barRect(tester);
        final primary = _rectOf(tester, _primary);
        final secondary = _rectOf(tester, _secondary);

        expect(secondary.left - bar.left, _inset.left);
        expect(secondary.width, ownWidth);
        expect(secondary.right + _gap, primary.left);
        expect(primary.width, _inner - ownWidth - _gap);
        expect(bar.right - primary.right, _inset.right);
      });
    }

    testWidgets('a lone primary action fills the weighted row', (tester) async {
      await _pump(tester, _bar(layout: .weighted, secondary: false));

      expect(_rectOf(tester, _primary).width, _inner);
    });

    testWidgets('summary sets the caption over the figure, at their own '
        'width, and the primary action takes the rest', (tester) async {
      const label = ValueKey<String>('label');
      const value = ValueKey<String>('value');
      await _pump(
        tester,
        BottomActionBar(
          primaryAction: _action(_primary),
          secondaryAction: _action(_secondary),
          summaryLabel: const SizedBox(key: label, width: 60, height: 16),
          summaryValue: const SizedBox(key: value, width: 90, height: 21),
          layout: .summary,
        ),
      );

      final bar = _barRect(tester);
      final labelRect = _rectOf(tester, label);
      final valueRect = _rectOf(tester, value);
      final primary = _rectOf(tester, _primary);

      expect(labelRect.left - bar.left, _inset.left);
      expect(valueRect.left, labelRect.left);
      expect(valueRect.top, labelRect.bottom);
      expect(primary.left, labelRect.left + 90 + _gap);
      expect(bar.right - primary.right, _inset.right);
      expect(find.byKey(_secondary), findsNothing);
    });

    testWidgets('summaryCompact puts the summary first and the primary '
        'action at its own width at the end, centred across', (tester) async {
      const label = ValueKey<String>('label');
      const value = ValueKey<String>('value');
      await _pump(
        tester,
        BottomActionBar(
          primaryAction: const SizedBox(key: _primary, width: 96, height: 48),
          secondaryAction: _action(_secondary),
          summaryLabel: const SizedBox(key: label, width: 60, height: 16),
          summaryValue: const SizedBox(key: value, width: 90, height: 21),
          layout: .summaryCompact,
        ),
      );

      final bar = _barRect(tester);
      final labelRect = _rectOf(tester, label);
      final valueRect = _rectOf(tester, value);
      final primary = _rectOf(tester, _primary);

      expect(labelRect.left - bar.left, _inset.left);
      expect(valueRect.left, labelRect.left);
      expect(valueRect.top, labelRect.bottom);
      expect(primary.width, 96);
      expect(bar.right - primary.right, _inset.right);
      // The summary (37 high) and the 48-high action share a centre line.
      expect(
        (labelRect.top + valueRect.bottom) / 2,
        moreOrLessEquals(primary.center.dy),
      );
      expect(find.byKey(_secondary), findsNothing);
    });

    testWidgets('summaryCompact without a summary still ends on the primary '
        'action', (tester) async {
      await _pump(
        tester,
        const BottomActionBar(
          primaryAction: SizedBox(key: _primary, width: 96, height: 48),
          layout: .summaryCompact,
        ),
      );

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);
      expect(primary.width, 96);
      expect(bar.right - primary.right, _inset.right);
    });

    testWidgets('the summary caption and figure take their own text styles', (
      tester,
    ) async {
      await _pump(
        tester,
        BottomActionBar(
          primaryAction: _action(_primary),
          summaryLabel: const Text('label'),
          summaryValue: const Text('value'),
          layout: .summary,
        ),
      );
      final theme = Theme.of(tester.element(find.text('label')));
      final label = tester.widget<Text>(find.text('label'));
      final value = tester.widget<Text>(find.text('value'));
      final labelStyle = DefaultTextStyle.of(
        tester.element(find.text('label')),
      );
      final valueStyle = DefaultTextStyle.of(
        tester.element(find.text('value')),
      );

      expect(label.style, isNull);
      expect(value.style, isNull);
      expect(
        labelStyle.style.fontSize,
        CoreBottomActionBarStyle.defaultSummaryLabelTextStyle
            .toValue(theme: theme)
            .fontSize,
      );
      expect(
        valueStyle.style.fontSize,
        CoreBottomActionBarStyle.defaultSummaryValueTextStyle
            .toValue(theme: theme)
            .fontSize,
      );
      expect(valueStyle.style.fontSize, 18);
    });
  });

  group('BottomActionBar horizontal layout', () {
    testWidgets('sets the secondary action before the primary, equal width', (
      tester,
    ) async {
      await _pump(tester, _bar(layout: .horizontal));

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);
      final cell = (_inner - _gap) / 2;

      expect(secondary.left - bar.left, _inset.left);
      expect(secondary.width, cell);
      expect(primary.width, cell);
      expect(secondary.right + _gap, primary.left);
      expect(bar.right - primary.right, _inset.right);
      expect(secondary.top, primary.top);
    });

    testWidgets('a lone primary action fills the row', (tester) async {
      await _pump(tester, _bar(layout: .horizontal, secondary: false));

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);

      expect(primary.left - bar.left, _inset.left);
      expect(primary.width, _inner);
    });

    testWidgets('actions of different heights share a centre line', (
      tester,
    ) async {
      await _pump(
        tester,
        _bar(layout: .horizontal, secondaryHeight: 56),
      );

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);

      expect(primary.center.dy, secondary.center.dy);
      expect(primary.height, 40, reason: 'the cell does not stretch it');
      expect(bar.height, _line + _inset.top + 56 + _inset.bottom);
    });

    testWidgets('mirrors in a right-to-left locale', (tester) async {
      await _pump(tester, _bar(layout: .horizontal), textDirection: .rtl);

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);

      expect(secondary.left, greaterThan(primary.left));
      expect(bar.right - secondary.right, _inset.right);
      expect(primary.left - bar.left, _inset.left);
    });
  });

  group('BottomActionBar note', () {
    const note = Text('By continuing you agree to the terms.');

    testWidgets('sits above the actions, the width of the bar', (
      tester,
    ) async {
      await _pump(tester, _bar(description: note));

      final text = tester.getRect(find.text(note.data!));
      final primary = _rectOf(tester, _primary);

      expect(text.bottom, lessThanOrEqualTo(primary.top));
      expect(primary.top - tester.getRect(_noteBox(note)).bottom, _gap);
      expect(tester.getRect(_noteBox(note)).width, _inner);
    });

    testWidgets('sits above the row in the horizontal layout', (tester) async {
      await _pump(tester, _bar(layout: .horizontal, description: note));

      final secondary = _rectOf(tester, _secondary);
      final box = tester.getRect(_noteBox(note));

      expect(secondary.top - box.bottom, _gap);
      expect(box.width, _inner);
    });

    testWidgets('takes bodySmall in onSurfaceVariant, centred', (
      tester,
    ) async {
      await _pump(tester, _bar(description: note));

      final style = _ambient(tester, note.data!);
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w400);
      expect(
        style.color,
        _color(tester, const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
      expect(
        tester
            .widget<DefaultTextStyle>(
              find
                  .ancestor(
                    of: find.text(note.data!),
                    matching: find.byType(DefaultTextStyle),
                  )
                  .first,
            )
            .textAlign,
        TextAlign.center,
      );
    });

    testWidgets('takes the style and the alignment the style states', (
      tester,
    ) async {
      await _pump(
        tester,
        _bar(
          description: note,
          style: const CoreBottomActionBarStyle(
            descriptionTextStyle: CoreTextStyle(fontSize: 20),
            descriptionTextAlign: .start,
          ),
        ),
      );

      final style = _ambient(tester, note.data!);
      expect(style.fontSize, 20);
      expect(
        style.color,
        _color(tester, const CoreColor.token(CoreColors.onSurfaceVariant)),
        reason: 'the fields it does not state keep the default',
      );
      expect(
        tester
            .widget<DefaultTextStyle>(
              find
                  .ancestor(
                    of: find.text(note.data!),
                    matching: find.byType(DefaultTextStyle),
                  )
                  .first,
            )
            .textAlign,
        TextAlign.start,
      );
    });

    testWidgets('an absent note leaves no gap', (tester) async {
      await _pump(tester, _bar());

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);

      expect(primary.top - bar.top, _line + _inset.top);
    });
  });

  group('BottomActionBar hairline', () {
    testWidgets('showDivider adds exactly its width to the height', (
      tester,
    ) async {
      await _pump(tester, _bar());
      final withLine = _barRect(tester).height;
      expect(_decoration(tester).border, isNotNull);

      await _pump(tester, _bar(showDivider: false));
      final withoutLine = _barRect(tester).height;

      expect(_decoration(tester).border, isNull);
      expect(withLine - withoutLine, _line);
    });

    testWidgets('a zero width states no border at all', (tester) async {
      // `BorderSide(width: 0)` would paint a one-pixel line in Flutter while
      // the Web twin's `border-top-width: 0` draws nothing.
      await _pump(
        tester,
        _bar(style: const CoreBottomActionBarStyle(dividerWidth: 0)),
      );
      final flat = _barRect(tester).height;

      expect(_decoration(tester).border, isNull);

      await _pump(tester, _bar(showDivider: false));
      expect(flat, _barRect(tester).height);
    });

    testWidgets('the actions do not move relative to the bar bottom', (
      tester,
    ) async {
      await _pump(tester, _bar(showDivider: false));

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);

      expect(primary.top - bar.top, _inset.top);
    });
  });

  group('BottomActionBar safe area', () {
    const home = EdgeInsets.only(bottom: 34);

    testWidgets('is added to the bottom padding', (tester) async {
      await _pump(tester, _bar());
      final flat = _barRect(tester).height;

      await _pump(tester, _bar(), safeArea: home);
      final bar = _barRect(tester);
      final secondary = _rectOf(tester, _secondary);

      expect(bar.height - flat, 34);
      expect(bar.bottom - secondary.bottom, _inset.bottom + 34);
    });

    testWidgets('is painted under: the filled box reaches the screen edge', (
      tester,
    ) async {
      await _pump(tester, _bar(), safeArea: home);

      final bar = _barRect(tester);
      final box = tester.getRect(
        find
            .descendant(
              of: find.byType(BottomActionBar),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(box, bar);
      expect(box.bottom, bar.bottom);
    });

    testWidgets('leaves the top and the sides to the page', (tester) async {
      await _pump(
        tester,
        _bar(),
        safeArea: const EdgeInsets.fromLTRB(10, 47, 10, 34),
      );

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);

      expect(primary.left - bar.left, _inset.left);
      expect(bar.right - primary.right, _inset.right);
      expect(primary.top - bar.top, _line + _inset.top);
    });

    testWidgets('a bar the style gives no bottom padding still clears it', (
      tester,
    ) async {
      await _pump(
        tester,
        _bar(
          style: const CoreBottomActionBarStyle(
            padding: CoreEdgeInsets.symmetric(horizontal: 20),
          ),
        ),
        safeArea: home,
      );

      final bar = _barRect(tester);
      final secondary = _rectOf(tester, _secondary);

      expect(bar.bottom - secondary.bottom, 34);
    });
  });

  group('BottomActionBar style', () {
    testWidgets('instance beats theme beats default', (tester) async {
      await _pump(
        tester,
        _bar(style: const CoreBottomActionBarStyle(spacing: 24)),
        componentTheme: const CoreComponentTheme(
          bottomActionBar: CoreBottomActionBarTheme(
            style: CoreBottomActionBarStyle(spacing: 16, dividerWidth: 2),
          ),
        ),
      );

      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);

      expect(secondary.top - primary.bottom, 24, reason: 'instance wins');
      expect(_hairline(tester).width, 2, reason: 'theme beats the default');
      expect(
        _rectOf(tester, _primary).left - _barRect(tester).left,
        _inset.left,
        reason: 'a field neither states keeps its default',
      );
    });

    testWidgets('a stated hairline colour reaches the hairline', (
      tester,
    ) async {
      const instance = CoreColor.token(CoreColors.primary);
      const theme = CoreColor.token(CoreColors.tertiary);
      assert(instance != theme, 'the two sources must differ');

      await _pump(
        tester,
        _bar(style: const CoreBottomActionBarStyle(dividerColor: instance)),
        componentTheme: const CoreComponentTheme(
          bottomActionBar: CoreBottomActionBarTheme(
            style: CoreBottomActionBarStyle(dividerColor: theme),
          ),
        ),
      );
      expect(_hairline(tester).color, _color(tester, instance));

      await _pump(
        tester,
        _bar(),
        componentTheme: const CoreComponentTheme(
          bottomActionBar: CoreBottomActionBarTheme(
            style: CoreBottomActionBarStyle(dividerColor: theme),
          ),
        ),
      );
      expect(_hairline(tester).color, _color(tester, theme));
    });

    testWidgets('a theme alone moves the defaults', (tester) async {
      await _pump(
        tester,
        _bar(),
        componentTheme: const CoreComponentTheme(
          bottomActionBar: CoreBottomActionBarTheme(
            style: CoreBottomActionBarStyle(
              backgroundColor: CoreColor.token(CoreColors.primary),
              padding: CoreEdgeInsets.all(8),
            ),
          ),
        ),
      );

      final bar = _barRect(tester);
      final primary = _rectOf(tester, _primary);

      expect(
        _decoration(tester).color,
        _color(tester, const CoreColor.token(CoreColors.primary)),
      );
      expect(primary.left - bar.left, 8);
      expect(primary.top - bar.top, _line + 8);
    });

    testWidgets('withStyle merges into the slot, later patches win', (
      tester,
    ) async {
      final bar = _bar(
        style: const CoreBottomActionBarStyle(
          padding: CoreEdgeInsets.all(10),
          spacing: 24,
        ),
      ).withStyle(const CoreBottomActionBarStyle(spacing: 4, dividerWidth: 3));
      expect(
        bar.bottomActionBarStyle,
        const CoreBottomActionBarStyle(
          padding: CoreEdgeInsets.all(10),
          spacing: 4,
          dividerWidth: 3,
        ),
      );

      await _pump(
        tester,
        bar.withStyle(const CoreBottomActionBarStyle(spacing: 6)),
      );

      final primary = _rectOf(tester, _primary);
      final secondary = _rectOf(tester, _secondary);

      expect(secondary.top - primary.bottom, 6);
      expect(_hairline(tester).width, 3);
      expect(primary.left - _barRect(tester).left, 10);
    });

    testWidgets('a start / end padding resolves against the text direction', (
      tester,
    ) async {
      const style = CoreBottomActionBarStyle(
        padding: CoreEdgeInsets.directional(
          start: 30,
          end: 10,
          top: 12,
          bottom: 12,
        ),
      );

      await _pump(tester, _bar(style: style));
      expect(tester.takeException(), isNull);
      expect(_rectOf(tester, _primary).left - _barRect(tester).left, 30);
      expect(_barRect(tester).right - _rectOf(tester, _primary).right, 10);

      await _pump(tester, _bar(style: style), textDirection: .rtl);
      expect(tester.takeException(), isNull);
      expect(_barRect(tester).right - _rectOf(tester, _primary).right, 30);
      expect(_rectOf(tester, _primary).left - _barRect(tester).left, 10);
    });

    testWidgets('a surface style bends the hairline through the geometry', (
      tester,
    ) async {
      final theme = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: .neoBrutalism,
        highContrast: false,
      );
      final bent = theme.geometry.stroke(_line, scaling: theme.scaling);
      expect(bent, isNot(_line), reason: 'this preset raises the stroke floor');

      await _pump(tester, _bar(), surfaceStyle: .neoBrutalism);

      expect(_hairline(tester).width, bent);
      expect(
        _rectOf(tester, _primary).top - _barRect(tester).top,
        bent + _inset.top,
      );
    });
  });

  group('BottomActionBar with real buttons', () {
    Widget primary() => Button(
      size: .xl,
      onPressed: () {},
      child: const Text('Register'),
    );

    Widget secondary() => Button(
      variant: .ghost,
      onPressed: () {},
      leading: const Icon(LucideIcons.x),
      child: const Text('Not now'),
    );

    testWidgets('fill the column without an expanded of their own', (
      tester,
    ) async {
      await _pump(
        tester,
        BottomActionBar(primaryAction: primary(), secondaryAction: secondary()),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.widgetWithText(Button, 'Register')).width,
        _inner,
      );
      expect(
        tester.getSize(find.widgetWithText(Button, 'Not now')).width,
        _inner,
      );
    });

    testWidgets('fill their cells in the row', (tester) async {
      await _pump(
        tester,
        BottomActionBar(
          primaryAction: primary(),
          secondaryAction: secondary(),
          layout: .horizontal,
        ),
      );

      final cell = (_inner - _gap) / 2;
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.widgetWithText(Button, 'Register')).width,
        cell,
      );
      expect(
        tester.getSize(find.widgetWithText(Button, 'Not now')).width,
        cell,
      );
    });

    testWidgets('a lone button fills the row', (tester) async {
      await _pump(
        tester,
        BottomActionBar(primaryAction: primary(), layout: .horizontal),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.widgetWithText(Button, 'Register')).width,
        _inner,
      );
    });

    testWidgets('fit a narrow screen without overflowing', (tester) async {
      await _pump(
        tester,
        BottomActionBar(
          primaryAction: primary(),
          secondaryAction: secondary(),
          description: const Text(
            'By continuing you agree to the terms of service and the '
            'privacy policy.',
          ),
          layout: .horizontal,
        ),
        width: 320,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('sits in a Scaffold footer, which hands it the full width', (
      tester,
    ) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Scaffold(
            footers: [
              BottomActionBar(
                primaryAction: primary(),
                secondaryAction: secondary(),
              ),
            ],
            child: const SizedBox.expand(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(BottomActionBar)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });
  });

  group('BottomActionBar in a Scaffold footer with a device inset', () {
    testWidgets('adds the home indicator to its own bottom padding once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(_width, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Scaffold(footers: [_bar()], child: const SizedBox.expand()),
        ),
      );

      final bar = _barRect(tester);
      final secondary = _rectOf(tester, _secondary);

      expect(bar.bottom, 800, reason: 'the bar is docked to the screen');
      expect(
        bar.bottom - secondary.bottom,
        _inset.bottom + 34,
        reason:
            'Scaffold adds no bottom inset of its own, so it is not doubled',
      );
      expect(
        bar.height,
        _line + _inset.top + 40 + _gap + 40 + _inset.bottom + 34,
      );
    });
  });

  group('BottomActionBar semantics', () {
    testWidgets('is a group container with no accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _bar());

      final semantics = tester.widget<CoUISemantics>(
        find.descendant(
          of: find.byType(BottomActionBar),
          matching: find.byType(CoUISemantics),
        ),
      );
      expect(semantics.role, CoreSemanticRole.group);
      expect(semantics.container, isTrue);
      expect(semantics.label, isNull);
      expect(
        tester
            .getSemantics(find.byType(CoUISemantics).first)
            .getSemanticsData()
            .label,
        isEmpty,
      );
      handle.dispose();
    });
  });

  group('BottomActionBar surface material', () {
    ThemeData styled(CoreSurfaceStyleId style) => applySurfaceStyle(
      ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      highContrast: false,
    );

    Future<void> pumpApp(
      WidgetTester tester,
      CoreSurfaceStyleId style,
      Widget bar,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: style,
          home: Center(
            child: SizedBox(width: _width, child: bar),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Iterable<SurfaceBlur> blurs(WidgetTester tester) =>
        tester.widgetList<SurfaceBlur>(
          find.descendant(
            of: find.byType(BottomActionBar),
            matching: find.byType(SurfaceBlur),
          ),
        );

    testWidgets('glass: the bar is frosted, faded and bent', (tester) async {
      await pumpApp(tester, .liquidGlass, _bar());

      final theme = styled(.liquidGlass);
      final glass = theme.surfaceFor(.functional)!;
      final pass = blurs(tester);
      expect(pass, hasLength(1), reason: 'the bar is one surface');
      expect(pass.single.surfaceBlur, glass.blurRadius);
      expect(pass.single.surfaceBlur, greaterThan(0));
      expect(pass.single.surfaceSheen, isNotNull);
      expect(pass.single.refraction, isNotNull, reason: 'glass bends');

      final fill = _decoration(tester).color!;
      final token = _color(
        tester,
        CoreBottomActionBarStyle.defaultBackgroundColor,
      );
      expect(fill.a, lessThan(1), reason: 'the blur has to show through');
      expect(fill.a, closeTo(token.a * glass.opacityIn(theme), 0.01));
    });

    testWidgets('glass: the pass wraps the whole box, safe area included', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .liquidGlass,
          home: MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
            child: Center(
              child: SizedBox(width: _width, child: _bar()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pass = tester.getRect(find.byType(SurfaceBlur));
      final box = tester.getRect(
        find
            .descendant(
              of: find.byType(BottomActionBar),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(pass, box);
      expect(
        box.bottom - _rectOf(tester, _secondary).bottom,
        _inset.bottom + 34,
      );
    });

    testWidgets('glass: a material that draws its own edge drops the hairline '
        'colour but keeps its width', (tester) async {
      await pumpApp(tester, .liquidGlass, _bar());

      expect(
        styled(.liquidGlass).surfaceFor(.functional)!.drawsOwnEdge,
        isTrue,
      );
      expect(_hairline(tester).color.a, 0);
      expect(_hairline(tester).width, _line);
    });

    testWidgets('glass: a fill-less bar stacks no pass over nothing', (
      tester,
    ) async {
      await pumpApp(
        tester,
        .liquidGlass,
        _bar(
          style: const CoreBottomActionBarStyle(
            backgroundColor: CoreColor.transparent,
          ),
        ),
      );

      expect(blurs(tester), isEmpty);
    });

    testWidgets('glass: a fill-less bar keeps the hairline it states', (
      tester,
    ) async {
      // No pass is stacked, so no material is there to draw an edge: the
      // hairline is the bar's only edge and keeps its colour.
      await pumpApp(
        tester,
        .liquidGlass,
        _bar(
          style: const CoreBottomActionBarStyle(
            backgroundColor: CoreColor.transparent,
          ),
        ),
      );

      expect(blurs(tester), isEmpty);
      expect(
        _hairline(tester).color,
        _color(tester, CoreBottomActionBarStyle.defaultDividerColor),
      );
      expect(_hairline(tester).color.a, greaterThan(0));
    });

    testWidgets('a style with no material keeps the plain tree', (
      tester,
    ) async {
      await pumpApp(tester, .defaultStyle, _bar());

      expect(blurs(tester), isEmpty);
      expect(_decoration(tester).color!.a, 1);
    });
  });
}

/// The note's own box — the `DefaultTextStyle` its `Text` sits under.
Finder _noteBox(Text note) => find
    .ancestor(
      of: find.text(note.data!),
      matching: find.byType(DefaultTextStyle),
    )
    .first;
