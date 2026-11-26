import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kCursorWidth = 20.0;
const _kTestText = 'Hello, World!';
const _kTestFontSize = 20.0;

material.Widget _buildApp(material.Widget child, {ThemeData? theme}) =>
    material.MaterialApp(
      home: Theme(data: theme ?? const ThemeData(), child: child),
    );

void main() {
  group('SelectableText', () {
    for (final coreTheme in [CoreThemePresets.light, CoreThemePresets.dark]) {
      for (final rich in [false, true]) {
        testWidgets('primary cursor preserves the toggle and overrides '
            '(${coreTheme.brightness}, rich=$rich)', (tester) async {
          final theme = ThemeData.fromCore(coreTheme);
          final primary = theme.colorScheme
              .resolve(const CoreColor.token(CoreColors.primary))
              .toValue();
          final selection = theme.colorScheme
              .resolve(const CoreColor.token(CoreColors.primaryContainer))
              .toValue();

          SelectableText content({bool? showCursor}) {
            final base = rich
                ? const SelectableText.rich(children: [Text(_kTestText)])
                : const SelectableText(_kTestText);
            return base.copyWith(showCursor: showCursor);
          }

          Future<material.EditableText> pump(
            SelectableText child, {
            CoreComponentTheme? componentTheme,
          }) async {
            await tester.pumpWidget(
              _buildApp(
                child,
                theme: componentTheme == null
                    ? theme
                    : theme.copyWith(coreComponentTheme: () => componentTheme),
              ),
            );
            return tester.widget<material.EditableText>(
              find.byType(material.EditableText),
            );
          }

          final hidden = await pump(content());
          expect(hidden.showCursor, isFalse);
          expect(hidden.cursorColor, primary);
          expect(hidden.selectionColor, selection);

          final shown = await pump(content(showCursor: true));
          expect(shown.showCursor, isTrue);
          expect(shown.cursorColor, primary);
          expect(shown.selectionColor, selection);

          const themed = CoreComponentTheme(
            selectableText: CoreSelectableTextTheme(
              style: CoreSelectableTextStyle(
                cursorColor: CoreColor.token(CoreColors.tertiary),
              ),
            ),
          );
          final inherited = await pump(
            content(showCursor: true),
            componentTheme: themed,
          );
          expect(
            inherited.cursorColor,
            theme.colorScheme
                .resolve(const CoreColor.token(CoreColors.tertiary))
                .toValue(),
          );

          final overridden = await pump(
            content(showCursor: true).withStyle(
              const CoreSelectableTextStyle(
                cursorColor: CoreColor.token(CoreColors.error),
              ),
            ),
            componentTheme: themed,
          );
          expect(
            overridden.cursorColor,
            theme.colorScheme
                .resolve(const CoreColor.token(CoreColors.error))
                .toValue(),
          );
          expect(overridden.showCursor, isTrue);
          expect(overridden.selectionColor, selection);
          final hiddenAgain = await pump(content(showCursor: false));
          expect(hiddenAgain.showCursor, isFalse);
          expect(hiddenAgain.cursorColor, primary);
        });
      }
    }

    testWidgets('renders with data string', (tester) async {
      await tester.pumpWidget(
        _buildApp(const SelectableText(_kTestText)),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text(_kTestText), findsOneWidget);
    });

    testWidgets('renders with style via selectableTextStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SelectableText(
            _kTestText,
            selectableTextStyle: CoreSelectableTextStyle(
              textStyle: CoreTextStyle(fontSize: _kTestFontSize),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final widget = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      expect(widget.style?.fontSize, equals(_kTestFontSize));
    });

    testWidgets('renders with textAlign', (tester) async {
      await tester.pumpWidget(
        _buildApp(const SelectableText(_kTestText, textAlign: .center)),
      );
      final _ = await tester.pumpAndSettle();

      final widget = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      expect(widget.textAlign, isNotNull);
      expect(widget.textAlign == .center, isTrue);
    });

    testWidgets('renders with maxLines', (tester) async {
      await tester.pumpWidget(
        _buildApp(const SelectableText(_kTestText, maxLines: 2)),
      );
      final _ = await tester.pumpAndSettle();

      final widget = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      expect(widget.maxLines, equals(2));
    });

    testWidgets('renders SelectableText.rich with children', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SelectableText.rich(children: [Text(_kTestText)]),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(material.SelectableText), findsOneWidget);
    });

    testWidgets('applies CoUI selection tint via a DefaultSelectionStyle '
        'ancestor (not the Material default)', (tester) async {
      await tester.pumpWidget(_buildApp(const SelectableText(_kTestText)));
      final _ = await tester.pumpAndSettle();

      // The wrapper this component adds is the closest DefaultSelectionStyle
      // ancestor of the inner material.SelectableText.
      final style = tester
          .widgetList<DefaultSelectionStyle>(
            find.ancestor(
              of: find.byType(material.SelectableText),
              matching: find.byType(DefaultSelectionStyle),
            ),
          )
          .first;
      expect(style.selectionColor, isNotNull);
      // CoUI tint = the `primaryContainer` token's colour, opaque — the band
      // sits behind the text, so it needs no alpha of its own. Distinguishes
      // it from the ambient Material selection colour that would otherwise
      // be inherited.
      expect(style.selectionColor!.a, 1.0);
    });

    testWidgets('the selection tint is primary-container, not primary', (
      tester,
    ) async {
      late ThemeData theme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SelectableText(_kTestText);
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tint = tester
          .widgetList<DefaultSelectionStyle>(
            find.ancestor(
              of: find.byType(material.SelectableText),
              matching: find.byType(DefaultSelectionStyle),
            ),
          )
          .first
          .selectionColor!;
      material.Color token(CoreColorToken t) =>
          theme.colorScheme.resolve(CoreColor.token(t)).toValue();
      final container = token(CoreColors.primaryContainer);
      final primary = token(CoreColors.primary);

      expect(tint.r, closeTo(container.r, 0.002));
      expect(tint.g, closeTo(container.g, 0.002));
      expect(tint.b, closeTo(container.b, 0.002));
      expect(
        tint.r == primary.r && tint.g == primary.g && tint.b == primary.b,
        isFalse,
      );
    });

    testWidgets('a selectionColor override is painted as given, alpha too', (
      tester,
    ) async {
      // The highlight sits behind the text, so the caller's own opacity is
      // the opacity drawn — nothing multiplies or replaces it.
      await tester.pumpWidget(
        _buildApp(
          const SelectableText(
            _kTestText,
            selectableTextStyle: CoreSelectableTextStyle(
              selectionColor: CoreColor.token(
                CoreColors.primary,
                opacity: CoreOpacity.opacity25,
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tint = tester
          .widgetList<DefaultSelectionStyle>(
            find.ancestor(
              of: find.byType(material.SelectableText),
              matching: find.byType(DefaultSelectionStyle),
            ),
          )
          .first
          .selectionColor!;

      expect(tint.a, closeTo(CoreOpacity.opacity25, 0.01));
    });

    testWidgets('a selectionColor override replaces the tint', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SelectableText(
                _kTestText,
                selectableTextStyle: CoreSelectableTextStyle(
                  selectionColor: CoreColor.token(CoreColors.tertiary),
                ),
              );
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tint = tester
          .widgetList<DefaultSelectionStyle>(
            find.ancestor(
              of: find.byType(material.SelectableText),
              matching: find.byType(DefaultSelectionStyle),
            ),
          )
          .first
          .selectionColor!;
      final tertiary = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.tertiary))
          .toValue();

      expect(tint.r, closeTo(tertiary.r, 0.002));
      expect(tint.g, closeTo(tertiary.g, 0.002));
      expect(tint.b, closeTo(tertiary.b, 0.002));
    });

    testWidgets('the selected text keeps the on-surface colour', (
      tester,
    ) async {
      // Selecting changes the band, not the glyphs: the text style the
      // component draws with states `onSurface` and no selection state
      // rewrites it.
      late ThemeData theme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SelectableText(_kTestText);
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final widget = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      final onSurface = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.onSurface))
          .toValue();
      final body = theme.typography.bodyMedium.toValue(theme: theme);

      expect(widget.style?.color, onSurface);
      expect(widget.style?.fontSize, body.fontSize);
    });

    testWidgets('uses coreComponentTheme cursorWidth when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(
              coreComponentTheme: CoreComponentTheme(
                selectableText: CoreSelectableTextTheme(
                  style: CoreSelectableTextStyle(cursorWidth: _kCursorWidth),
                ),
              ),
            ),
            child: SelectableText(_kTestText),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final widget = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      expect(widget.cursorWidth, equals(_kCursorWidth));
    });
  });
}
