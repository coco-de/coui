import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The places the surface material used to reach one platform and not the
/// other (#5429, #5434), each read back from what the Flutter side now
/// paints.
///
/// Every case pairs the style that states the material with one that does
/// not. The negative control is what separates "the material arrived" from
/// "something on this widget happens to blur / cast / light an edge".

ThemeData get _base => ThemeData.fromCore(CoreThemePresets.light);

/// The theme a [style] folds — the same fold `CoUIApp` runs, so expected
/// values are derived from the seat rather than copied out of the recipe.
ThemeData _styled(CoreSurfaceStyleId style) =>
    applySurfaceStyle(_base, surfaceStyle: style, highContrast: false);

Future<void> _pump(
  WidgetTester tester,
  CoreSurfaceStyleId style,
  Widget child,
) async {
  // Room for the overlays and tails that sit outside a box.
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    CoUIApp(
      theme: _base,
      surfaceStyle: style,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// The [SurfaceBlur]s inside [scope].
Iterable<SurfaceBlur> _blurs(WidgetTester tester, Finder scope) =>
    tester.widgetList<SurfaceBlur>(
      find.descendant(of: scope, matching: find.byType(SurfaceBlur)),
    );

/// The non-empty [InsetShadow] stacks inside [scope].
List<List<BoxShadow>> _insets(WidgetTester tester, Finder scope) => [
  for (final inset in tester.widgetList<InsetShadow>(
    find.descendant(of: scope, matching: find.byType(InsetShadow)),
  ))
    if (inset.shadows.isNotEmpty) inset.shadows,
];

/// The outer shadow stacks the boxes inside [scope] paint through their
/// decoration.
List<List<BoxShadow>> _decorationCasts(WidgetTester tester, Finder scope) {
  final found = <List<BoxShadow>>[];
  for (final element
      in find
          .descendant(
            of: scope,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container || w is AnimatedContainer || w is DecoratedBox,
            ),
          )
          .evaluate()) {
    final widget = element.widget;
    final decoration = switch (widget) {
      Container(:final decoration) => decoration,
      AnimatedContainer(:final decoration) => decoration,
      DecoratedBox(:final decoration) => decoration,
      _ => null,
    };
    if (decoration is BoxDecoration &&
        (decoration.boxShadow?.isNotEmpty ?? false)) {
      found.add(decoration.boxShadow!);
    }
  }
  return found;
}

/// Whether [shadows] is the style's rim — every layer in the palette's
/// surface highlight. Channels, not the packed colour: the layer's own
/// opacity rewrites the alpha.
bool _isRim(List<BoxShadow> shadows) {
  final highlight = CoreThemePresets.lightColorScheme
      .resolve(const CoreColor.token(CoreColors.surfaceHighlight))
      .toValue();
  return shadows.isNotEmpty &&
      shadows.every(
        (s) =>
            s.color.r == highlight.r &&
            s.color.g == highlight.g &&
            s.color.b == highlight.b,
      );
}

/// Reads one pixel of [boundary] back, as `0xAARRGGBB`.
Future<int> _pixel(
  WidgetTester tester,
  GlobalKey boundary,
  Offset at,
) async {
  final result = await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final data = (await image.toByteData())!;
    final i = ((at.dy.round() * image.width) + at.dx.round()) * 4;
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    final a = data.getUint8(i + 3);
    image.dispose();
    return (a << 24) | (r << 16) | (g << 8) | b;
  });
  return result!;
}

/// Each channel of [color] composited over an opaque [page].
int _over(Color color, Color page) {
  int ch(double c, double p) =>
      ((c * color.a + p * (1 - color.a)) * 255).round().clamp(0, 255);
  return (0xFF << 24) |
      (ch(color.r, page.r) << 16) |
      (ch(color.g, page.g) << 8) |
      ch(color.b, page.b);
}

