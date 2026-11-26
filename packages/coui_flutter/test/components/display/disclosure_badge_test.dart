import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kOpenLabel = '공개 · 지금 열람';
const _kCommitmentLabel = '계약 시 제공';
const _kPrivateLabel = '비공개 · NDA';

const _kOverrideBorderWidth = 3.0;
const _kOverrideMarkerSpacing = 17.0;

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Align(child: SizedBox(width: 400, child: child)),
    ),
  ),
);

/// Resolves a [ResolvedDisclosureBadge] inside a real element tree, so
/// `Theme.of(context)` / the colour scheme run against a live theme.
Future<ResolvedDisclosureBadge> _resolve(
  WidgetTester tester, {
  required CoreDisclosureKind kind,
  CoreDisclosureBadgeStyle? disclosureBadgeStyle,
  CoreDisclosureBadgeTheme? componentTheme,
  bool dark = false,
}) async {
  late ResolvedDisclosureBadge resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          colorScheme: dark
              ? CoreThemePresets.darkColorScheme
              : CoreThemePresets.lightColorScheme,
          coreComponentTheme: CoreComponentTheme(
            disclosureBadge: componentTheme,
          ),
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveDisclosureBadge(
              context,
              kind: kind,
              disclosureBadgeStyle: disclosureBadgeStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

void main() {
  // ═══════════════════════════════════════════════
  // Shape — the reason the component exists
  // ═══════════════════════════════════════════════

  group('the three kinds stay apart without colour', () {
    testWidgets('private is the only dashed outline, and it is painted', (
      tester,
    ) async {
      for (final kind in CoreDisclosureKind.values) {
        await tester.pumpWidget(
          _app(DisclosureBadge(kind: kind, label: 'x')),
        );

        final painted = find.descendant(
          of: find.byType(DisclosureBadge),
          matching: find.byType(CustomPaint),
        );
        final decorated = find.descendant(
          of: find.byType(DisclosureBadge),
          matching: find.byType(DecoratedBox),
        );

        if (kind.stroke == CoreDisclosureStroke.dashed) {
          expect(
            painted,
            findsWidgets,
            reason:
                'Flutter has no dashed BorderSide, so a private badge that '
                'is not hand-painted is a solid one — and then the kind '
                'that says "withheld" is separated from the others by '
                'colour alone (WCAG 1.4.1).',
          );
        } else {
          expect(decorated, findsWidgets);
        }
      }
    });

    testWidgets('only commitment renders the marker dot', (tester) async {
      for (final kind in CoreDisclosureKind.values) {
        await tester.pumpWidget(
          _app(DisclosureBadge(kind: kind, label: 'x')),
        );

        expect(
          find.descendant(
            of: find.byType(DisclosureBadge),
            matching: find.byType(ExcludeSemantics),
          ),
          kind.hasMarker ? findsOneWidget : findsNothing,
          reason:
              'commitment and open share a solid outline, so the dot is '
              'the only non-colour signal left between them.',
        );
      }
    });

    testWidgets('no theme can flatten the shapes', (tester) async {
      // A theme that pushes all three kinds to one colour — the exact
      // move the component is built to survive.
      const flat = CoreDisclosureBadgeStyle(
        foregroundColor: CoreColor.token(CoreColors.onSurface),
        borderColor: CoreColor.token(CoreColors.onSurface),
      );
      final strokes = <CoreDisclosureKind, bool>{};
      final markers = <CoreDisclosureKind, bool>{};

      for (final kind in CoreDisclosureKind.values) {
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: ThemeData(
                coreComponentTheme: const CoreComponentTheme(
                  disclosureBadge: CoreDisclosureBadgeTheme(
                    style: flat,
                    kindStyles: {
                      CoreDisclosureKind.open: flat,
                      CoreDisclosureKind.commitment: flat,
                      CoreDisclosureKind.private: flat,
                    },
                  ),
                ),
              ),
              child: material.Scaffold(
                body: Align(
                  child: DisclosureBadge(kind: kind, label: 'x'),
                ),
              ),
            ),
          ),
        );

        strokes[kind] = find
            .descendant(
              of: find.byType(DisclosureBadge),
              matching: find.byType(CustomPaint),
            )
            .evaluate()
            .isNotEmpty;
        markers[kind] = find
            .descendant(
              of: find.byType(DisclosureBadge),
              matching: find.byType(ExcludeSemantics),
            )
            .evaluate()
            .isNotEmpty;
      }

      expect(strokes[CoreDisclosureKind.private], isTrue);
      expect(strokes[CoreDisclosureKind.open], isFalse);
      expect(markers[CoreDisclosureKind.commitment], isTrue);
      expect(markers[CoreDisclosureKind.open], isFalse);
    });
  });

  // ═══════════════════════════════════════════════
  // The state is written down
  // ═══════════════════════════════════════════════

  group('label', () {
    testWidgets('is rendered as text for every kind', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              DisclosureBadge(
                kind: CoreDisclosureKind.open,
                label: _kOpenLabel,
              ),
              DisclosureBadge(
                kind: CoreDisclosureKind.commitment,
                label: _kCommitmentLabel,
              ),
              DisclosureBadge(
                kind: CoreDisclosureKind.private,
                label: _kPrivateLabel,
              ),
            ],
          ),
        ),
      );

      expect(find.text(_kOpenLabel), findsOneWidget);
      expect(find.text(_kCommitmentLabel), findsOneWidget);
      expect(find.text(_kPrivateLabel), findsOneWidget);
    });

    test('an empty one is rejected at construction', () {
      expect(
        () => DisclosureBadge(kind: CoreDisclosureKind.private, label: ''),
        throwsAssertionError,
        reason:
            'A wordless outline states the disclosure state through '
            'colour and shape alone, which is what this component exists '
            'to prevent.',
      );
    });
  });

  // ═══════════════════════════════════════════════
  // resolveDisclosureBadge — merge chain
  // ═══════════════════════════════════════════════

  group('resolveDisclosureBadge', () {
    testWidgets('each kind takes its own colour pair', (tester) async {
      final open = await _resolve(tester, kind: CoreDisclosureKind.open);
      final commitment = await _resolve(
        tester,
        kind: CoreDisclosureKind.commitment,
      );
      final private = await _resolve(tester, kind: CoreDisclosureKind.private);

      expect(
        private.foregroundColor,
        isNot(open.foregroundColor),
        reason:
            'Painting the unopenable thing in the colour of the openable '
            'thing is a lie the reader only discovers after clicking.',
      );
      expect(commitment.borderColor, private.borderColor);
      expect(open.borderColor, isNot(private.borderColor));
    });

    testWidgets('a token colour tracks the active scheme', (tester) async {
      final light = await _resolve(tester, kind: CoreDisclosureKind.private);
      final dark = await _resolve(
        tester,
        kind: CoreDisclosureKind.private,
        dark: true,
      );

      expect(
        dark.foregroundColor,
        isNot(light.foregroundColor),
        reason:
            'A colour frozen at its light value is the dark-mode '
            'regression scheme.resolve exists to prevent.',
      );
    });

    testWidgets('falls back to the design-system chrome', (tester) async {
      final resolved = await _resolve(tester, kind: CoreDisclosureKind.open);

      expect(
        resolved.borderWidth,
        CoreDisclosureBadgeStyle.defaultBorderWidth,
      );
      expect(
        resolved.markerSize,
        CoreDisclosureBadgeStyle.defaultMarkerSize,
      );
      expect(
        resolved.markerSpacing,
        CoreDisclosureBadgeStyle.defaultMarkerSpacing,
      );
      expect(resolved.dashLength, greaterThan(0));
      expect(resolved.dashGap, greaterThan(0));
    });

    testWidgets('the instance override wins over the per-kind theme', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        kind: CoreDisclosureKind.commitment,
        componentTheme: const CoreDisclosureBadgeTheme(
          style: CoreDisclosureBadgeStyle(
            borderWidth: 9,
            markerSpacing: _kOverrideMarkerSpacing,
          ),
          kindStyles: {
            CoreDisclosureKind.commitment: CoreDisclosureBadgeStyle(
              borderWidth: 5,
            ),
          },
        ),
        disclosureBadgeStyle: const CoreDisclosureBadgeStyle(
          borderWidth: _kOverrideBorderWidth,
        ),
      );

      expect(resolved.borderWidth, _kOverrideBorderWidth);
      expect(
        resolved.markerSpacing,
        _kOverrideMarkerSpacing,
        reason: 'An override of one field must not drop the rest.',
      );
    });

    testWidgets('the label colour follows the kind foreground', (
      tester,
    ) async {
      final resolved = await _resolve(tester, kind: CoreDisclosureKind.open);

      expect(resolved.labelTextStyle.color, resolved.foregroundColor);
    });

    testWidgets('a typographic override keeps the rest of the role', (
      tester,
    ) async {
      final plain = await _resolve(tester, kind: CoreDisclosureKind.open);
      final bold = await _resolve(
        tester,
        kind: CoreDisclosureKind.open,
        disclosureBadgeStyle: const CoreDisclosureBadgeStyle(
          labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );

      expect(bold.labelTextStyle.fontWeight, CoreFontWeight.bold.weight);
      expect(bold.labelTextStyle.fontSize, plain.labelTextStyle.fontSize);
      expect(bold.labelTextStyle.color, plain.labelTextStyle.color);
    });
  });

  // ═══════════════════════════════════════════════
  // Static by construction
  // ═══════════════════════════════════════════════

  group('the badge is not a control', () {
    testWidgets('carries no gesture, no cursor, no fill', (tester) async {
      await tester.pumpWidget(
        _app(
          const DisclosureBadge(
            kind: CoreDisclosureKind.open,
            label: _kOpenLabel,
          ),
        ),
      );

      final scope = find.byType(DisclosureBadge);
      expect(
        find.descendant(of: scope, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(
        find.descendant(of: scope, matching: find.byType(MouseRegion)),
        findsNothing,
        reason:
            'Pointer feedback on a static marker promises an interaction '
            'that does not exist.',
      );

      final decoration =
          tester
                  .widgetList<DecoratedBox>(
                    find.descendant(
                      of: scope,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .first
                  .decoration
              as BoxDecoration;
      expect(
        decoration.color,
        isNull,
        reason: 'A fill is what makes a Chip read as pressable.',
      );
    });
  });

  // ═══════════════════════════════════════════════
  // Chain sugar
  // ═══════════════════════════════════════════════

  group('withStyle', () {
    test('merges into the existing style, patch wins', () {
      final badge =
          const DisclosureBadge(
                kind: CoreDisclosureKind.private,
                label: _kPrivateLabel,
              )
              .withStyle(
                const CoreDisclosureBadgeStyle(
                  borderWidth: _kOverrideBorderWidth,
                  markerSpacing: _kOverrideMarkerSpacing,
                ),
              )
              .withStyle(const CoreDisclosureBadgeStyle(borderWidth: 5));

      expect(badge.disclosureBadgeStyle?.borderWidth, 5);
      expect(
        badge.disclosureBadgeStyle?.markerSpacing,
        _kOverrideMarkerSpacing,
      );
      expect(badge.kind, CoreDisclosureKind.private);
      expect(badge.label, _kPrivateLabel);
    });

    test('copyWith keeps every field it was not given', () {
      const original = DisclosureBadge(
        kind: CoreDisclosureKind.commitment,
        label: _kCommitmentLabel,
      );
      final copy = original.copyWith(label: _kOpenLabel);

      expect(copy.kind, CoreDisclosureKind.commitment);
      expect(copy.label, _kOpenLabel);
    });
  });
}
