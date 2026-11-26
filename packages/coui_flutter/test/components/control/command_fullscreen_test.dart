import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  const glyphSizes = {
    CoreCommandSize.sm: 16.0,
    CoreCommandSize.md: 18.0,
    CoreCommandSize.lg: 20.0,
  };
  const buttonSizes = {
    CoreCommandSize.sm: 32.0,
    CoreCommandSize.md: 40.0,
    CoreCommandSize.lg: 48.0,
  };
  for (final size in CoreCommandSize.values) {
    for (final dark in [false, true]) {
      testWidgets(
        'fullscreen ${size.name} dark=$dark paints a square back button '
        'and dismisses',
        (tester) async {
          var dismissals = 0;
          await pumpTestApp(
            tester,
            Command(
              groups: const [],
              presentation: .fullscreen,
              size: size,
              onDismiss: () => dismissals++,
            ),
            theme: ThemeData.fromCore(
              dark ? CoreThemePresets.dark : CoreThemePresets.light,
            ),
          );
          final arrow = find.byWidgetPredicate(
            (widget) => widget is Icon && widget.icon == LucideIcons.arrowLeft,
          );
          final button = find.ancestor(
            of: arrow,
            matching: find.byType(Button),
          );
          final svg = find.descendant(
            of: arrow,
            matching: find.byType(SvgPicture),
          );
          expect(tester.getSize(button), Size.square(buttonSizes[size]!));
          expect(tester.getSize(svg), Size.square(glyphSizes[size]!));
          expect(tester.getCenter(svg), tester.getCenter(button));
          final context = tester.element(arrow);
          final ink = Theme.of(context).colorScheme
              .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
              .toValue();
          expect(
            tester.widget<SvgPicture>(svg).colorFilter,
            ColorFilter.mode(ink, BlendMode.srcIn),
          );
          expect(
            tester.widget<Icon>(arrow).iconStyle!.size,
            isNull,
            reason: 'Button supplies the default icon size',
          );
          // Hit near the button edge, outside the smaller glyph's box.
          await tester.tapAt(
            tester.getTopLeft(button) + Offset(2, buttonSizes[size]! / 2),
          );
          await tester.pump();
          expect(dismissals, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('inline and dialog ${size.name} retain their search glyph', (
      tester,
    ) async {
      for (final presentation in [
        CoreCommandPresentation.inline,
        CoreCommandPresentation.dialog,
      ]) {
        await pumpTestApp(
          tester,
          Command(
            groups: const [],
            presentation: presentation,
            size: size,
            onDismiss: () {},
          ),
        );
        final search = find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == LucideIcons.search,
        );
        final svg = find.descendant(
          of: search,
          matching: find.byType(SvgPicture),
        );
        expect(
          tester.getSize(svg),
          Size.square(
            {
              CoreCommandSize.sm: 16.0,
              CoreCommandSize.md: 20.0,
              CoreCommandSize.lg: 24.0,
            }[size]!,
          ),
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Icon && widget.icon == LucideIcons.arrowLeft,
          ),
          findsNothing,
        );
      }
    });
  }
  testWidgets('fullscreen retains explicit back glyph overrides', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Command(
        groups: const [],
        presentation: .fullscreen,
        onDismiss: () {},
        commandStyle: const CoreCommandStyle(
          backIconStyle: CoreIconStyle(
            size: 22,
            color: CoreColor(0xff123456),
          ),
        ),
      ),
    );
    final arrow = find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == LucideIcons.arrowLeft,
    );
    final svg = find.descendant(of: arrow, matching: find.byType(SvgPicture));
    expect(tester.getSize(svg), const Size.square(22));
    expect(
      tester.widget<SvgPicture>(svg).colorFilter,
      const ColorFilter.mode(Color(0xff123456), BlendMode.srcIn),
    );
  });
}