/// Largest per-channel distance between two `0xAARRGGBB` pixels.
int _distance(int a, int b) {
  var worst = 0;
  for (final shift in const [16, 8, 0]) {
    final d = (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs();
    if (d > worst) worst = d;
  }
  return worst;
}

void main() {
  group(
    'ChatBubble — the body takes the whole material, the tail its share',
    () {
      testWidgets('glass: the body is frosted and bent, not only faded', (
        tester,
      ) async {
        await _pump(
          tester,
          .liquidGlass,
          const ChatBubble(key: ValueKey('b'), child: Text('hi')),
        );

        final glass = _styled(.liquidGlass).surfaceFor(.content)!;
        final blurs = _blurs(tester, find.byKey(const ValueKey('b')));
        expect(blurs, hasLength(1), reason: 'the body is one surface');
        expect(blurs.single.surfaceBlur, glass.blurRadius);
        expect(blurs.single.surfaceSheen, isNotNull);
        expect(blurs.single.refraction, isNotNull, reason: 'glass bends');
      });

      testWidgets('a style with no material keeps the plain tree', (
        tester,
      ) async {
        await _pump(
          tester,
          .defaultStyle,
          const ChatBubble(key: ValueKey('b'), child: Text('hi')),
        );

        expect(_blurs(tester, find.byKey(const ValueKey('b'))), isEmpty);
      });

      testWidgets('the tail paints the share the body fills with', (
        tester,
      ) async {
        // Read in paint, because the decision this pins is about the pixel:
        // the tail is the body's silhouette, so it is as translucent as the
        // body's fill — not the full-strength colour the Web twin used to
        // paint it with. Over a flat page the frost has nothing to show, so
        // the tail's pixel is exactly the share composited over the page.
        const page = Color(0xFFFFFFFF);
        final boundary = GlobalKey();
        tester.view.physicalSize = const Size(400, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          CoUIApp(
            theme: _base,
            surfaceStyle: .liquidGlass,
            home: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: boundary,
                child: const ColoredBox(
                  color: page,
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: ChatBubble(
                      key: ValueKey('b'),
                      variant: .primary,
                      tail: true,
                      child: Text('hi'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byKey(const ValueKey('b')));
        final resolved = resolveChatBubble(
          context,
          variant: .primary,
          alignment: .start,
          tail: true,
        );
        expect(resolved.backgroundColor.a, lessThan(1), reason: 'glass fades');

        // The tail sits left of the body (start alignment), its bottom edge
        // flush with the body's; sample its fat end, away from the tip.
        final body = tester.getRect(
          find
              .descendant(
                of: find.byKey(const ValueKey('b')),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final probe = Offset(
          body.left - resolved.tailWidth / 4,
          body.bottom - resolved.tailHeight / 4,
        );
        final painted = await _pixel(tester, boundary, probe);
        final opaque = _over(
          resolved.backgroundColor.withValues(alpha: 1),
          page,
        );
        final shared = _over(resolved.backgroundColor, page);

        expect(
          _distance(painted, shared),
          lessThanOrEqualTo(2),
          reason: 'the tail is the body fill at the material share',
        );
        expect(
          _distance(painted, opaque),
          greaterThan(16),
          reason: 'the tail did not stay at full strength',
        );
      });
    },
  );

  group('Toast — a casting panel takes the rim', () {
    testWidgets('clay lights the panel', (tester) async {
      await _pump(
        tester,
        .claymorphism,
        const Toast(key: ValueKey('t'), message: 'Saved'),
      );

      final insets = _insets(tester, find.byKey(const ValueKey('t')));
      expect(insets.where(_isRim), hasLength(1));
    });

    testWidgets('a style with no rim adds none', (tester) async {
      await _pump(
        tester,
        .defaultStyle,
        const Toast(key: ValueKey('t'), message: 'Saved'),
      );

      expect(_insets(tester, find.byKey(const ValueKey('t'))), isEmpty);
    });

    testWidgets('a toast that casts nothing gets no rim', (tester) async {
      // The gate, not the style: a rim decorates a surface that casts.
      await _pump(
        tester,
        .claymorphism,
        const Toast(
          key: ValueKey('t'),
          message: 'Saved',
          toastStyle: CoreToastStyle(panelBoxShadow: []),
        ),
      );

      expect(_insets(tester, find.byKey(const ValueKey('t'))), isEmpty);
    });
  });

  group('Sortable — the lifted row takes the rim, a resting one none', () {
    Future<ResolvedSortable> resolveUnder(
      WidgetTester tester,
      CoreSurfaceStyleId style, {
      CoreSortableStyle? sortableStyle,
    }) async {
      late ResolvedSortable resolved;
      await _pump(
        tester,
        style,
        Builder(
          builder: (context) {
            resolved = resolveSortable(context, sortableStyle: sortableStyle);
            return const SizedBox.shrink();
          },
        ),
      );
      return resolved;
    }

    testWidgets('clay: the proxy is lit', (tester) async {
      final resolved = await resolveUnder(tester, .claymorphism);
      expect(_isRim(resolved.proxyInsetShadow), isTrue);
    });

    testWidgets('no rim under a style that states none', (tester) async {
      final resolved = await resolveUnder(tester, .defaultStyle);
      expect(resolved.proxyInsetShadow, isEmpty);
    });

    testWidgets('a proxy that does not lift casts nothing and gets none', (
      tester,
    ) async {
      final resolved = await resolveUnder(
        tester,
        .claymorphism,
        sortableStyle: const CoreSortableStyle(proxyElevation: 0),
      );
      expect(resolved.proxyInsetShadow, isEmpty);
    });
  });

  group('WindowPanel — the frame casts, so it takes the rim', () {
    testWidgets('clay lights the frame', (tester) async {
      await _pump(
        tester,
        .claymorphism,
        const SizedBox(
          width: 320,
          height: 200,
          child: WindowPanel(key: ValueKey('w'), title: Text('Editor')),
        ),
      );

      final insets = _insets(tester, find.byKey(const ValueKey('w')));
      expect(insets.where(_isRim), hasLength(1));
    });

    testWidgets('a style with no rim adds none', (tester) async {
      await _pump(
        tester,
        .defaultStyle,
        const SizedBox(
          width: 320,
          height: 200,
          child: WindowPanel(key: ValueKey('w'), title: Text('Editor')),
        ),
      );

      expect(_insets(tester, find.byKey(const ValueKey('w'))), isEmpty);
    });
  });

  group('Button — a filled button is glass, an unfilled one is not', () {
    // The same split the Web twin draws with its surface marker — a variant
    // is in one list or the other on both platforms.
    for (final variant in const [
      CoreButtonVariant.primary,
      CoreButtonVariant.secondary,
      CoreButtonVariant.outline,
      CoreButtonVariant.destructive,
    ]) {
      testWidgets('glass: ${variant.name} is frosted, faded and bent', (
        tester,
      ) async {
        await _pump(
          tester,
          .liquidGlass,
          Button(
            key: const ValueKey('b'),
            variant: variant,
            onPressed: () {},
            child: const Text('Save'),
          ),
        );

        final glass = _styled(.liquidGlass).surfaceFor(.content)!;
        final blurs = _blurs(tester, find.byKey(const ValueKey('b')));
        expect(blurs, hasLength(1));
        expect(blurs.single.surfaceBlur, glass.blurRadius);
        expect(blurs.single.surfaceSheen, isNotNull);
        expect(blurs.single.refraction, isNotNull);
      });
    }

    for (final variant in const [
      CoreButtonVariant.ghost,
      CoreButtonVariant.plain,
      CoreButtonVariant.menu,
      CoreButtonVariant.menubar,
      CoreButtonVariant.fixed,
    ]) {
      testWidgets('glass: ${variant.name} paints no fill and takes nothing', (
        tester,
      ) async {
        // A material is a statement about a filled box. Handed one, a
        // fill-less button frosts a backdrop behind nothing and draws an
        // edge band around a box that is not there.
        await _pump(
          tester,
          .liquidGlass,
          Button(
            key: const ValueKey('b'),
            variant: variant,
            onPressed: () {},
            child: const Text('Save'),
          ),
        );

        expect(_blurs(tester, find.byKey(const ValueKey('b'))), isEmpty);
      });
    }

    testWidgets('glass: a button inside a glass card keeps its edge, '
        'drops the frost', (tester) async {
      // Glass does not stack on glass — the nested token drops the
      // backdrop pass and keeps the band, on every surface.
      await _pump(
        tester,
        .liquidGlass,
        Card(
          body: Button(
            key: const ValueKey('b'),
            onPressed: () {},
            child: const Text('Save'),
          ),
        ),
      );

      final blurs = _blurs(tester, find.byKey(const ValueKey('b')));
      expect(blurs, hasLength(1));
      expect(blurs.single.surfaceBlur ?? 0, 0, reason: 'no second pass');
      expect(blurs.single.surfaceSheen, isNotNull, reason: 'the edge stays');
    });

    testWidgets('a style with no material keeps the plain tree', (
      tester,
    ) async {
      await _pump(
        tester,
        .defaultStyle,
        Button(
          key: const ValueKey('b'),
          onPressed: () {},
          child: const Text('Save'),
        ),
      );

      expect(_blurs(tester, find.byKey(const ValueKey('b'))), isEmpty);
    });
  });

  group('Badge · ValidationBadge · Kbd — a filled control takes the whole '
      'material, not only the share', () {
    // Each draws its own box (its Web root is an inline `<span>`), so it reads
    // the material seat itself. It used to fold the share into its fill and
    // stop there — translucent on this platform, frosted and bent on the Web.
    final cases = <String, Widget Function(Key)>{
      'Badge': (key) => Badge(key: key, child: const Text('New')),
      'ValidationBadge': (key) => ValidationBadge(
        key: key,
        label: 'Has a digit',
        state: .valid,
      ),
      'Kbd': (key) => Kbd(key: key, keys: const ['K']),
    };

    for (final MapEntry(key: name, value: build) in cases.entries) {
      testWidgets('glass: $name is frosted, faded and bent', (tester) async {
        await _pump(tester, .liquidGlass, build(const ValueKey('c')));

        final glass = _styled(.liquidGlass).surfaceFor(.content)!;
        final blurs = _blurs(tester, find.byKey(const ValueKey('c')));
        expect(blurs, hasLength(1));
        expect(blurs.single.surfaceBlur, glass.blurRadius);
        expect(blurs.single.surfaceSheen, isNotNull);
        expect(blurs.single.refraction, isNotNull);
      });

      testWidgets('glass: $name inside a glass card keeps its edge, drops '
          'the frost', (tester) async {
        // Glass does not stack on glass — the nested token drops the
        // backdrop pass and keeps the band, as on every other surface.
        await _pump(
          tester,
          .liquidGlass,
          Card(body: build(const ValueKey('c'))),
        );

        final blurs = _blurs(tester, find.byKey(const ValueKey('c')));
        expect(blurs, hasLength(1));
        expect(blurs.single.surfaceBlur ?? 0, 0, reason: 'no second pass');
        expect(blurs.single.surfaceSheen, isNotNull, reason: 'the edge stays');
      });

      testWidgets('$name keeps the plain tree under a style with no '
          'material', (tester) async {
        await _pump(tester, .defaultStyle, build(const ValueKey('c')));

        expect(_blurs(tester, find.byKey(const ValueKey('c'))), isEmpty);
      });
    }

    testWidgets('Kbd: every key cap is its own surface', (tester) async {
      await _pump(
        tester,
        .liquidGlass,
        const Kbd(key: ValueKey('c'), keys: ['Ctrl', 'C']),
      );

      expect(_blurs(tester, find.byKey(const ValueKey('c'))), hasLength(2));
    });

    testWidgets('glass: an outlined badge paints no fill, takes nothing and '
        'keeps its stroke', (tester) async {
      // A material is a statement about a filled box — the outlined badge's
      // fill is its token at opacity 0. Handed one, it frosts a backdrop
      // behind nothing; and the stroke a material clears is the only edge
      // the badge has. The Web twin carries no marker for the same answer.
      late ResolvedBadge resolved;
      await _pump(
        tester,
        .liquidGlass,
        Badge(
          key: const ValueKey('c'),
          variant: .outlined,
          child: Builder(
            builder: (context) {
              resolved = resolveBadge(
                context,
                tone: .neutral,
                variant: .outlined,
                size: .sm,
                form: .count,
              );
              return const Text('Draft');
            },
          ),
        ),
      );

      expect(_blurs(tester, find.byKey(const ValueKey('c'))), isEmpty);
      expect(resolved.backgroundColor.a, 0);
      expect(resolved.borderColor, isNotNull);
      expect(resolved.borderColor!.a, greaterThan(0), reason: 'stroke kept');
    });
  });

  group('ValidationBadge — a tint stays a tint under a translucent '
      'material', () {
    testWidgets('glass: the fill is the token alpha times the share', (
      tester,
    ) async {
      // The Web twin used to restate the published triplet at the share and
      // drop the token's own 10% — a 6% tint came out as a 60% wash. The
      // two platforms now compose the same way: token alpha × share.
      late ResolvedValidationBadge resolved;
      late ThemeData theme;
      await _pump(
        tester,
        .liquidGlass,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            resolved = resolveValidationBadge(
              context,
              state: .valid,
              size: CoreValidationBadgeStyle.defaultSize,
              pendingIcon: null,
              validIcon: null,
              invalidIcon: null,
            );
            return const SizedBox.shrink();
          },
        ),
      );

      final share = theme.surfaceFor(.content)!.opacityIn(theme);
      expect(share, lessThan(1), reason: 'glass states a share');
      expect(
        resolved.backgroundColor.a,
        moreOrLessEquals(
          CoreValidationBadgeStyle.defaultValidBackgroundColor.opacity * share,
          epsilon: 1 / 255,
        ),
      );
    });
  });

  group('the rim rides only a shadow the surface authored — the gate the '
      'Web twin now keys on', () {
    // A rim decorates a surface that casts its own shadow; it does not raise
    // a flat one. These are the rows the Web twin used to light under
    // claymorphism while this platform drew nothing.
    testWidgets('clay: a flat container takes no rim', (tester) async {
      await _pump(
        tester,
        .claymorphism,
        const OutlinedContainer(
          key: ValueKey('c'),
          child: SizedBox(width: 80, height: 40),
        ),
      );

      expect(_insets(tester, find.byKey(const ValueKey('c'))), isEmpty);
    });

    testWidgets('clay: a lifted container is lit', (tester) async {
      await _pump(
        tester,
        .claymorphism,
        const OutlinedContainer(
          key: ValueKey('c'),
          containerStyle: CoreOutlinedContainerStyle(elevation: .medium),
          child: SizedBox(width: 80, height: 40),
        ),
      );

      expect(
        _insets(tester, find.byKey(const ValueKey('c'))).where(_isRim),
        hasLength(1),
      );
    });

    testWidgets('clay: an inline palette takes no rim, a dialog one does', (
      tester,
    ) async {
      // The panel's own inset layer — the first under its container. The
      // dialog palette's footer holds key caps, which cast and are lit in
      // their own right.
      List<BoxShadow> panelInset() => tester
          .widgetList<InsetShadow>(
            find.descendant(
              of: find
                  .descendant(
                    of: find.byKey(const ValueKey('c')),
                    matching: find.byType(OutlinedContainer),
                  )
                  .first,
              matching: find.byType(InsetShadow),
            ),
          )
          .first
          .shadows;

      // An empty palette is as tall as its content and its 240 floor, so the
      // box must hold that and the chrome around it — a shorter one makes the
      // empty state overflow, which this test is not about.
      await _pump(
        tester,
        .claymorphism,
        const SizedBox(
          width: 400,
          height: 480,
          child: Command(key: ValueKey('c'), groups: []),
        ),
      );
      expect(panelInset(), isEmpty);

      await _pump(
        tester,
        .claymorphism,
        const SizedBox(
          width: 400,
          height: 480,
          child: Command(
            key: ValueKey('c'),
            presentation: .dialog,
            groups: [],
          ),
        ),
      );
      expect(_isRim(panelInset()), isTrue);
    });

    testWidgets('clay: a multi-answer card, a toggle and a reverse chip take '
        'no rim', (tester) async {
      await _pump(
        tester,
        .claymorphism,
        Column(
          mainAxisSize: .min,
          children: [
            SizedBox(
              width: 300,
              child: MultiAnswerCard<int>(
                key: const ValueKey('m'),
                value: 1,
                onChanged: (_) {},
                child: const Text('Answer'),
              ),
            ),
            Toggle(key: const ValueKey('t'), value: false, onChanged: (_) {}),
            const Chip(
              key: ValueKey('r'),
              chipStyle: CoreChipStyle(castMotion: .reverse),
              child: Text('Tag'),
            ),
          ],
        ),
      );

      for (final key in const ['m', 't', 'r']) {
        expect(
          _insets(tester, find.byKey(ValueKey(key))),
          isEmpty,
          reason: key,
        );
      }
    });
  });

  group('the contributed cast reaches the boxes the Web twin redraws', () {
    // The twin composes `OutlinedContainer` for both, which gives a box at
    // rest elevation the style's cast. The Web redraws them and used to
    // leave it out.
    bool castsHard(List<BoxShadow> stack) => stack.any(
      (s) => s.offset.dx > 0 && s.offset.dy > 0 && s.blurRadius == 0,
    );

    testWidgets('neo: a multi-answer card casts', (tester) async {
      await _pump(
        tester,
        .neoBrutalism,
        SizedBox(
          width: 300,
          child: MultiAnswerCard<int>(
            key: const ValueKey('m'),
            value: 1,
            onChanged: (_) {},
            child: const Text('Answer'),
          ),
        ),
      );

      expect(
        _decorationCasts(
          tester,
          find.byKey(const ValueKey('m')),
        ).any(castsHard),
        isTrue,
      );
    });

    testWidgets('neo: a toggle track casts', (tester) async {
      await _pump(
        tester,
        .neoBrutalism,
        Toggle(key: const ValueKey('t'), value: false, onChanged: (_) {}),
      );

      expect(
        _decorationCasts(
          tester,
          find.byKey(const ValueKey('t')),
        ).any(castsHard),
        isTrue,
      );
    });
  });
}
