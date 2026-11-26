import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_widgetbook/preview/surface_preview.dart';
import 'package:widgetbook/widgetbook.dart';

part 'app_bar.stories.g.dart';

void _handleNoop() {}

/// Ghost icon button used in the leading / trailing clusters.
Widget _barAction(IconName icon) => Button(
  onPressed: _handleNoop,
  variant: .ghost,
  size: .sm,
  shape: .square,
  child: Icon(icon),
);

/// Knob input for [AppBar] stories.
class AppBarInput {
  /// Creates an [AppBarInput].
  const AppBarInput({
    this.variant = CoreAppBarVariant.defaultVariant,
    this.title = 'Dashboard',
    this.header = '',
    this.subtitle = '',
    this.showLeading = true,
    this.showTrailing = true,
    this.groupedToolbar = false,
    this.centerTitle = CoreAppBarContract.defaultCenterTitle,
    this.trailingExpanded = CoreAppBarContract.defaultTrailingExpanded,
    this.showDivider = CoreAppBarContract.defaultShowDivider,
    this.elevated = CoreAppBarContract.defaultElevated,
  });

  /// Bar shape — standard (64px) / compact (56px) / medium (112px) /
  /// dense (48px desktop window bar) / prominent (56px one-line heading).
  final CoreAppBarVariant variant;

  /// Title slot text — the title slot is dropped when empty.
  final String title;

  /// Header slot text stacked above the title — hidden when empty. The
  /// centre column is bounded by the bar height, so pair this with a
  /// short title and an empty subtitle.
  final String header;

  /// Subtitle slot text stacked below the title — hidden when empty.
  final String subtitle;

  /// Whether the leading navigation button is shown.
  final bool showLeading;

  /// Whether the trailing action cluster is shown.
  final bool showTrailing;

  /// Show action groups and a menu instead of a single trailing cluster.
  final bool groupedToolbar;

  /// Whether the title is centred instead of start-aligned.
  final bool centerTitle;

  /// Whether the trailing cluster takes the remaining width.
  final bool trailingExpanded;

  /// Whether the bottom hairline divider is drawn.
  final bool showDivider;

  /// Whether the elevated drop shadow is drawn.
  final bool elevated;
}

/// Navigation metadata for the AppBar component.
const kComponentMeta = ComponentMeta(name: 'AppBar', path: 'navigation');

/// Story metadata for [AppBar].
const kMeta = Meta(AppBar.new, argsType: AppBarInput.new);

/// Default builder mapping [AppBarInput] args to an [AppBar].
final AppBarDefaults defaults = _Defaults(
  setup: (context, child, args) => SurfaceChromePreview(header: child),
  builder: (context, args) => AppBar(
    variant: args.variant,
    scrollController: PrimaryScrollController.maybeOf(context),
    // The bar owns the title typography per variant, so the slot stays a
    // plain Text — chaining a role here would mask the variant axis.
    title: args.title.isEmpty ? null : Text(args.title),
    header: args.header.isEmpty
        ? null
        : Text(args.header).labelSmall.onSurfaceVariant,
    subtitle: args.subtitle.isEmpty
        ? null
        : Text(args.subtitle).bodySmall.onSurfaceVariant,
    leading: args.showLeading ? [_barAction(LucideIcons.menu)] : const [],
    trailing: args.showTrailing
        ? args.groupedToolbar
              ? [
                  ToolbarGroup(
                    ariaLabel: 'Search actions',
                    children: [_barAction(LucideIcons.search)],
                  ),
                  ToolbarGroup(
                    ariaLabel: 'Collection actions',
                    children: [
                      _barAction(LucideIcons.heart),
                      DropdownMenu(
                        trigger: _barAction(LucideIcons.ellipsis),
                        items: const [
                          CoreMenuItem.action(
                            'Save collection',
                            leading: Icon(LucideIcons.heart),
                            onPressed: _handleNoop,
                          ),
                          CoreMenuItem.divider(),
                          CoreMenuItem.action(
                            'Share collection',
                            leading: Icon(LucideIcons.share),
                            onPressed: _handleNoop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ]
              : [_barAction(LucideIcons.search), _barAction(LucideIcons.bell)]
        : const [],
    trailingExpanded: args.trailingExpanded,
    centerTitle: args.centerTitle,
    showDivider: args.showDivider,
    elevated: args.elevated,
  ),
);

/// Standard 64px bar — leading nav button, start-aligned title and a
/// trailing action cluster.
final $Default = _Story();

/// Compact 56px single-row bar.
final $Compact = _Story(
  args: _Args(
    variant: EnumArg(
      CoreAppBarVariant.compact,
      values: CoreAppBarVariant.values,
    ),
  ),
);

/// 112px bar — a 48px leading / action row above a bottom-aligned large
/// title.
final $Medium = _Story(
  args: _Args(
    variant: EnumArg(
      CoreAppBarVariant.medium,
      values: CoreAppBarVariant.values,
    ),
    title: StringArg('Inbox'),
  ),
);

/// 48px desktop window / tool bar — one row of 32px controls on the
/// chrome-tier face, clusters 14 apart and a semibold label title.
final $Dense = _Story(
  args: _Args(
    variant: EnumArg(
      CoreAppBarVariant.dense,
      values: CoreAppBarVariant.values,
    ),
    title: StringArg('Workspace'),
  ),
);

/// 56px one-line bar with a large start-aligned heading — the first screen
/// of a tab, so no back button. The trailing pair here is the shared icon
/// actions; the words-only action this bar is usually paired with is in the
/// docs example.
final $Prominent = _Story(
  args: _Args(
    variant: EnumArg(
      CoreAppBarVariant.prominent,
      values: CoreAppBarVariant.values,
    ),
    title: StringArg('지도'),
    showLeading: BoolArg(false),
  ),
);

/// Title centred between the leading and trailing clusters.
final $CenteredTitle = _Story(
  name: 'Centered Title',
  args: _Args(
    title: StringArg('Settings'),
    centerTitle: BoolArg(true),
  ),
);

/// Title with a secondary line stacked underneath it.
final $WithSubtitle = _Story(
  name: 'With Subtitle',
  args: _Args(
    title: StringArg('Design System'),
    subtitle: StringArg('12 members'),
  ),
);

/// Title slot turned off — the leading and trailing clusters span the
/// bar on their own.
final $TitleOff = _Story(
  name: 'Title Off',
  args: _Args(
    title: StringArg(''),
    trailingExpanded: BoolArg(true),
  ),
);

/// Drop shadow instead of the bottom hairline.
final $Elevated = _Story(
  args: _Args(
    showDivider: BoolArg(false),
    elevated: BoolArg(true),
  ),
);

/// Change Surface material to compare action groups and their popup menu.
final $MenusAndToolbars = _Story(
  name: 'Menus and Toolbars',
  args: _Args(groupedToolbar: BoolArg(true)),
);
