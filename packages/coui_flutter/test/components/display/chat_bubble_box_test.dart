// What the Flutter chat bubble paints for its box — the inner padding, the
// corners, the single-line height they add up to, and the face the neutral
// bubble fills with.
//
// The resolver reads `defaultPadding` / `defaultBorderRadius` from Core
// without naming a number, so a test that compared the painted box against
// those same defaults would pass for any value. Every expectation here is
// derived from the tokens the default names (`space10` / `space14` /
// `radius14`) and read back from the widgets, not from the default itself.
// The neutral face is read the same way: the expected colour comes from the
// shipped scheme's `surfaceContainerHigh` slot, and the painted body fill,
// the painted tail pixel and the text colour are read back from the tree.
//
// Only the coui barrel is imported: pulling in `package:flutter/widgets.dart`
// as well re-introduces Flutter's own `Banner`, which that barrel hides.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const Key _kBubble = ValueKey('bubble');

/// The room a bubble is laid out in — wide enough that a one-word message
/// never wraps, so the box is the content plus the padding.
const double _kRoom = 400;

Future<void> _pump(
  WidgetTester tester,
  Widget bubble, {
  CoreDensity density = .defaultDensity,
  CoreThemeData? core,
  bool highContrast = false,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: _kRoom, child: bubble),
      ),
      theme: ThemeData.fromCore(core ?? CoreThemePresets.light),
      density: density,
      highContrast: highContrast,
    ),
  );
  await tester.pumpAndSettle();
}

/// The bubble's `Padding` — the one directly around the message.
EdgeInsets _padding(WidgetTester tester) {
  final padding = find.descendant(
    of: find.byKey(_kBubble),
    matching: find.ancestor(
      of: find.text('hi'),
      matching: find.byType(Padding),
    ),
  );
  return tester.widget<Padding>(padding.first).padding.resolve(.ltr);
}

