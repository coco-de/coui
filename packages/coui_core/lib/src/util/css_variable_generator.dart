import 'package:coui_core/src/adapter/design_system_adapter_selector.dart';
import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/shape/radius_scale.dart' show CoreRadius;
import 'package:coui_core/src/theme/core_theme_data.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_family.dart';
import 'package:coui_core/src/typography/typography_scale.dart';

// Not a design token — CSS `rem` base (browser root font-size). Font-size
// tokens are authored in logical px and emitted as `rem` so they track the
// browser's accessibility text scaling.
const double _kRemDivisor = 16;

/// Generates CSS custom properties from [CoreThemeData].
///
/// Outputs `--coui-{token}: value;` pairs for web integration.
class CssVariableGenerator {
  const CssVariableGenerator._();

  /// Generate all CSS variables from a theme — [runtimeVars] and the
  /// [typographyVars] of its scale.
  static Map<String, String> generate(CoreThemeData theme) {
    return {...runtimeVars(theme), ...typographyVars(theme.typography)};
  }

  /// The CSS variables a theme writes while the page runs — colour and
  /// corners, without the type roles.
  ///
  /// The runtime path writes these inline on `<html>`, and an inline
  /// declaration beats every rule in the stylesheet. The stylesheet states
  /// the role variables at `:root` and restates them under rules of its own
  /// (a surface style raising a role's weight), so a role written here would
  /// hold the page to that one value over every such rule from that call on.
  /// A product sets its type where the stylesheet is generated
  /// (`ThemeConfig.typography` on Web).
  static Map<String, String> runtimeVars(CoreThemeData theme) {
    return {..._colorVars(theme), ..._radiusVars(theme)};
  }

  /// Per-role typography CSS variables from a [CoreTypography] scale.
  ///
  /// Emits `--coui-text-{role}-{size,line-height,weight,tracking}` for each
  /// of the roles in the scale, and `--coui-text-{role}-family` for a role
  /// that names its own font family (the default scale names one only on
  /// the code roles — mono). A role with a fixed line box
  /// (`CoreTextStyle.lineHeightPx`) writes it into the same line-height
  /// variable as a rem length, so the box tracks browser text scaling the
  /// way Flutter's `height = px / fontSize` tracks the text scaler. A role
  /// with a multiplier writes the multiplier itself, unitless, so an element
  /// that reads the variable straight into `line-height` passes a multiplier
  /// down to text of another size, as Flutter's `DefaultTextStyle` does; the
  /// role also writes `--coui-text-{role}-line-box`: `1` for a length and
  /// `0` for a multiplier. These public flags let existing CSS consumers
  /// scale a fixed box without scaling a multiplier twice. The role's own
  /// class rounds the box it draws (`ThemeConfig`): a component's text scale
  /// (`--coui-text-scale`) grows a fixed box and leaves a multiplier, which
  /// already follows the scaled size. The Web
  /// Tailwind `fontSize` config references these per-role variables (the
  /// family through a rule of its own — see `ThemeConfig`), so a
  /// project-supplied `theme.typography` (the role composition — which
  /// font-size / weight / line-height / letter-spacing makes `bodyMedium`)
  /// renders on Web identically to Flutter. The SSR default block
  /// (`ThemeConfig`) and [generate] emit through this single source; the
  /// runtime override path ([runtimeVars]) leaves the roles out.
  static Map<String, String> typographyVars(CoreTypography typography) {
    final vars = <String, String>{};
    for (final token in CoreTextStyles.values) {
      final style = token.read(typography);
      final role = token.name;
      final fontSize = style.fontSize;
      if (fontSize != null) {
        vars['--coui-text-$role-size'] = '${fontSize / _kRemDivisor}rem';
      }
      final lineHeightPx = style.lineHeightPx;
      final lineHeight = style.lineHeight;
      if (lineHeightPx != null) {
        vars['--coui-text-$role-line-height'] =
            '${lineHeightPx / _kRemDivisor}rem';
        vars['--coui-text-$role-line-box'] = '1';
      } else if (lineHeight != null) {
        vars['--coui-text-$role-line-height'] = '$lineHeight';
        vars['--coui-text-$role-line-box'] = '0';
      }
      final fontWeight = style.fontWeight;
      if (fontWeight != null) {
        vars['--coui-text-$role-weight'] = '$fontWeight';
      }
      final letterSpacing = style.letterSpacing;
      if (letterSpacing != null) {
        vars['--coui-text-$role-tracking'] = '${letterSpacing}em';
      }
      final fontFamily = style.fontFamily;
      if (fontFamily != null) {
        vars['--coui-text-$role-family'] = fontFamilyCss(fontFamily);
      }
    }
    return vars;
  }

