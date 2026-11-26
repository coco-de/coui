import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestProgress = 0.65;
const _kTestProgressHalf = 0.5;
const _kTestColor = CoreColor(0xFFFF0000);
const _kTestTrackAlpha = 0.2;
const _kTestBackgroundColor = CoreColor(0xFF00FF00);
const _kCustomMin = 10.0;
const _kCustomMax = 100.0;
const _kCustomProgress = 75.0;

Widget _buildApp(Widget child, {ThemeData theme = const ThemeData()}) {
  return material.MaterialApp(
    home: Theme(
      data: theme,
      child: child,
    ),
  );
}

/// Pumps [progress] at a 240px width and returns the painted (track, fill)
/// colours and the active theme. The track is the first `Container` under
/// the bar, the fill the last — with `disableAnimation` the fill is a plain
/// `Container`.
Future<(material.Color, material.Color, ThemeData)> _paint(
  WidgetTester tester,
  Progress progress, {
  ThemeData theme = const ThemeData(),
}) async {
  late ThemeData active;
  await tester.pumpWidget(
    _buildApp(
      material.Builder(
        builder: (context) {
          active = Theme.of(context);
          return material.Center(
            child: material.SizedBox(width: 240, child: progress),
          );
        },
      ),
      theme: theme,
    ),
  );
  final colours = tester
      .widgetList<material.Container>(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Container),
        ),
      )
      .map((c) => (c.decoration! as material.BoxDecoration).color!)
      .toList();
  return (colours.first, colours.last, active);
}

