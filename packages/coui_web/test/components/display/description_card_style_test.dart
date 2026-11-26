import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

class _CaptureTitle extends StatelessComponent {
  const _CaptureTitle(this.onBuild, {this.style});

  final void Function(ResolvedDescriptionCard value) onBuild;
  final CoreDescriptionCardStyle? style;

  @override
  Component build(BuildContext context) {
    onBuild(
      resolveDescriptionCard(
        context,
        variant: .outlined,
        size: .md,
        descriptionCardStyle: style,
      ),
    );
    return const div([]);
  }
}

void main() {
  for (final tokenColor in [false, true]) {
    testComponents('a role slot owns its color once, token=$tokenColor', (
      tester,
    ) async {
      final color = tokenColor
          ? const CoreColor.token(CoreColors.primary)
          : const CoreColor(0xFF123456);
      late ResolvedDescriptionCard resolved;
      tester.pumpComponent(
        Theme.defaults(
          child: _CaptureTitle(
            (value) => resolved = value,
            style: CoreDescriptionCardStyle(
              titleColor: const CoreColor(0xFF654321),
              titleTextStyle: CoreTextStyle.token(
                CoreTextStyles.codeMd,
                color: color,
              ),
            ),
          ),
        ),
      );

      final classes = resolved.titleText.className.split(' ');
      final css = resolved.titleText.inlineStyles!.properties;
      expect(classes.where((value) => value == 'text-code-md'), hasLength(1));
      expect(
        classes.where((value) => value == 'text-primary'),
        hasLength(tokenColor ? 1 : 0),
      );
      expect(css['color'], tokenColor ? isNull : color.toValue());
    });
  }

  testComponents('an explicit title token uses the shared role emitter', (
    tester,
  ) async {
    late ResolvedDescriptionCard resolved;
    tester.pumpComponent(
      Theme.defaults(
        child: _CaptureTitle(
          (value) => resolved = value,
          style: const CoreDescriptionCardStyle(
            titleTextStyle: CoreTextStyle.token(CoreTextStyles.codeMd),
          ),
        ),
      ),
    );

    expect(resolved.titleText.className, contains('text-code-md'));
    expect(resolved.titleText.className, isNot(contains('text-label-xl')));
    final css = resolved.titleText.inlineStyles!.properties;
    expect(css['font-size'], '0.9375rem');
    // The card's SemiBold rides across a later role (#6470).
    expect(css['font-weight'], '${CoreFontWeight.semiBold}');
    expect(css['line-height'], CssVariableGenerator.lineHeightCss(1.4));
  });

  testComponents('an unset title style retains its role and no inline style', (
    tester,
  ) async {
    late ResolvedDescriptionCard resolved;
    tester.pumpComponent(
      Theme.defaults(child: _CaptureTitle((value) => resolved = value)),
    );

    expect(resolved.titleText.className, contains('text-label-xl'));
    expect(resolved.titleText.inlineStyles, isNull);
  });

  testComponents('all explicit title fields reach the existing carrier', (
    tester,
  ) async {
    late ResolvedDescriptionCard resolved;
    tester.pumpComponent(
      Theme.defaults(
        child: _CaptureTitle(
          (value) => resolved = value,
          style: const CoreDescriptionCardStyle(
            titleColor: CoreColor(0xFF654321),
            titleTextStyle: CoreTextStyle(
              fontSize: 17,
              fontWeight: CoreFontWeight.bold,
              letterSpacing: 0.03,
              lineHeight: 1.3,
              lineHeightPx: 20.3,
              fontFamily: CoreFontFamily.mono,
              color: CoreColor(0xFF123456),
            ),
          ),
        ),
      ),
    );

    final css = resolved.titleText.inlineStyles!.properties;
    expect(css['font-size'], '1.0625rem');
    expect(css['font-weight'], '700');
    expect(css['letter-spacing'], '0.03em');
    expect(css['font-family'], contains('--coui-font-family-mono'));
    expect(
      css['line-height'],
      CssVariableGenerator.roundToPixelCss('1.26875rem'),
    );
    // Preserve the Web path's established slot-color priority when both
    // legacy titleColor and the nested style color are explicitly set.
    expect(css['color'], const CoreColor(0xFF123456).toValue());
  });

  testComponents('widget title fields merge over the component theme', (
    tester,
  ) async {
    late ResolvedDescriptionCard resolved;
    tester.pumpComponent(
      Theme(
        data: ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            descriptionCard: CoreDescriptionCardTheme(
              style: CoreDescriptionCardStyle(
                titleTextStyle: CoreTextStyle(
                  fontSize: 17,
                  lineHeightPx: 20.3,
                  fontFamily: CoreFontFamily.mono,
                ),
              ),
            ),
          ),
        ),
        child: _CaptureTitle(
          (value) => resolved = value,
          style: const CoreDescriptionCardStyle(
            titleTextStyle: CoreTextStyle(
              fontWeight: CoreFontWeight.bold,
              lineHeight: 1.3,
            ),
          ),
        ),
      ),
    );

    final css = resolved.titleText.inlineStyles!.properties;
    expect(css['font-size'], '1.0625rem');
    expect(css['font-weight'], '700');
    expect(css['font-family'], contains('--coui-font-family-mono'));
    expect(css['line-height'], CssVariableGenerator.lineHeightCss(1.3));
    expect(
      css['line-height'],
      CssVariableGenerator.lineHeightCss(1.3),
    );
  });
}