/// The bubble body's painted corners.
BorderRadius _corners(WidgetTester tester) {
  final box = find.descendant(
    of: find.byKey(_kBubble),
    matching: find.byType(DecoratedBox),
  );
  final decoration = tester.widget<DecoratedBox>(box.first).decoration;
  return (decoration as BoxDecoration).borderRadius!.resolve(.ltr);
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

/// Largest per-channel distance between two `0xAARRGGBB` pixels.
int _distance(int a, int b) {
  var worst = 0;
  for (final shift in const [16, 8, 0]) {
    final d = (((a >> shift) & 0xFF) - ((b >> shift) & 0xFF)).abs();
    if (d > worst) worst = d;
  }
  return worst;
}

/// The `0xAARRGGBB` of an opaque [color], for comparing against a pixel.
int _argb(Color color) =>
    (0xFF << 24) |
    ((color.r * 255).round() << 16) |
    ((color.g * 255).round() << 8) |
    (color.b * 255).round();

/// The body's fill — the colour on the bubble's own `DecoratedBox`.
Color _bodyFill(WidgetTester tester) {
  final box = find.descendant(
    of: find.byKey(_kBubble),
    matching: find.byType(DecoratedBox),
  );
  final decoration = tester.widget<DecoratedBox>(box.first).decoration;
  return (decoration as BoxDecoration).color!;
}

/// The colour the message text is drawn in.
Color? _textColor(WidgetTester tester) =>
    DefaultTextStyle.of(tester.element(find.text('hi'))).style.color;

/// The four shipped schemes the neutral face is read under, each with the
/// theme data that carries it.
final _kModes = <String, ({CoreThemeData theme, ResolvedColorScheme scheme})>{
  'Light': (
    theme: CoreThemePresets.light,
    scheme: CoreThemePresets.lightColorScheme,
  ),
  'Dark': (
    theme: CoreThemePresets.dark,
    scheme: CoreThemePresets.darkColorScheme,
  ),
  'HCLight': (
    theme: CoreThemePresets.highContrastLight,
    scheme: CoreThemePresets.highContrastLightColorScheme,
  ),
  'HCDark': (
    theme: CoreThemePresets.highContrastDark,
    scheme: CoreThemePresets.highContrastDarkColorScheme,
  ),
};

void main() {
  group('ChatBubble box', () {
    testWidgets('the message sits 14 across and 10 down inside the body', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, child: Text('hi')),
      );

      expect(
        _padding(tester),
        const EdgeInsets.symmetric(
          horizontal: CoreSpace.space14,
          vertical: CoreSpace.space10,
        ),
      );
    });

    testWidgets('every corner paints the 14 step when there is no tail', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, child: Text('hi')),
      );

      expect(_corners(tester), BorderRadius.circular(CoreRadius.radius14));
    });

    testWidgets(
      'start-aligned: the bottom-left corner is square, three stay 14',
      (
        tester,
      ) async {
        await _pump(
          tester,
          const ChatBubble(key: _kBubble, tail: true, child: Text('hi')),
        );

        expect(
          _corners(tester),
          const BorderRadius.only(
            topLeft: Radius.circular(CoreRadius.radius14),
            topRight: Radius.circular(CoreRadius.radius14),
            bottomRight: Radius.circular(CoreRadius.radius14),
          ),
        );
      },
    );

    testWidgets(
      'end-aligned: the bottom-right corner is square, three stay 14',
      (
        tester,
      ) async {
        await _pump(
          tester,
          const ChatBubble(
            key: _kBubble,
            alignment: .end,
            tail: true,
            child: Text('hi'),
          ),
        );

        expect(
          _corners(tester),
          const BorderRadius.only(
            topLeft: Radius.circular(CoreRadius.radius14),
            topRight: Radius.circular(CoreRadius.radius14),
            bottomLeft: Radius.circular(CoreRadius.radius14),
          ),
        );
      },
    );

    testWidgets('the body is the message plus the padding, one line tall', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, child: Text('hi')),
      );

      final body = tester.getSize(find.byKey(_kBubble));
      final text = tester.getSize(find.text('hi'));

      expect(body.height, text.height + 2 * CoreSpace.space10);
      expect(body.width, text.width + 2 * CoreSpace.space14);
    });

    testWidgets('a caller-stated padding and corner still win', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          chatBubbleStyle: CoreChatBubbleStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space16,
            ),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
          ),
          child: Text('hi'),
        ),
      );

      expect(
        _padding(tester),
        const EdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space16,
        ),
      );
      expect(_corners(tester), BorderRadius.circular(CoreRadius.radius8));
    });
  });

  group('ChatBubble box under density', () {
    // 10 and 14 are off the 4px rungs, so density sends them to the next rung
    // in its direction; the corner follows the row band.
    testWidgets('compact: 8 down, 12 across, corner 12', (tester) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, child: Text('hi')),
        density: .compact,
      );

      expect(
        _padding(tester),
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
      expect(_corners(tester), BorderRadius.circular(12));
    });

    testWidgets('spacious: 12 down, 16 across, corner 16', (tester) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, child: Text('hi')),
        density: .spacious,
      );

      expect(
        _padding(tester),
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
      expect(_corners(tester), BorderRadius.circular(16));
    });
  });

  group('ChatBubble neutral face', () {
    // The expected colours come from the shipped scheme's slots, not from the
    // variant table the resolver reads, so a face that moved back to the
    // `surfaceContainer` slot fails in every mode.
    for (final mode in _kModes.entries) {
      final scheme = mode.value.scheme;
      final highContrast = mode.key.startsWith('HC');

      testWidgets(
        '${mode.key}: the body fills with surfaceContainerHigh, the text '
        'with onSurface',
        (tester) async {
          await _pump(
            tester,
            const ChatBubble(key: _kBubble, child: Text('hi')),
            core: mode.value.theme,
            highContrast: highContrast,
          );

          expect(_bodyFill(tester), scheme.surfaceContainerHigh.toValue());
          expect(
            _bodyFill(tester),
            isNot(scheme.surfaceContainer.toValue()),
            reason: 'the two container tones differ in every mode',
          );
          expect(_textColor(tester), scheme.onSurface.toValue());
        },
      );

      testWidgets('${mode.key}: the resolver hands the widget the same fill', (
        tester,
      ) async {
        await _pump(
          tester,
          const ChatBubble(key: _kBubble, child: Text('hi')),
          core: mode.value.theme,
          highContrast: highContrast,
        );

        final resolved = resolveChatBubble(
          tester.element(find.byKey(_kBubble)),
          variant: .neutral,
          alignment: .start,
          tail: false,
        );

        expect(
          resolved.backgroundColor,
          scheme.surfaceContainerHigh.toValue(),
        );
        expect(resolved.foregroundColor, scheme.onSurface.toValue());
      });

      testWidgets('${mode.key}: the tail paints the body fill', (
        tester,
      ) async {
        // The tail is drawn by its own painter, so the body's fill says
        // nothing about it — read its pixel. Opaque, so the page behind it
        // does not matter.
        final boundary = GlobalKey();
        tester.view.physicalSize = const Size(600, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          buildTestApp(
            Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: boundary,
                child: const ColoredBox(
                  color: Color(0xFFFF00FF),
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: ChatBubble(
                      key: _kBubble,
                      tail: true,
                      child: Text('hi'),
                    ),
                  ),
                ),
              ),
            ),
            theme: ThemeData.fromCore(mode.value.theme),
            highContrast: highContrast,
          ),
        );
        await tester.pumpAndSettle();

        final body = tester.getRect(
          find
              .descendant(
                of: find.byKey(_kBubble),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        // Start-aligned: the tail sits left of the body, flush with its
        // bottom. Sample the fat end, away from the rounded tip.
        final probe = Offset(
          body.left - CoreChatBubbleStyle.defaultTailWidth / 4,
          body.bottom - CoreChatBubbleStyle.defaultTailHeight / 4,
        );
        final painted = await _pixel(tester, boundary, probe);

        expect(
          _distance(painted, _argb(scheme.surfaceContainerHigh.toValue())),
          lessThanOrEqualTo(1),
          reason: 'the tail is cut against the same fill as the body',
        );
        expect(
          _distance(painted, _argb(scheme.surfaceContainer.toValue())),
          greaterThan(1),
          reason: 'not the tone the face used to read',
        );
      });
    }

    testWidgets('the primary face still fills with the primary slot', (
      tester,
    ) async {
      // Negative control: the swap is the neutral entry alone.
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          variant: .primary,
          child: Text('hi'),
        ),
      );
      final scheme = CoreThemePresets.lightColorScheme;

      expect(_bodyFill(tester), scheme.primary.toValue());
      expect(_textColor(tester), scheme.onPrimary.toValue());
    });

    testWidgets('a caller-stated face still wins over the variant', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          chatBubbleStyle: CoreChatBubbleStyle(
            backgroundColor: CoreColor(0xFF123456),
          ),
          child: Text('hi'),
        ),
      );

      expect(_bodyFill(tester), const Color(0xFF123456));
    });
  });

  group('ChatBubble plain variant', () {
    /// Tail painters under the bubble — the pointer is its own `CustomPaint`.
    int tails(WidgetTester tester) => find
        .descendant(
          of: find.byKey(_kBubble),
          matching: find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == '_ChatTailPainter',
          ),
        )
        .evaluate()
        .length;

    /// Width of the bubble body.
    double width(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byKey(_kBubble),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .width;

    testWidgets('paints no face, muted text, no padding', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          variant: .plain,
          child: Text('hi'),
        ),
      );
      final scheme = CoreThemePresets.lightColorScheme;

      expect(_bodyFill(tester).a, 0);
      expect(_textColor(tester), scheme.onSurfaceVariant.toValue());
      expect(_padding(tester), EdgeInsets.zero);
    });

    testWidgets('may take the whole row', (
      tester,
    ) async {
      await _pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: ChatBubble(
            key: _kBubble,
            variant: .plain,
            child: SizedBox(width: _kRoom, child: Text('hi')),
          ),
        ),
      );
      expect(width(tester), _kRoom);
    });

    testWidgets('a filled bubble keeps the shared three quarters', (
      tester,
    ) async {
      await _pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: ChatBubble(
            key: _kBubble,
            child: SizedBox(width: _kRoom, child: Text('hi')),
          ),
        ),
      );
      expect(
        width(tester),
        _kRoom * CoreChatBubbleStyle.defaultMaxWidthFactor,
      );
    });

    testWidgets('a tail cannot be switched on: it has no fill to extend', (
      tester,
    ) async {
      for (final alignment in CoreChatAlignment.values) {
        await _pump(
          tester,
          ChatBubble(
            key: _kBubble,
            variant: .plain,
            alignment: alignment,
            tail: true,
            child: const Text('hi'),
          ),
        );

        expect(tails(tester), 0, reason: alignment.name);
        expect(
          _corners(tester),
          BorderRadius.circular(CoreRadius.radius14),
          reason: '${alignment.name}: no corner squared for a tail',
        );
      }
    });

    testWidgets('tail: false draws no tail and squares no corner', (
      tester,
    ) async {
      for (final alignment in CoreChatAlignment.values) {
        await _pump(
          tester,
          ChatBubble(
            key: _kBubble,
            alignment: alignment,
            child: const Text('hi'),
          ),
        );

        expect(tails(tester), 0, reason: alignment.name);
        expect(
          _corners(tester),
          BorderRadius.circular(CoreRadius.radius14),
          reason: '${alignment.name}: no corner squared without a tail',
        );
      }
    });

    testWidgets(
      'a filled variant draws no tail unless asked: the default is off',
      (
        tester,
      ) async {
        expect(CoreChatBubbleContract.defaultTail, isFalse);
        // Unstated: the side decides, and the start side keeps the default.
        expect(const ChatBubble(child: Text('hi')).tail, isNull);
        expect(
          CoreChatBubbleContract.defaultTailFor(CoreChatAlignment.start),
          CoreChatBubbleContract.defaultTail,
        );

        await _pump(
          tester,
          const ChatBubble(key: _kBubble, child: Text('hi')),
        );

        expect(tails(tester), 0);
        expect(_corners(tester), BorderRadius.circular(CoreRadius.radius14));
      },
    );

    testWidgets('a filled variant draws its tail', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(key: _kBubble, tail: true, child: Text('hi')),
      );

      expect(tails(tester), 1);
    });

    testWidgets('a caller-made transparent fill drops the tail too', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          tail: true,
          chatBubbleStyle: CoreChatBubbleStyle(
            backgroundColor: CoreColor.transparent,
          ),
          child: Text('hi'),
        ),
      );

      expect(tails(tester), 0);
    });

    testWidgets('a caller fill gives plain a face and a tail', (tester) async {
      await _pump(
        tester,
        const ChatBubble(
          key: _kBubble,
          variant: .plain,
          tail: true,
          chatBubbleStyle: CoreChatBubbleStyle(
            backgroundColor: CoreColor(0xFF123456),
          ),
          child: Text('hi'),
        ),
      );

      expect(_bodyFill(tester), const Color(0xFF123456));
      expect(tails(tester), 1);
    });

    testWidgets('the caller style wins over the variant row', (
      tester,
    ) async {
      // merged (caller) > variant row > shipped default: here the shipped
      // plain row states padding 0 and width 1, and the caller style states
      // both again and wins.
      await _pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: ChatBubble(
            key: _kBubble,
            variant: .plain,
            chatBubbleStyle: CoreChatBubbleStyle(
              padding: CoreEdgeInsets.all(CoreSpace.space8),
              maxWidthFactor: 0.5,
            ),
            child: SizedBox(width: _kRoom, child: Text('hi')),
          ),
        ),
      );

      expect(_padding(tester), const EdgeInsets.all(CoreSpace.space8));
      expect(width(tester), _kRoom * 0.5);
    });

    testWidgets('the eight filled variants keep the shared padding', (
      tester,
    ) async {
      for (final variant in CoreChatBubbleVariant.values) {
        if (variant == .plain) continue;
        await _pump(
          tester,
          ChatBubble(
            key: _kBubble,
            variant: variant,
            child: const Text('hi'),
          ),
        );

        expect(
          _padding(tester),
          const EdgeInsets.symmetric(
            horizontal: CoreSpace.space14,
            vertical: CoreSpace.space10,
          ),
          reason: variant.name,
        );
      }
    });
  });

  group('ChatBubble plain variant, theme level', () {
    testWidgets('a Theme variantStyles row beats the shipped plain row', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _kRoom,
              child: ChatBubble(
                key: _kBubble,
                variant: .plain,
                child: Text('hi'),
              ),
            ),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light).copyWith(
            coreComponentTheme: () => const CoreComponentTheme(
              chatBubble: CoreChatBubbleTheme(
                variantStyles: {
                  CoreChatBubbleVariant.plain: CoreChatBubbleStyle(
                    padding: CoreEdgeInsets.all(CoreSpace.space4),
                  ),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_padding(tester), const EdgeInsets.all(CoreSpace.space4));
    });
  });
}
