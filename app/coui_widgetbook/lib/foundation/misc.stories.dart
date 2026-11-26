import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'misc.stories.g.dart';

const _kSwatchSize = 48.0;
const _kUnnamedSize = '';

/// Token sections available in the misc foundation showcase.
enum MiscSection {
  /// Icon size scale from the theme icon theme.
  iconSizes,

  /// Border radius token scale.
  radius,
}

/// Showcase page for misc foundation tokens (radius, icon sizes).
class MiscTokensDemo extends StatelessWidget {
  /// Creates a [MiscTokensDemo].
  const MiscTokensDemo({super.key, this.section = MiscSection.radius});

  /// Which token section to display.
  final MiscSection section;

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      .radius => const _RadiusList(),
      .iconSizes => const _IconSizesList(),
    };
  }
}

/// Navigation metadata for the Misc foundation page.
const kComponentMeta = ComponentMeta(name: 'Misc', path: 'foundation');

/// Story metadata for [MiscTokensDemo].
const kMeta = Meta(MiscTokensDemo.new);

/// Border radius token scale.
final $Radius = _Story();

/// Icon size scale.
final $IconSizes = _Story(
  name: 'Icon Sizes',
  args: _Args(
    section: EnumArg(MiscSection.iconSizes, values: MiscSection.values),
  ),
);

class _RadiusList extends StatelessWidget {
  const _RadiusList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Type argument is required so the `.zero` / `.all(.circular(...))` dot
    // shorthands below resolve their context type — not inferrable.
    const radii = <(String, BorderRadius)>[
      ('radius0 (none)', .zero),
      ('radius4', .all(.circular(CoreRadius.radius4))),
      ('radius8', .all(.circular(CoreRadius.radius8))),
      ('radius16', .all(.circular(CoreRadius.radius16))),
      ('radius24', .all(.circular(CoreRadius.radius24))),
      ('radius9999 (round)', .all(.circular(CoreRadius.radius9999))),
    ];

    return ListView.builder(
      itemBuilder: (context, index) {
        final (name, radius) = radii[index];

        return material.ListTile(
          leading: SizedBox.square(
            dimension: _kSwatchSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.toValue(),
                borderRadius: radius,
              ),
            ),
          ),
          title: Text(name),
          subtitle: Text(radius.toString()),
        );
      },
      itemCount: radii.length,
    );
  }
}

class _IconSizesList extends StatelessWidget {
  const _IconSizesList();

  @override
  Widget build(BuildContext context) {
    final iconTheme = Theme.of(context).iconTheme;
    final sizes = {
      'large': iconTheme.large.size,
      'medium': iconTheme.medium.size,
      'small': iconTheme.small.size,
      'x2Large': iconTheme.x2Large.size,
      'x2Small': iconTheme.x2Small.size,
      'x3Large': iconTheme.x3Large.size,
      'x3Small': iconTheme.x3Small.size,
      'x4Large': iconTheme.x4Large.size,
      'x4Small': iconTheme.x4Small.size,
      'xLarge': iconTheme.xLarge.size,
      'xSmall': iconTheme.xSmall.size,
    };

    return ListView.builder(
      itemBuilder: (context, index) {
        final name = sizes.keys.elementAtOrNull(index) ?? _kUnnamedSize;
        final iconSize = sizes.values.elementAtOrNull(index);

        return material.ListTile(
          leading: Icon(
            LucideIcons.star,
            iconStyle: CoreIconStyle(size: iconSize),
          ),
          title: Text(name),
          subtitle: Text('${iconSize ?? 0}px'),
        );
      },
      itemCount: sizes.length,
    );
  }
}