  /// The CSS `line-height` of a line-height multiplier — the line box
  /// Flutter draws for it, a whole number of pixels.
  ///
  /// Flutter's text engine lays every line out at `ascent + descent`
  /// rounded to a whole logical pixel (`LineMetrics.height`), so a 14px
  /// label at 1.4 sits in a 20px line, not 19.6, and a 16px title at 1.4 in
  /// 22, not 22.4. A browser keeps the fractional product, so the same
  /// paragraph came out a fraction of a pixel per line shorter or taller
  /// on Web, and every box that holds text — an alert, a toast, a list row
  /// — a pixel off its Flutter twin. The value rounds the product the way
  /// the engine does (halfway rounds up). `1em` is the font size of the
  /// element the value lands on, so a size override there still scales the
  /// box, as Flutter's multiplier scales with the size it is applied to.
  ///
  /// The value is a length, not a number: it is fixed on the element that
  /// states it, and an element below it with another size would inherit
  /// that length rather than the multiplier. So the Web emits that state a
  /// line height also restate the multiplier for what is below them
  /// (`--coui-leading`), and text that changes only its size draws its own
  /// box from it ([inheritedLineHeightCss]).
  static String lineHeightCss(double lineHeight) =>
      roundToPixelCss('calc($lineHeight * 1em)');

  /// The custom property that carries the line-height multiplier down the
  /// tree on Web — Flutter's `DefaultTextStyle.height`, which text of
  /// another size inherits as a multiplier.
  static const String leadingVar = '--coui-leading';

  /// The CSS `line-height` of text that states its size and not its
  /// leading: the multiplier it inherits ([leadingVar]) at its own size,
  /// rounded as Flutter's engine rounds the line.
  ///
  /// With no multiplier above the element the value is invalid at
  /// computed-value time, so the element inherits its parent's line height
  /// as it would without the declaration.
  static String inheritedLineHeightCss() =>
      roundToPixelCss('calc(var($leadingVar) * 1em)');

  /// [length] rounded to the nearest whole CSS pixel, halfway up — the
  /// rounding Flutter's text engine applies to a line box.
  static String roundToPixelCss(String length) =>
      'round(nearest, $length, 1px)';

  /// The CSS `font-family` value for [family] — the one conversion every
  /// Web emit of a family goes through (role variables here, Style
  /// overrides in `toInlineCss` and the components that state a family).
  ///
  /// The text face and the mono face read their own stacks, so they keep
  /// their fallbacks. Any other face — a product's display face — falls back
  /// to the text face, which carries the Hangul most Latin faces lack. This
  /// is the same fallback the Flutter conversion gives that face.
  static String fontFamilyCss(String family) => switch (family) {
    CoreFontFamily.sans => 'var(--coui-font-family-sans)',
    CoreFontFamily.mono => 'var(--coui-font-family-mono)',
    _ =>
      '"${family.replaceAll('"', '')}", '
          'var(--coui-font-family-sans)',
  };

  /// Generate a CSS `:root { ... }` block string.
  static String toCssBlock(CoreThemeData theme) {
    final vars = generate(theme);
    final buffer = StringBuffer(':root {\n');
    for (final entry in vars.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value};');
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  static Map<String, String> _colorVars(CoreThemeData theme) {
    // Resolve the scheme through the active design-system adapter before
    // emitting CSS variables — the Web theme-resolution path for the
    // multi-DS axis. The CoUI baseline adapter is a pass-through, so a
    // `.coui` theme's variables are unchanged.
    final scheme = theme.designSystem.adapter.resolveColorScheme(
      theme.colorScheme,
      theme.brightness,
    );
    final colors = scheme.toMap();
    return {
      for (final entry in colors.entries) ...{
        // CoUI format: OKLch
        '--coui-${entry.key}': CoreColorConversion.toOKLch(
          CoreColor.fromHex(entry.value),
        ),
        // Also provide hex for fallback
        '--coui-${entry.key}-hex': entry.value,
      },
    };
  }

  /// One `--coui-radius-N` per `CoreRadius` step, multiplied by
  /// [CoreThemeData.radiusScaling].
  ///
  /// The steps are read off [CoreRadius.steps] rather than listed here. Web
  /// reaches every corner on the ladder through `var(--coui-radius-N)`, so a
  /// step this map skips keeps its unscaled `:root` value while the steps
  /// around it scale — the ladder stops being ordered, and a control size
  /// whose corner sits on a skipped step reads less round than the size
  /// below it. The two sentinels sit outside the ladder: `radius0` is square
  /// at any scale, and `radius9999` (fully round) is a statement rather
  /// than a magnitude, so it is never multiplied.
  static Map<String, String> _radiusVars(CoreThemeData theme) {
    final scale = theme.radiusScaling;
    String name(double step) => '--coui-radius-${step.toInt()}';
    return {
      name(CoreRadius.radius0): '${CoreRadius.radius0 * scale}px',
      for (final step in CoreRadius.steps) name(step): '${step * scale}px',
      name(CoreRadius.radius9999): '${CoreRadius.radius9999}px',
    };
  }
}
