import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

const _kTestText = 'Hello';

/// 세그먼트 수직 중심 비교 시 허용 오차 (px) — then() fall-through 회귀 테스트용.
const _kVerticalCenterEpsilon = 0.5;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// Reads the **resolved** font weight the chain actually applied to the
/// rendered text — the `RichText` the inner `Text` builds carries the
/// inherited `DefaultTextStyle` (set by `WrappedText`) merged with its
/// own style, so its `fontWeight` is the effective paint-time value.
FontWeight? _resolvedWeight(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(WrappedText),
          matching: find.byType(RichText),
        )
        .first,
  );
  return richText.text.style?.fontWeight;
}

/// Reads the whole **resolved** text style the rendered `RichText` paints
/// with — the chain's `DefaultTextStyle.merge` folded onto whatever the
/// ancestors set.
TextStyle _resolvedStyle(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(WrappedText),
          matching: find.byType(RichText),
        )
        .first,
  );
  return richText.text.style!;
}

/// Ambient text style a surrounding slot lays down (a card header that
/// set `titleMedium`-like chrome) — every property differs from the
/// `bodyMedium` baseline so an inherited value is distinguishable from a
/// reset one.
TextStyle _ambientStyle(ThemeData theme) => TextStyle(
  color: theme.colorScheme.primary.toValue(),
  fontSize: CoreFontSize.s24,
  fontWeight: CoreFontWeight.light.weight,
  height: CoreLineHeight.h180,
);

/// Pumps [chain] under a `DefaultTextStyle` carrying [_ambientStyle] and
/// returns the theme it resolved against.
Future<ThemeData> _pumpUnderAmbient(
  WidgetTester tester,
  Widget chain,
) async {
  late ThemeData theme;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          theme = Theme.of(context);
          return DefaultTextStyle(style: _ambientStyle(theme), child: chain);
        },
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();
  return theme;
}