/// The text style a cell's [text] was painted with — the cell's ambient
/// `DefaultTextStyle` folded into the paragraph.
material.TextStyle _paintedStyle(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

material.Color _token(ThemeData theme, CoreColorToken token) =>
    theme.colorScheme.resolve(CoreColor.token(token)).toValue();

void main() {
  group('Progress widget', () {
    group('rendering', () {
      testWidgets('renders with default values', (tester) async {
        await tester.pumpWidget(
          _buildApp(const Progress(value: _kTestProgress)),
        );

        expect(find.byType(Progress), findsOneWidget);
      });

      testWidgets('renders indeterminate when value is null', (tester) async {
        await tester.pumpWidget(_buildApp(const Progress()));

        final widget = tester.widget<Progress>(find.byType(Progress));
        expect(widget.value, isNull);
      });

      testWidgets('renders with custom colors via progressStyle', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            const Progress(
              value: _kTestProgress,
              progressStyle: CoreProgressStyle(
                color: _kTestColor,
                backgroundColor: _kTestBackgroundColor,
              ),
            ),
          ),
        );

        final widget = tester.widget<Progress>(find.byType(Progress));
        expect(widget.progressStyle?.color, equals(_kTestColor));
        expect(
          widget.progressStyle?.backgroundColor,
          equals(_kTestBackgroundColor),
        );
      });

      testWidgets('renders with disableAnimation', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Progress(disableAnimation: true, value: _kTestProgress),
          ),
        );

        final widget = tester.widget<Progress>(find.byType(Progress));
        expect(widget.disableAnimation, isTrue);
      });
    });

    group('properties', () {
      test('default min is 0.0', () {
        const widget = Progress();

        expect(widget.min, equals(0.0));
      });

      test('default max is 1.0', () {
        const widget = Progress();

        expect(widget.max, equals(1.0));
      });

      test('default disableAnimation is false', () {
        const widget = Progress();

        expect(widget.disableAnimation, isFalse);
      });

      test('custom min and max are preserved', () {
        const widget = Progress(
          max: _kCustomMax,
          min: _kCustomMin,
          value: _kCustomProgress,
        );

        expect(widget.min, equals(_kCustomMin));
        expect(widget.max, equals(_kCustomMax));
      });
    });

    group('key support', () {
      testWidgets('respects provided key', (tester) async {
        const testKey = Key('test-progress');

        await tester.pumpWidget(
          _buildApp(const Progress(key: testKey, value: _kTestProgress)),
        );

        expect(find.byKey(testKey), findsOneWidget);
      });
    });

    group('colour chain — what each getter paints', () {
      // A palette getter names the FILL: the track is left unset so it stays
      // the neutral track, and `.success` reads as a success bar rather than
      // a primary bar on a solid success track.
      // `.transparent` clears the track and keeps the fill — a transparent
      // fill would leave nothing on screen. The Web twin holds the same
      // contract in its own test.
      final palette = <String, (Progress Function(Progress), CoreColor)>{
        'primary': ((p) => p.primary, const .token(CoreColors.primary)),
        'secondary': ((p) => p.secondary, const .token(CoreColors.secondary)),
        'tertiary': ((p) => p.tertiary, const .token(CoreColors.tertiary)),
        'surface': ((p) => p.surface, const .token(CoreColors.surface)),
        'surfaceContainer': (
          (p) => p.surfaceContainer,
          const .token(CoreColors.surfaceContainer),
        ),
        'error': ((p) => p.error, const .token(CoreColors.error)),
        'success': ((p) => p.success, const .token(CoreColors.success)),
        'warning': ((p) => p.warning, const .token(CoreColors.warning)),
        'info': ((p) => p.info, const .token(CoreColors.info)),
        'outline': ((p) => p.outline, const .token(CoreColors.outline)),
      };

      for (final MapEntry(key: name, value: (getter, token))
          in palette.entries) {
        test('.$name patches the fill, leaves the track unset', () {
          final style = getter(
            const Progress(value: _kTestProgress),
          ).progressStyle!;

          expect(style.color, token);
          expect(style.backgroundColor, isNull);
        });
      }

      test('.transparent patches the track, leaves the fill unset', () {
        final style = const Progress(
          value: _kTestProgress,
        ).transparent.progressStyle!;

        expect(style.backgroundColor, CoreColor.transparent);
        expect(style.color, isNull);
      });

      /// Pumps [progress] and returns the painted (track, fill) colours and
      /// the active scheme.
      Future<(material.Color, material.Color, ResolvedColorScheme)> paint(
        WidgetTester tester,
        Progress progress,
      ) async {
        late ResolvedColorScheme scheme;
        await tester.pumpWidget(
          _buildApp(
            material.Builder(
              builder: (context) {
                scheme = Theme.of(context).colorScheme;
                return material.Center(
                  child: material.SizedBox(width: 200, child: progress),
                );
              },
            ),
          ),
        );
        final colours = tester
            .widgetList<material.Container>(
              find.descendant(
                of: find.byType(Progress),
                matching: find.byType(material.Container),
              ),
            )
            .map((c) => (c.decoration! as material.BoxDecoration).color!)
            .toList();
        return (colours.first, colours.last, scheme);
      }

      testWidgets('.success paints a success fill on the neutral track', (
        tester,
      ) async {
        final (track, fill, scheme) = await paint(
          tester,
          const Progress(
            value: _kTestProgressHalf,
            disableAnimation: true,
          ).success,
        );
        final success = scheme
            .resolve(const CoreColor.token(CoreColors.success))
            .toValue();

        expect(fill, success);
        expect(
          track,
          scheme.resolve(CoreProgressStyle.defaultBackgroundColor).toValue(),
          reason: 'the track took the fill hue instead of staying neutral',
        );
      });

      testWidgets('.transparent keeps the default fill on a clear track', (
        tester,
      ) async {
        final (track, fill, scheme) = await paint(
          tester,
          const Progress(
            value: _kTestProgressHalf,
            disableAnimation: true,
          ).transparent,
        );

        expect(
          fill,
          scheme.resolve(CoreProgressStyle.defaultColor).toValue(),
          reason: 'the bar lost its fill — nothing left to see',
        );
        expect(track.a, 0, reason: 'the track is not cleared');
      });

      testWidgets('a raw fill keeps the neutral track', (tester) async {
        final (track, fill, scheme) = await paint(
          tester,
          const Progress(
            value: _kTestProgressHalf,
            disableAnimation: true,
          ).withStyle(const CoreProgressStyle(color: _kTestColor)),
        );

        expect(fill, _kTestColor.toValue());
        expect(
          track,
          scheme.resolve(CoreProgressStyle.defaultBackgroundColor).toValue(),
        );
      });

      testWidgets('a stated backgroundAlpha fades a track of the fill hue', (
        tester,
      ) async {
        final (track, fill, _) = await paint(
          tester,
          const Progress(
            value: _kTestProgressHalf,
            disableAnimation: true,
          ).withStyle(
            const CoreProgressStyle(
              color: _kTestColor,
              backgroundAlpha: _kTestTrackAlpha,
            ),
          ),
        );

        expect(fill, _kTestColor.toValue());
        expect(
          track,
          _kTestColor.toValue().withValues(alpha: _kTestTrackAlpha),
        );
      });

      testWidgets('a raw radial arc keeps the neutral track ring', (
        tester,
      ) async {
        late ResolvedRadialProgress resolved;
        late ResolvedColorScheme scheme;
        await tester.pumpWidget(
          _buildApp(
            material.Builder(
              builder: (context) {
                scheme = Theme.of(context).colorScheme;
                resolved = resolveRadialProgress(
                  context,
                  radialProgressStyle: const CoreRadialProgressStyle(
                    color: _kTestColor,
                  ),
                );
                return const material.SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved.color, _kTestColor.toValue());
        expect(
          resolved.backgroundColor,
          scheme
              .resolve(CoreRadialProgressStyle.defaultBackgroundColor)
              .toValue(),
        );
      });

      testWidgets('a stated backgroundAlpha fades a ring of the arc hue', (
        tester,
      ) async {
        late ResolvedRadialProgress resolved;
        await tester.pumpWidget(
          _buildApp(
            material.Builder(
              builder: (context) {
                resolved = resolveRadialProgress(
                  context,
                  radialProgressStyle: const CoreRadialProgressStyle(
                    color: _kTestColor,
                    backgroundAlpha: _kTestTrackAlpha,
                  ),
                );
                return const material.SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          resolved.backgroundColor,
          _kTestColor.toValue().withValues(alpha: _kTestTrackAlpha),
        );
      });
    });

    group('value updates', () {
      testWidgets('rebuilds when value changes', (tester) async {
        await tester.pumpWidget(
          _buildApp(const Progress(value: _kTestProgress)),
        );

        await tester.pumpWidget(
          _buildApp(const Progress(value: _kTestProgressHalf)),
        );

        await tester.pump();

        final widget = tester.widget<Progress>(find.byType(Progress));
        expect(widget.value, equals(_kTestProgressHalf));
      });
    });
  });

  group('tone — what the fill means', () {
    test('defaults to primary', () {
      expect(const Progress().tone, CoreProgressTone.primary);
    });

    final fills = <CoreProgressTone, CoreColorToken>{
      CoreProgressTone.primary: CoreColors.primary,
      CoreProgressTone.success: CoreColors.success,
      CoreProgressTone.warning: CoreColors.warning,
      CoreProgressTone.destructive: CoreColors.error,
    };
    for (final MapEntry(key: tone, value: slot) in fills.entries) {
      testWidgets('${tone.name} paints the ${slot.name} fill on the neutral '
          'track', (tester) async {
        final (track, fill, theme) = await _paint(
          tester,
          Progress(
            value: _kTestProgressHalf,
            disableAnimation: true,
            tone: tone,
          ),
        );

        expect(fill, _token(theme, slot));
        expect(
          track,
          _token(theme, CoreColors.surfaceContainerHigh),
          reason: 'the track followed the tone',
        );
      });
    }

    testWidgets('the indeterminate bar slides in the tone fill', (
      tester,
    ) async {
      final (_, fill, theme) = await _paint(
        tester,
        const Progress(tone: CoreProgressTone.destructive),
      );

      expect(fill, _token(theme, CoreColors.error));
    });

    testWidgets('a stated colour wins over the tone', (tester) async {
      final (_, fill, _) = await _paint(
        tester,
        const Progress(
          value: _kTestProgressHalf,
          disableAnimation: true,
          tone: CoreProgressTone.warning,
          progressStyle: CoreProgressStyle(color: _kTestColor),
        ),
      );

      expect(fill, _kTestColor.toValue());
    });

    testWidgets('a backgroundAlpha track fades the tone fill', (tester) async {
      final (track, _, theme) = await _paint(
        tester,
        const Progress(
          value: _kTestProgressHalf,
          disableAnimation: true,
          tone: CoreProgressTone.success,
          progressStyle: CoreProgressStyle(backgroundAlpha: _kTestTrackAlpha),
        ),
      );

      expect(
        track,
        _token(theme, CoreColors.success).withValues(alpha: _kTestTrackAlpha),
      );
    });

    group('theme chain', () {
      const projectFill = CoreColor(0xFF111111);
      const toneFill = CoreColor(0xFF222222);
      const theme = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          progress: CoreProgressTheme(
            style: CoreProgressStyle(color: projectFill),
            toneStyles: {
              CoreProgressTone.warning: CoreProgressStyle(color: toneFill),
            },
          ),
        ),
      );

      Future<material.Color> fillFor(
        WidgetTester tester,
        CoreProgressTone tone, {
        CoreProgressStyle? progressStyle,
      }) async => (await _paint(
        tester,
        Progress(
          value: _kTestProgressHalf,
          disableAnimation: true,
          tone: tone,
          progressStyle: progressStyle,
        ),
        theme: theme,
      )).$2;

      testWidgets('project style → toneStyles[tone] → progressStyle', (
        tester,
      ) async {
        expect(
          await fillFor(tester, CoreProgressTone.success),
          projectFill.toValue(),
          reason: 'only the project style reaches success',
        );
        expect(
          await fillFor(tester, CoreProgressTone.warning),
          toneFill.toValue(),
          reason: "the warning row wins over the project's style",
        );
        expect(
          await fillFor(
            tester,
            CoreProgressTone.warning,
            progressStyle: const CoreProgressStyle(color: _kTestColor),
          ),
          _kTestColor.toValue(),
          reason: 'the instance wins over the tone row',
        );
      });
    });
  });

  group('label cells', () {
    const label = 'Team plan';
    const valueLabel = '31 / 50';
    const caption = 'AI usage · 18 days left';

    Future<void> pumpBar(WidgetTester tester, Progress progress) =>
        tester.pumpWidget(
          _buildApp(
            material.Center(
              child: material.SizedBox(width: 240, child: progress),
            ),
          ),
        );

    testWidgets('without a cell the bar is the whole widget', (tester) async {
      await pumpBar(tester, const Progress(value: _kTestProgressHalf));

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(Progress),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.child, isA<material.Container>());
      expect(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Column),
        ),
        findsNothing,
      );
      expect(
        tester.getSize(find.byType(Progress)).height,
        CoreProgressStyle
            .defaultsBySize[CoreProgressSize.defaultSize]!
            .minHeight,
      );
    });

    testWidgets('each cell paints in its own text tier', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const material.Center(
                child: material.SizedBox(
                  width: 240,
                  child: Progress(
                    value: _kTestProgressHalf,
                    label: Text(label),
                    valueLabel: Text(valueLabel),
                    caption: Text(caption),
                  ),
                ),
              );
            },
          ),
        ),
      );

      double? roleSize(CoreTextStyleToken role) =>
          CoreTextStyle.token(role).toValue(theme: theme).fontSize;

      final labelStyle = _paintedStyle(tester, label);
      expect(labelStyle.fontSize, roleSize(CoreTextStyles.labelMedium));
      expect(labelStyle.fontWeight, material.FontWeight.w500);
      expect(labelStyle.color, _token(theme, CoreColors.onSurface));

      final valueStyle = _paintedStyle(tester, valueLabel);
      expect(valueStyle.fontSize, roleSize(CoreTextStyles.labelMedium));
      expect(valueStyle.fontWeight, material.FontWeight.w400);
      expect(valueStyle.color, _token(theme, CoreColors.onSurfaceVariant));

      final captionStyle = _paintedStyle(tester, caption);
      expect(captionStyle.fontSize, roleSize(CoreTextStyles.bodyXs));
      expect(captionStyle.color, _token(theme, CoreColors.onSurfaceSubtle));
    });

    testWidgets('label row above, caption below, 8 apart from the bar', (
      tester,
    ) async {
      await pumpBar(
        tester,
        const Progress(
          value: _kTestProgressHalf,
          label: Text(label),
          valueLabel: Text(valueLabel),
          caption: Text(caption),
        ),
      );
      final track = tester.getRect(
        find
            .descendant(
              of: find.byType(Progress),
              matching: find.byType(material.Container),
            )
            .first,
      );
      final bar = tester.getRect(find.byType(Progress));
      final labelRect = tester.getRect(find.text(label));
      final valueRect = tester.getRect(find.text(valueLabel));
      final captionRect = tester.getRect(find.text(caption));

      expect(labelRect.left, bar.left, reason: 'label starts the row');
      expect(valueRect.right, bar.right, reason: 'value label ends the row');
      expect(track.width, bar.width, reason: 'the bar keeps its full width');
      expect(track.top - labelRect.bottom, CoreSpace.space8);
      expect(captionRect.top - track.bottom, CoreSpace.space8);
      expect(captionRect.left, bar.left);
    });

    testWidgets('a lone value label still sits at the end', (tester) async {
      await pumpBar(
        tester,
        const Progress(value: _kTestProgressHalf, valueLabel: Text(valueLabel)),
      );

      expect(
        tester.getRect(find.text(valueLabel)).right,
        tester.getRect(find.byType(Progress)).right,
      );
    });

    testWidgets('a caption alone draws no label row spacer', (tester) async {
      await pumpBar(
        tester,
        const Progress(value: _kTestProgressHalf, caption: Text(caption)),
      );
      final track = tester.getRect(
        find
            .descendant(
              of: find.byType(Progress),
              matching: find.byType(material.Container),
            )
            .first,
      );

      expect(track.top, tester.getRect(find.byType(Progress)).top);
      expect(find.byType(Gap), findsOneWidget);
    });

    testWidgets('the label names the bar; the value label is not read twice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpBar(
        tester,
        const Progress(
          value: 0.62,
          label: Text(label),
          valueLabel: Text(valueLabel),
          caption: Text(caption),
        ),
      );

      final node = tester.getSemantics(find.text(label));
      expect(node.label, contains(label));
      // Flutter has one merged node, so the caption joins the NAME here. The
      // Web twin keeps the two apart — `aria-labelledby` names the bar and
      // `aria-describedby` describes it — so a screen reader hears the same
      // words in both, but only Web can tell the name from the description.
      expect(node.label, contains(caption));
      expect(node.label, isNot(contains(valueLabel)));
      expect(node.value, '62%');
      handle.dispose();
    });

    testWidgets('a style override reaches the cells and the spacers', (
      tester,
    ) async {
      await pumpBar(
        tester,
        const Progress(
          value: _kTestProgressHalf,
          label: Text(label),
          caption: Text(caption),
          progressStyle: CoreProgressStyle(
            labelStyle: CoreTextStyle(color: _kTestColor),
            labelGapStyle: CoreGapStyle(size: CoreSpace.space12),
            captionGapStyle: CoreGapStyle(size: CoreSpace.space4),
          ),
        ),
      );
      final track = tester.getRect(
        find
            .descendant(
              of: find.byType(Progress),
              matching: find.byType(material.Container),
            )
            .first,
      );

      final labelStyle = _paintedStyle(tester, label);
      expect(labelStyle.color, _kTestColor.toValue());
      expect(
        labelStyle.fontWeight,
        material.FontWeight.w500,
        reason: 'the default weight survives a colour-only override',
      );
      expect(track.top - tester.getRect(find.text(label)).bottom, 12);
      expect(tester.getRect(find.text(caption)).top - track.bottom, 4);
    });

    test('copyWith carries the tone and the cells', () {
      const original = Progress(
        tone: CoreProgressTone.warning,
        label: Text(label),
        valueLabel: Text(valueLabel),
        caption: Text(caption),
      );
      final copy = original.copyWith(value: _kTestProgressHalf);

      expect(copy.tone, CoreProgressTone.warning);
      expect(copy.label, original.label);
      expect(copy.valueLabel, original.valueLabel);
      expect(copy.caption, original.caption);
    });
  });
}
