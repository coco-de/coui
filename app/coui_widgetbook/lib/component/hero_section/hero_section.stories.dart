import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'hero_section.stories.g.dart';

const _kHeroMinHeight = 280.0;
const _kHeroImageMinHeight = 320.0;
const _kHeroImageBase =
    'https://images.unsplash.com/photo-1451187580459-43490279c0fa';
const _kHeroImageUrl = '$_kHeroImageBase?w=1200&q=80';
const _kHeroOverlayColor = CoreColor(0x66000000);

void _handleNoop() {}

/// Knob input for [Hero] stories.
class HeroSectionInput {
  /// Creates a [HeroSectionInput].
  const HeroSectionInput({
    this.title = 'Welcome to CoUI',
    this.subtitle = 'Cross-platform design system for Flutter and Jaspr.',
    this.showBackgroundImage = false,
    this.showOverlay = true,
  });

  /// Hero title text.
  final String title;

  /// Hero subtitle text (hidden when a background image is shown).
  final String subtitle;

  /// Whether a background image is rendered behind the content.
  final bool showBackgroundImage;

  /// Whether a scrim overlay is drawn over the background image.
  final bool showOverlay;
}

/// Navigation metadata for the Hero block.
const kComponentMeta = ComponentMeta(name: 'Hero', path: 'layout');

/// Story metadata for [Hero].
const kMeta = Meta(Hero.new, argsType: HeroSectionInput.new);

/// Default builder mapping [HeroSectionInput] args to a [Hero].
final HeroSectionDefaults defaults = _Defaults(
  builder: (context, args) {
    final title = args.showBackgroundImage
        ? Text(args.title).titleLarge.inverseOnSurface
        : Text(args.title).titleLarge.onSurface;
    final child = args.showBackgroundImage
        ? title
        : Column(
            mainAxisSize: .min,
            children: [
              title,
              const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
              Text(args.subtitle).bodyMedium.onSurfaceVariant,
              const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space20)),
              const Button(
                onPressed: _handleNoop,
                child: Text('Get Started'),
              ),
            ],
          );

    return Hero(
      imageUrl: args.showBackgroundImage ? _kHeroImageUrl : null,
      semanticLabel: args.showBackgroundImage
          ? 'Mountain landscape hero banner'
          : null,
      heroStyle: CoreHeroStyle(
        overlayColor: args.showBackgroundImage && args.showOverlay
            ? _kHeroOverlayColor
            : null,
        minHeight: args.showBackgroundImage
            ? _kHeroImageMinHeight
            : _kHeroMinHeight,
      ),
      child: child,
    );
  },
);

/// Text hero with title, subtitle, and call-to-action button.
final $Default = _Story();

/// Hero with a background image and scrim overlay.
final $WithBackgroundImage = _Story(
  name: 'With Background Image',
  args: _Args(
    title: StringArg('Explore the Mountains'),
    showBackgroundImage: BoolArg(true),
  ),
);