void main() {
  group('TextExtension', () {
    group('font size extensions', () {
      testWidgets('.labelMedium returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).labelMedium),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.bodySmall returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodySmall),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.bodyMedium returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodyMedium),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.bodyLarge returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodyLarge),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.titleLarge returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).titleLarge),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.headlineSmall returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).headlineSmall),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.headlineLarge returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).headlineLarge),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.displaySmall returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).displaySmall),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('font family extensions', () {
      testWidgets('.sans returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).sans),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.mono returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).mono),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('font weight extensions', () {
      testWidgets('.thin returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).thin),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.light returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).light),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.regular returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).regular),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.medium returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).medium),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.semiBold returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).semiBold),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.bold returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bold),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.extraBold returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).extraBold),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.black returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).black),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('font style extensions', () {
      testWidgets('.italic returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).italic),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.underline returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).underline),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('semantic text extensions', () {
      testWidgets('.displaySmall returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).displaySmall),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.headlineSmall returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).headlineSmall),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.bodyLarge returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodyLarge),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.titleLarge returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).titleLarge),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.titleLarge returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).titleLarge),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.bodySmall returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodySmall),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('the 22-role scale and its primitives', () {
      // The roles and primitives the Web chain names too. Each must wrap
      // its child and read its own role from the theme — not fall back to
      // the `bodyMedium` baseline a role chain starts from.
      final roles = <String, (Widget, CoreTextStyle Function(ThemeData))>{
        'bodyXs': (const Text(_kTestText).bodyXs, (t) => t.typography.bodyXs),
        'labelXs': (
          const Text(_kTestText).labelXs,
          (t) => t.typography.labelXs,
        ),
        'codeXs': (const Text(_kTestText).codeXs, (t) => t.typography.codeXs),
        'codeSm': (const Text(_kTestText).codeSm, (t) => t.typography.codeSm),
        'codeMd': (const Text(_kTestText).codeMd, (t) => t.typography.codeMd),
      };

      for (final MapEntry(key: name, value: (chain, role)) in roles.entries) {
        testWidgets('.$name reads its own role', (tester) async {
          late ThemeData theme;
          await tester.pumpWidget(
            _buildApp(
              Builder(
                builder: (context) {
                  theme = Theme.of(context);
                  return chain;
                },
              ),
            ),
          );
          final _ = await tester.pumpAndSettle();

          expect(find.byType(WrappedText), findsOneWidget);
          final style = _resolvedStyle(tester);
          final expected = role(theme).toValue(theme: theme);
          expect(style.fontSize, expected.fontSize);
          expect(style.fontWeight, expected.fontWeight);
          expect(style.fontFamily, expected.fontFamily);
          expect(style.letterSpacing, expected.letterSpacing);
        });
      }

      final primitives = <String, (Widget, double? Function(TextStyle))>{
        's11': (const Text(_kTestText).s11, (s) => s.fontSize),
        's13': (const Text(_kTestText).s13, (s) => s.fontSize),
        's15': (const Text(_kTestText).s15, (s) => s.fontSize),
        'h150': (const Text(_kTestText).h150, (s) => s.height),
      };
      const expectedPrimitive = {
        's11': CoreFontSize.s11,
        's13': CoreFontSize.s13,
        's15': CoreFontSize.s15,
        'h150': CoreLineHeight.h150,
      };

      for (final MapEntry(key: name, value: (chain, read))
          in primitives.entries) {
        testWidgets('.$name sets ${expectedPrimitive[name]}', (tester) async {
          await tester.pumpWidget(_buildApp(chain));
          final _ = await tester.pumpAndSettle();

          expect(find.byType(WrappedText), findsOneWidget);
          expect(read(_resolvedStyle(tester)), expectedPrimitive[name]);
        });
      }
    });

    // A code role states a fixed 21px line box. Flutter's `height` is a
    // multiplier, so the chain resolves the box against the final size —
    // a later size modifier keeps the line where the Web keeps it, and a
    // later line-height statement replaces the box.
    group('fixed line box of the code roles', () {
      double lineOf(TextStyle style) => style.height! * style.fontSize!;

      Future<TextStyle> pumpChain(WidgetTester tester, Widget chain) async {
        await tester.pumpWidget(_buildApp(chain));
        final _ = await tester.pumpAndSettle();
        return _resolvedStyle(tester);
      }

      testWidgets('.codeMd draws 21px in the mono stack, untracked', (
        tester,
      ) async {
        final style = await pumpChain(tester, const Text(_kTestText).codeMd);

        expect(style.fontSize, CoreFontSize.s13);
        expect(lineOf(style), closeTo(CoreLineBox.px21, 1e-9));
        // The `bodyMedium` baseline under a role chain carries −1% tracking
        // and a 1.5 multiplier; neither may leak into code text.
        expect(style.letterSpacing, 0);
        expect(style.fontFamily, CoreFontFamily.mono);
        expect(style.fontFamilyFallback, kCoreMonoFontFallback);
      });

      testWidgets('.codeMd.s16 keeps the 21px line', (tester) async {
        final style = await pumpChain(
          tester,
          const Text(_kTestText).codeMd.s16,
        );

        expect(style.fontSize, CoreFontSize.s16);
        expect(lineOf(style), closeTo(CoreLineBox.px21, 1e-9));
      });

      testWidgets('.codeSm.fontSize(v) keeps the 21px line', (tester) async {
        final style = await pumpChain(
          tester,
          const Text(_kTestText).codeSm.fontSize(CoreFontSize.s20),
        );

        expect(lineOf(style), closeTo(CoreLineBox.px21, 1e-9));
      });

      testWidgets('a later .h140 replaces the box', (tester) async {
        final style = await pumpChain(
          tester,
          const Text(_kTestText).codeMd.h140,
        );

        expect(style.height, CoreLineHeight.h140);
      });

      testWidgets('a later .lineHeight(v) replaces the box', (tester) async {
        final style = await pumpChain(
          tester,
          const Text(_kTestText).codeMd.s16.lineHeight(CoreLineHeight.h160),
        );

        expect(style.height, CoreLineHeight.h160);
      });

      testWidgets('a height passed to call() replaces the box', (
        tester,
      ) async {
        final style = await pumpChain(
          tester,
          const Text(_kTestText).codeMd(height: CoreLineHeight.h200),
        );

        expect(style.height, CoreLineHeight.h200);
      });

      testWidgets('a later multiplier role replaces the box', (tester) async {
        late ThemeData theme;
        await tester.pumpWidget(
          _buildApp(
            Builder(
              builder: (context) {
                theme = Theme.of(context);
                return const Text(_kTestText).codeMd.bodyMedium;
              },
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(
          _resolvedStyle(tester).height,
          theme.typography.bodyMedium.toValue(theme: theme).height,
        );
      });

      testWidgets('a code role after a multiplier restates the box', (
        tester,
      ) async {
        final style = await pumpChain(
          tester,
          const Text(_kTestText).h140.codeMd.s16,
        );

        expect(lineOf(style), closeTo(CoreLineBox.px21, 1e-9));
      });
    });

    group('color extensions', () {
      testWidgets('.foreground returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).foreground),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('.onSurface returns WrappedText wrapping the widget', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).onSurface),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets(
        '.onPrimaryContainer wraps the widget with a TextModifier',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(const Text(_kTestText).onPrimaryContainer),
          );
          final _ = await tester.pumpAndSettle();

          expect(find.byType(WrappedText), findsAtLeast(1));
          expect(find.text(_kTestText), findsOneWidget);
        },
      );

      testWidgets(
        '.onErrorContainer wraps the widget with a TextModifier',
        (tester) async {
          await tester.pumpWidget(
            _buildApp(const Text(_kTestText).onErrorContainer),
          );
          final _ = await tester.pumpAndSettle();

          expect(find.byType(WrappedText), findsAtLeast(1));
          expect(find.text(_kTestText), findsOneWidget);
        },
      );
    });

    group('chained extensions', () {
      testWidgets('can chain .bodyLarge.bold', (tester) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodyLarge.bold),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('can chain .bodySmall.italic', (tester) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).bodySmall.italic),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('can chain .titleLarge.semiBold.italic', (tester) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).titleLarge.semiBold.italic),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(WrappedText), findsAtLeast(1));
        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('resolved fontWeight (chain → RichText paint-time value)', () {
      testWidgets('.medium resolves to FontWeight.w500', (tester) async {
        await tester.pumpWidget(_buildApp(const Text(_kTestText).medium));
        final _ = await tester.pumpAndSettle();
        expect(_resolvedWeight(tester), FontWeight.w500);
      });

      testWidgets('.semiBold resolves to FontWeight.w600', (tester) async {
        await tester.pumpWidget(_buildApp(const Text(_kTestText).semiBold));
        final _ = await tester.pumpAndSettle();
        expect(_resolvedWeight(tester), FontWeight.w600);
      });

      testWidgets('.bold resolves to FontWeight.w700', (tester) async {
        await tester.pumpWidget(_buildApp(const Text(_kTestText).bold));
        final _ = await tester.pumpAndSettle();
        expect(_resolvedWeight(tester), FontWeight.w700);
      });

      testWidgets('.titleSmall role carries its semibold (w600) weight', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(const Text(_kTestText).titleSmall));
        final _ = await tester.pumpAndSettle();
        expect(_resolvedWeight(tester), FontWeight.w600);
      });

      testWidgets('.titleSmall.medium — later .medium (w500) overrides role', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Text(_kTestText).titleSmall.medium),
        );
        final _ = await tester.pumpAndSettle();
        expect(_resolvedWeight(tester), FontWeight.w500);
      });
    });

    // #4080 — a chain without a role overrides only what it names and
    // inherits the rest from the surrounding text style, like the Web
    // `Text` (which emits only the chain's classes and lets the cascade
    // supply the rest). A role chain still restates the whole style.
    group('partial chain inherits the ambient DefaultTextStyle', () {
      testWidgets('.semiBold keeps the ambient size / line-height / colour', (
        tester,
      ) async {
        final theme = await _pumpUnderAmbient(
          tester,
          const Text(_kTestText).semiBold,
        );
        final style = _resolvedStyle(tester);
        final ambient = _ambientStyle(theme);
        expect(style.fontWeight, CoreFontWeight.semiBold.weight);
        expect(style.fontSize, ambient.fontSize);
        expect(style.height, ambient.height);
        expect(style.color, ambient.color);
      });

      testWidgets('.onSurface changes only the colour', (tester) async {
        final theme = await _pumpUnderAmbient(
          tester,
          const Text(_kTestText).onSurface,
        );
        final style = _resolvedStyle(tester);
        final ambient = _ambientStyle(theme);
        expect(style.color, theme.colorScheme.onSurface.toValue());
        expect(style.fontSize, ambient.fontSize);
        expect(style.fontWeight, ambient.fontWeight);
        expect(style.height, ambient.height);
      });

      testWidgets('an em letter-spacing resolves against the inherited size', (
        tester,
      ) async {
        await _pumpUnderAmbient(tester, const Text(_kTestText).tight);
        final style = _resolvedStyle(tester);
        expect(
          style.letterSpacing,
          CoreLetterSpacing.tight * CoreFontSize.s24,
        );
      });

      testWidgets('a role chain restates size / weight from the role', (
        tester,
      ) async {
        final theme = await _pumpUnderAmbient(
          tester,
          const Text(_kTestText).bodyMedium.semiBold,
        );
        final style = _resolvedStyle(tester);
        final role = theme.typography.bodyMedium.toValue(theme: theme);
        expect(style.fontSize, role.fontSize);
        expect(style.height, role.height);
        expect(style.fontWeight, CoreFontWeight.semiBold.weight);
        expect(style.color, theme.colorScheme.onSurface.toValue());
      });

      testWidgets('a role named after a partial chain still restates it', (
        tester,
      ) async {
        final theme = await _pumpUnderAmbient(
          tester,
          const Text(_kTestText).onPrimary.titleSmall,
        );
        final style = _resolvedStyle(tester);
        final role = theme.typography.titleSmall.toValue(theme: theme);
        expect(style.fontSize, role.fontSize);
        expect(style.color, theme.colorScheme.onPrimary.toValue());
      });
    });

    group('WrappedText', () {
      testWidgets('renders child widget', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            WrappedText(
              style: (context, theme) =>
                  TextStyle(fontWeight: CoreFontWeight.bold.weight),
              child: const Text(_kTestText),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.text(_kTestText), findsOneWidget);
      });

      testWidgets('renders with wrapper', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            WrappedText(
              wrapper: (context, child) => material.Padding(
                padding: material.EdgeInsets.zero,
                child: child,
              ),
              child: const Text(_kTestText),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.text(_kTestText), findsOneWidget);
      });
    });

    group('then() fall-through (chain-modifier receiver, #3256)', () {
      testWidgets('체인 수신자 세그먼트와 .middle WidgetSpan 세그먼트의 수직 중심이 일치한다', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child:
                  TextExtension(
                    const Text('[필수] ').bodySmall.semiBold,
                  ).then(
                    WidgetSpan(
                      alignment: .middle,
                      child: const Text('서비스 이용 약관').bodySmall,
                    ),
                  ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final tagCenter = tester.getCenter(find.text('[필수] '));
        final labelCenter = tester.getCenter(find.text('서비스 이용 약관'));
        expect(
          tagCenter.dy,
          moreOrLessEquals(labelCenter.dy, epsilon: _kVerticalCenterEpsilon),
        );
      });

      testWidgets('fall-through WidgetSpan 은 middle 정렬로 감싼다', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: TextExtension(
                const Text(_kTestText).bodySmall,
              ).thenText(' tail'),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final richText = tester.widget<RichText>(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is RichText &&
                    widget.text is TextSpan &&
                    ((widget.text as TextSpan).children?.firstOrNull
                        is WidgetSpan),
              )
              .first,
        );
        final children = (richText.text as TextSpan).children!;
        final firstSpan = children.first as WidgetSpan;
        expect(firstSpan.alignment, PlaceholderAlignment.middle);
      });
    });

    group('thenLink (Link.inlineSpan with an owned recognizer)', () {
      Future<void> tapText(WidgetTester tester, String needle) async {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.byType(RichText).first,
        );
        final start = paragraph.text.toPlainText().indexOf(needle);
        final box = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: start, extentOffset: start + 1),
            )
            .first
            .toRect();
        await tester.tapAt(
          paragraph.localToGlobal(
            Offset(box.left + box.width / 4, box.center.dy),
          ),
        );
        await tester.pump();
      }

      testWidgets('rides the receiver as one paragraph and fires onPressed', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: const Text('No account? ').thenLink(
                href: '/sign-up',
                text: 'Sign up',
                onPressed: () => taps++,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final paragraph = tester.renderObject<RenderParagraph>(
          find.byType(RichText).first,
        );
        expect(paragraph.text.toPlainText(), 'No account? Sign up');

        await tapText(tester, 'Sign up');
        expect(taps, 1);

        // The words around the link are not part of it.
        await tapText(tester, 'No account?');
        expect(taps, 1);
      });

      testWidgets('survives a rebuild: the new span answers, once', (
        tester,
      ) async {
        var taps = 0;
        late void Function(void Function()) rebuild;
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: material.StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;

                  return const Text('Have an account? ').thenLink(
                    href: '/log-in',
                    text: 'Log in',
                    onPressed: () => taps++,
                  );
                },
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        // Each build hands the previous span's recognizer back, so a tap
        // after several rebuilds must still reach the handler exactly once.
        for (var i = 0; i < 3; i++) {
          rebuild(() {});
          await tester.pump();
        }
        await tapText(tester, 'Log in');

        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows the href when it is given no label', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Center(
              child: const Text('See ').thenLink(href: '/docs'),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final paragraph = tester.renderObject<RenderParagraph>(
          find.byType(RichText).first,
        );
        expect(paragraph.text.toPlainText(), 'See /docs');
      });
    });
  });
}
