import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'icon.stories.g.dart';

/// Selectable glyph options for [IconDemo] stories.
enum IconGlyph {
  /// Check glyph.
  check,

  /// Close (x) glyph.
  close,

  /// Heart glyph.
  heart,

  /// House glyph.
  house,

  /// Mail glyph.
  mail,

  /// Search glyph.
  search,

  /// Settings glyph.
  settings,

  /// Star glyph.
  star,
}

/// Interactive demo host for [Icon] stories.
///
/// Renders a single [Icon] with knob-controlled glyph, size, and
/// muted coloring.
class IconDemo extends StatelessWidget {
  /// Creates an [IconDemo].
  const IconDemo({
    super.key,
    this.glyph = IconGlyph.star,
    this.size = CoreSpace.space20,
    this.muted = false,
  });

  /// Glyph to render.
  final IconGlyph glyph;

  /// Icon size in logical pixels.
  final double size;

  /// Whether the icon uses the muted on-surface-variant color.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final icon = switch (glyph) {
      .star => LucideIcons.star,
      .house => LucideIcons.house,
      .search => LucideIcons.search,
      .settings => LucideIcons.settings,
      .heart => LucideIcons.heart,
      .mail => LucideIcons.mail,
      .check => LucideIcons.check,
      .close => LucideIcons.x,
    };

    return Icon(
      icon,
      iconStyle: CoreIconStyle(
        size: size,
        color: muted
            ? const CoreColor.token(CoreColors.onSurfaceVariant)
            : null,
      ),
    );
  }
}

/// Navigation metadata for the Icon component.
const kComponentMeta = ComponentMeta(name: 'Icon', path: 'icon');

/// Story metadata for [IconDemo].
const kMeta = Meta(IconDemo.new);

/// Star icon at the medium (20) size with editable knobs.
final $Default = _Story();

/// Extra-small (12) icon size.
final $Small = _Story(
  args: _Args(size: DoubleArg(CoreSpace.space12)),
);

/// Extra-large (32) icon size.
final $Large = _Story(
  args: _Args(size: DoubleArg(CoreSpace.space32)),
);

/// Muted icon using the on-surface-variant color token.
final $Muted = _Story(
  args: _Args(muted: BoolArg(true)),
);

/// House glyph from the gallery set.
final $House = _Story(
  args: _Args(glyph: EnumArg(IconGlyph.house, values: IconGlyph.values)),
);

/// Search glyph from the gallery set.
final $Search = _Story(
  args: _Args(glyph: EnumArg(IconGlyph.search, values: IconGlyph.values)),
);

/// Heart glyph from the gallery set.
final $Heart = _Story(
  args: _Args(glyph: EnumArg(IconGlyph.heart, values: IconGlyph.values)),
);
