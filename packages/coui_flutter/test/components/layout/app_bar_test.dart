import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

BoxDecoration _barDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(AppBar),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  group('AppBar chrome', () {
    testWidgets('default render draws the divider and stands 64 tall', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title')),
      );

      expect(tester.getSize(find.byType(AppBar)).height, 64);

      final decoration = _barDecoration(tester);
      final border = decoration.border;
      expect(border, isA<Border>(), reason: 'divider renders as a border');
      final bottom = (border! as Border).bottom;
      expect(bottom.width, 1, reason: 'hairline divider is stroke1');
      expect(
        decoration.boxShadow,
        isNull,
        reason: 'no elevated shadow by default',
      );
    });

    testWidgets('showDivider: false drops the bottom border', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), showDivider: false),
      );

      expect(_barDecoration(tester).border, isNull);
    });

    testWidgets('variant compact renders 56 tall', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.compact),
      );
      expect(tester.getSize(find.byType(AppBar)).height, 56);
    });

    testWidgets('variant dense renders 48 tall', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.dense),
      );
      expect(tester.getSize(find.byType(AppBar)).height, 48);
    });

    testWidgets('variant medium renders 112 tall', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.medium),
      );
      expect(tester.getSize(find.byType(AppBar)).height, 112);
    });

    testWidgets('medium places the title in the bottom block', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.medium),
      );

      final barTop = tester.getTopLeft(find.byType(AppBar)).dy;
      final titleTop = tester.getTopLeft(find.text('Title')).dy;
      expect(
        titleTop - barTop,
        greaterThanOrEqualTo(48),
        reason: 'title sits below the 48px top row',
      );
    });

    testWidgets('elevated: true paints the drop-shadow stack', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), elevated: true),
      );

      final decoration = _barDecoration(tester);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('appBarStyle.padding reaches the bar', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(
          title: Text('Title'),
          appBarStyle: CoreAppBarStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space16),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(of: find.byType(AppBar), matching: find.byType(Padding))
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(CoreSpace.space16));
    });

    testWidgets('centerTitle centres the title text', (tester) async {
      await pumpTestApp(
        tester,
        const AppBar(title: Text('Title'), centerTitle: true),
      );

      final defaultStyle = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Title'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(defaultStyle.textAlign, TextAlign.center);
    });

    testWidgets('medium + centerTitle bottom-centres the title block', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const AppBar(
          title: Text('Title'),
          variant: CoreAppBarVariant.medium,
          centerTitle: true,
        ),
      );

      final align = tester.widget<Align>(
        find
            .descendant(of: find.byType(AppBar), matching: find.byType(Align))
            .first,
      );
      expect(align.alignment, Alignment.bottomCenter);
    });
  });

  // The title's own inset, measured as rendered.
  //
  // `titlePadding` is a Core default for all three variants and the Web twin
  // emits it on the title element unconditionally, but the Flutter widget
  // read it in the `medium` branch only — so the single-row variants drew
  // their titles 8px left of Web. Nothing caught it: the branch guard reads
  // a field "somewhere in the file", and the chrome tests above assert the
  // bar's outer padding, not the title's.
  //
  // The expected value is derived from the Core constants and the theme's
  // own `scaling` rather than written as a number: a hardcoded 16 would pass
  // against a widget that hardcoded 16 too, which is the fake fix this group
  // exists to kill.
  group('AppBar title inset', () {
    /// Distance from the bar's left edge to the title's, plus the scaling
    /// the theme applied.
    Future<({double inset, double scaling})> titleInset(
      WidgetTester tester,
      AppBar bar,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return bar;
          },
        ),
      );
      final barLeft = tester.getTopLeft(find.byType(AppBar)).dx;
      final titleLeft = tester.getTopLeft(find.text('Title')).dx;
      return (inset: titleLeft - barLeft, scaling: scaling);
    }

    /// Bar inset + title inset for [variant], in unscaled logical px.
    double expectedInset(CoreAppBarVariant variant) =>
        (CoreAppBarStyle.defaultsByVariant[variant]!.padding ??
                CoreAppBarStyle.defaultPadding)
            .toValue()
            .left +
        CoreAppBarStyle.defaultsByVariant[variant]!.titlePadding!
            .toValue()
            .left;

    testWidgets('standard indents the title by bar padding + titlePadding', (
      tester,
    ) async {
      final measured = await titleInset(
        tester,
        const AppBar(title: Text('Title')),
      );

      expect(
        measured.inset,
        moreOrLessEquals(
          expectedInset(CoreAppBarVariant.standard) * measured.scaling,
          epsilon: 0.01,
        ),
      );
    });

    testWidgets('compact indents by its own 16 bar padding', (tester) async {
      // Both single-row variants share one render branch; compact states its
      // own bar padding on its variant row, standard reads the shared 8.
      final measured = await titleInset(
        tester,
        const AppBar(
          title: Text('Title'),
          variant: CoreAppBarVariant.compact,
        ),
      );

      expect(
        measured.inset,
        moreOrLessEquals(
          expectedInset(CoreAppBarVariant.compact) * measured.scaling,
          epsilon: 0.01,
        ),
      );
    });

    testWidgets('a titlePadding override reaches the single-row render', (
      tester,
    ) async {
      // The value only arrives here if the widget reads the resolved slot;
      // a branch that hardcodes the default would render 8 and fail.
      final measured = await titleInset(
        tester,
        const AppBar(
          title: Text('Title'),
          appBarStyle: CoreAppBarStyle(
            titlePadding: CoreEdgeInsets.only(left: CoreSpace.space32),
          ),
        ),
      );

      expect(
        measured.inset,
        moreOrLessEquals(
          (CoreAppBarStyle.defaultPadding.toValue().left + CoreSpace.space32) *
              measured.scaling,
          epsilon: 0.01,
        ),
      );
    });

    testWidgets('medium keeps its own larger inset', (tester) async {
      // Regression pin for the branch that was already correct — medium
      // pads the title block itself and its bar padding lands on the top
      // row, so its inset is the title inset alone.
      final measured = await titleInset(
        tester,
        const AppBar(title: Text('Title'), variant: CoreAppBarVariant.medium),
      );

      expect(
        measured.inset,
        moreOrLessEquals(
          CoreAppBarStyle
                  .defaultsByVariant[CoreAppBarVariant.medium]!
                  .titlePadding!
                  .toValue()
                  .left *
              measured.scaling,
          epsilon: 0.01,
        ),
      );
    });
  });

  // The bar's own inset, measured at the leading cluster's left edge.
  group('AppBar bar padding', () {
    const leadingKey = ValueKey<String>('leading');

    Future<({double inset, double scaling})> leadingInset(
      WidgetTester tester,
      CoreAppBarVariant variant,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return AppBar(
              title: const Text('Title'),
              variant: variant,
              leading: const [Icon(LucideIcons.x, key: leadingKey)],
            );
          },
        ),
      );
      final barLeft = tester.getTopLeft(find.byType(AppBar)).dx;
      final leadingLeft = tester.getTopLeft(find.byKey(leadingKey)).dx;
      return (inset: leadingLeft - barLeft, scaling: scaling);
    }

    for (final (variant, padding) in [
      (CoreAppBarVariant.standard, 8.0),
      (CoreAppBarVariant.compact, 16.0),
      (CoreAppBarVariant.medium, 8.0),
      (CoreAppBarVariant.dense, 16.0),
    ]) {
      testWidgets('${variant.name} insets its leading cluster by $padding', (
        tester,
      ) async {
        final measured = await leadingInset(tester, variant);

        expect(
          measured.inset,
          moreOrLessEquals(padding * measured.scaling, epsilon: 0.01),
        );
      });
    }
  });

  // Dense — the desktop title bar. The row states its own face, cluster gaps
  // and a semibold label title; each is read back off the render so a
  // resolver that kept reading the shared default (surface, 4 / 4, the
  // role's own weight) fails here.
  group('AppBar dense', () {
    const leadingKey = ValueKey<String>('leading');
    const action1Key = ValueKey<String>('action 1');
    const action2Key = ValueKey<String>('action 2');

    Future<ThemeData> pumpDense(
      WidgetTester tester, {
      CoreDensity density = .defaultDensity,
    }) async {
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const AppBar(
              variant: CoreAppBarVariant.dense,
              leading: [Icon(LucideIcons.panelLeft, key: leadingKey)],
              title: Text('Title'),
              trailing: [
                Icon(LucideIcons.bell, key: action1Key),
                Icon(LucideIcons.settings, key: action2Key),
              ],
            );
          },
        ),
        density: density,
      );
      return theme;
    }

    testWidgets('paints the chrome-tier face, not surface', (tester) async {
      final theme = await pumpDense(tester);
      final face = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.surfaceContainerLow))
          .toValue();
      final surface = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.surface))
          .toValue();

      expect(_barDecoration(tester).color, face);
      expect(face, isNot(surface), reason: 'the two tiers must differ');
    });

    testWidgets('the other variants keep the surface face', (tester) async {
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const AppBar(
              title: Text('Title'),
              variant: CoreAppBarVariant.compact,
            );
          },
        ),
      );

      expect(
        _barDecoration(tester).color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue(),
      );
    });

    testWidgets('clusters sit 14 apart with no title inset', (tester) async {
      final theme = await pumpDense(tester);
      final leadingRight = tester.getTopRight(find.byKey(leadingKey)).dx;
      final titleLeft = tester.getTopLeft(find.text('Title')).dx;

      expect(
        titleLeft - leadingRight,
        moreOrLessEquals(CoreSpace.space14 * theme.scaling, epsilon: 0.01),
      );
    });

    testWidgets('actions sit 8 apart', (tester) async {
      final theme = await pumpDense(tester);
      final firstRight = tester.getTopRight(find.byKey(action1Key)).dx;
      final secondLeft = tester.getTopLeft(find.byKey(action2Key)).dx;

      expect(
        secondLeft - firstRight,
        moreOrLessEquals(CoreSpace.space8 * theme.scaling, epsilon: 0.01),
      );
    });

    testWidgets('title is labelLarge at semibold in onSurface', (tester) async {
      final theme = await pumpDense(tester);
      final role = const CoreTextStyle.token(
        CoreTextStyles.labelLarge,
      ).toValue(theme: theme);
      final drawn = tester
          .renderObject<RenderParagraph>(find.text('Title'))
          .text
          .style!;

      expect(drawn.fontWeight, FontWeight.w600);
      expect(drawn.fontSize, role.fontSize);
      expect(drawn.height, role.height);
      expect(drawn.letterSpacing, role.letterSpacing);
      expect(
        drawn.color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurface))
            .toValue(),
      );
    });

    // Height is a bar step, not a spacing value — like the other variants it
    // stays put under density while the inset moves with the spacing ladder.
    testWidgets('compact density keeps 48 and moves the inset', (
      tester,
    ) async {
      final theme = await pumpDense(tester, density: .compact);
      final barLeft = tester.getTopLeft(find.byType(AppBar)).dx;
      final leadingLeft = tester.getTopLeft(find.byKey(leadingKey)).dx;

      expect(tester.getSize(find.byType(AppBar)).height, 48);
      expect(
        leadingLeft - barLeft,
        moreOrLessEquals(
          theme.geometry.space(CoreSpace.space16) * theme.scaling,
          epsilon: 0.01,
        ),
      );
      expect(
        theme.geometry.space(CoreSpace.space16),
        lessThan(CoreSpace.space16),
        reason: 'compact density must actually move the spacing ladder',
      );
    });
  });

  // Prominent is a single row at the compact height whose title is the
  // screen's heading — a large `headlineSmall`, start-aligned, 20 in from the
  // bar edge — for the first screen of a tab. It rides the same single-row
  // render branch as standard / compact / dense, so these tests pin what is
  // its own: the height, the title role and the two 20 insets.
  group('AppBar prominent', () {
    const trailingKey = ValueKey<String>('trailing words');

    Future<({ThemeData theme, double scaling})> pumpProminent(
      WidgetTester tester, {
      bool centerTitle = false,
      List<Widget> trailing = const [],
    }) async {
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return AppBar(
              variant: CoreAppBarVariant.prominent,
              centerTitle: centerTitle,
              title: const Text('Title'),
              trailing: trailing,
            );
          },
        ),
      );
      return (theme: theme, scaling: theme.scaling);
    }

    testWidgets('renders 56 tall and keeps the divider', (tester) async {
      await pumpProminent(tester);

      expect(tester.getSize(find.byType(AppBar)).height, 56);
      expect(_barDecoration(tester).border, isA<Border>());
    });

    testWidgets('paints the surface face, not the chrome tier', (tester) async {
      final pumped = await pumpProminent(tester);

      expect(
        _barDecoration(tester).color,
        pumped.theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue(),
      );
    });

    testWidgets('title is headlineSmall in onSurface — the role whole', (
      tester,
    ) async {
      final pumped = await pumpProminent(tester);
      final role = const CoreTextStyle.token(
        CoreTextStyles.headlineSmall,
      ).toValue(theme: pumped.theme);
      final drawn = tester
          .renderObject<RenderParagraph>(find.text('Title'))
          .text
          .style!;

      expect(drawn.fontSize, role.fontSize);
      expect(drawn.fontWeight, role.fontWeight);
      expect(drawn.height, role.height);
      expect(drawn.letterSpacing, role.letterSpacing);
      expect(
        drawn.color,
        pumped.theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurface))
            .toValue(),
      );
      expect(
        drawn.fontSize,
        greaterThan(
          const CoreTextStyle.token(
            CoreTextStyles.titleLarge,
          ).toValue(theme: pumped.theme).fontSize!,
        ),
        reason: 'the heading is larger than the medium bar title',
      );
    });

    testWidgets('title starts 20 in from the bar edge', (tester) async {
      final pumped = await pumpProminent(tester);
      final barLeft = tester.getTopLeft(find.byType(AppBar)).dx;
      final titleLeft = tester.getTopLeft(find.text('Title')).dx;

      expect(
        titleLeft - barLeft,
        moreOrLessEquals(20 * pumped.scaling, epsilon: 0.01),
      );
    });

    testWidgets('a words-only action ends 20 in from the other edge', (
      tester,
    ) async {
      final pumped = await pumpProminent(
        tester,
        trailing: [
          Button(
            key: trailingKey,
            variant: CoreButtonVariant.ghost,
            onPressed: () {},
            child: const Text('목록으로'),
          ),
        ],
      );
      final barRight = tester.getTopRight(find.byType(AppBar)).dx;
      final wordsRight = tester.getTopRight(find.text('목록으로')).dx;

      expect(
        barRight - wordsRight,
        moreOrLessEquals(20 * pumped.scaling, epsilon: 0.01),
        reason: "4 bar padding + the ghost button's own 16 inset",
      );
    });

    DefaultTextStyle titleDefaults(WidgetTester tester) =>
        tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Title'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );

    testWidgets('title is start-aligned by default', (tester) async {
      await pumpProminent(tester);

      expect(titleDefaults(tester).textAlign, isNull);
    });

    testWidgets('centerTitle centres it like the other single-row bars', (
      tester,
    ) async {
      await pumpProminent(tester, centerTitle: true);

      expect(titleDefaults(tester).textAlign, TextAlign.center);
    });

    testWidgets('density moves the insets and keeps the 56 height', (
      tester,
    ) async {
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const AppBar(
              variant: CoreAppBarVariant.prominent,
              title: Text('Title'),
            );
          },
        ),
        density: .compact,
      );
      final barLeft = tester.getTopLeft(find.byType(AppBar)).dx;
      final titleLeft = tester.getTopLeft(find.text('Title')).dx;

      expect(tester.getSize(find.byType(AppBar)).height, 56);
      expect(
        titleLeft - barLeft,
        moreOrLessEquals(
          (theme.geometry.space(CoreSpace.space4) +
                  theme.geometry.space(CoreSpace.space16)) *
              theme.scaling,
          epsilon: 0.01,
        ),
      );
    });
  });
}
