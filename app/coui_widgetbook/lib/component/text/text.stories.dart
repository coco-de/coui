import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'text.stories.g.dart';

const _kSampleText = 'The quick brown fox jumps over the lazy dog.';

/// Typography role applied via the [Text] chain API.
enum TextRoleOption {
  /// `bodyLarge` role.
  bodyLarge,

  /// `bodyMedium` role.
  bodyMedium,

  /// `bodySmall` role.
  bodySmall,

  /// `codeSm` role — monospace on the code roles' fixed 21px line.
  codeSm,

  /// `displaySmall` role.
  displaySmall,

  /// `headlineLarge` role.
  headlineLarge,

  /// `headlineSmall` role.
  headlineSmall,

  /// `labelMedium` role.
  labelMedium,

  /// `titleLarge` role.
  titleLarge,
}

/// Font weight applied via the [Text] chain API.
enum TextWeightOption {
  /// Black weight.
  black,

  /// Bold weight.
  bold,

  /// Light weight.
  light,

  /// Medium weight.
  medium,

  /// Regular weight.
  regular,

  /// Semi-bold weight.
  semiBold,

  /// Thin weight.
  thin,
}

/// Semantic color applied via the [Text] chain API.
enum TextColorOption {
  /// Error color.
  error,

  /// Foreground color.
  foreground,

  /// Info color.
  info,

  /// On-surface color.
  onSurface,

  /// Primary color.
  primary,

  /// Secondary color.
  secondary,

  /// Success color.
  success,

  /// Tertiary color.
  tertiary,

  /// Warning color.
  warning,
}

/// Demo host that exercises the [Text] chain API (role, weight,
/// color and style modifiers) on a single sample string.
class TextStyleDemo extends StatelessWidget {
  /// Creates a [TextStyleDemo].
  const TextStyleDemo({
    super.key,
    this.text = _kSampleText,
    this.role = TextRoleOption.bodyMedium,
    this.weight = TextWeightOption.regular,
    this.color = TextColorOption.onSurface,
    this.italic = false,
    this.underline = false,
    this.mono = false,
  });

  /// Sample text to render.
  final String text;

  /// Typography role.
  final TextRoleOption role;

  /// Font weight.
  final TextWeightOption weight;

  /// Semantic color.
  final TextColorOption color;

  /// Whether the italic modifier is applied.
  final bool italic;

  /// Whether the underline modifier is applied.
  final bool underline;

  /// Whether the mono font family modifier is applied.
  final bool mono;

  Widget _applyRole(Widget base) => switch (role) {
    .displaySmall => base.displaySmall(),
    .headlineLarge => base.headlineLarge(),
    .headlineSmall => base.headlineSmall(),
    .titleLarge => base.titleLarge(),
    .bodyLarge => base.bodyLarge(),
    .bodyMedium => base.bodyMedium(),
    .bodySmall => base.bodySmall(),
    .labelMedium => base.labelMedium(),
    .codeSm => base.codeSm(),
  };

  Widget _applyWeight(Widget base) => switch (weight) {
    .thin => base.thin(),
    .light => base.light(),
    .regular => base.regular(),
    .medium => base.medium(),
    .semiBold => base.semiBold(),
    .bold => base.bold(),
    .black => base.black(),
  };

  Widget _applyColor(Widget base) => switch (color) {
    .foreground => base.foreground(),
    .onSurface => base.onSurface(),
    .primary => base.onPrimaryContainer(),
    .secondary => base.onSecondaryContainer(),
    .tertiary => base.onTertiaryContainer(),
    .success => base.onSuccessContainer(),
    .warning => base.onWarningContainer(),
    .error => base.onErrorContainer(),
    .info => base.onInfoContainer(),
  };

  @override
  Widget build(BuildContext context) {
    final styled = _applyColor(_applyWeight(_applyRole(Text(text))));
    final withItalic = italic ? styled.italic() : styled;
    final withUnderline = underline ? withItalic.underline() : withItalic;

    return mono ? withUnderline.mono() : withUnderline;
  }
}

/// Navigation metadata for the Text component.
const kComponentMeta = ComponentMeta(name: 'Text', path: 'text');

/// Story metadata for [TextStyleDemo].
const kMeta = Meta(TextStyleDemo.new);

/// Body text with role / weight / color / style knobs.
final $Default = _Story();

/// Headline typography role.
final $Headline = _Story(
  args: _Args(
    role: EnumArg(TextRoleOption.headlineLarge, values: TextRoleOption.values),
  ),
);

/// Bold font weight.
final $Bold = _Story(
  args: _Args(
    weight: EnumArg(TextWeightOption.bold, values: TextWeightOption.values),
  ),
);

/// Primary semantic color.
final $Primary = _Story(
  args: _Args(
    color: EnumArg(TextColorOption.primary, values: TextColorOption.values),
  ),
);

/// Italic style modifier.
final $Italic = _Story(args: _Args(italic: BoolArg(true)));

/// Underline style modifier.
final $Underline = _Story(args: _Args(underline: BoolArg(true)));

/// Mono font family modifier.
final $Mono = _Story(args: _Args(mono: BoolArg(true)));
