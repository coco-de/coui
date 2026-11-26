import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'scaffold.stories.g.dart';

// Scaffold widgetbook constants.
const _kContainerWidth = 360.0;
const _kContainerHeight = 320.0;
const _kLoadingProgressInitial = 65.0;
const _kPercentMax = 100.0;

/// Knob input for [Scaffold] stories.
class ScaffoldInput {
  /// Creates a [ScaffoldInput].
  const ScaffoldInput({
    this.title = 'Dashboard',
    this.body = 'Main content area',
    this.showFooter = true,
    this.showFab = false,
    this.fabLocation = CoreScaffoldFabLocation.defaultLocation,
    this.loading = false,
    this.loadingIndeterminate = false,
    this.loadingProgress = _kLoadingProgressInitial,
  });

  /// App bar title text.
  final String title;

  /// Centered body text.
  final String body;

  /// Whether a footer bar is shown.
  final bool showFooter;

  /// Whether a floating action button is shown.
  final bool showFab;

  /// Location of the floating action button.
  final CoreScaffoldFabLocation fabLocation;

  /// Whether the loading progress bar is shown.
  final bool loading;

  /// Whether the loading progress bar is indeterminate.
  final bool loadingIndeterminate;

  /// Loading progress value (0-100) when determinate.
  final double loadingProgress;
}

/// Navigation metadata for the Scaffold component.
const kComponentMeta = ComponentMeta(name: 'Scaffold', path: 'layout');

/// Story metadata for [Scaffold].
const kMeta = Meta(Scaffold.new, argsType: ScaffoldInput.new);

void _handleNoop() {}

/// Default builder mapping [ScaffoldInput] args to a [Scaffold].
final ScaffoldDefaults defaults = _Defaults(
  setup: (context, child, args) => material.SizedBox(
    width: _kContainerWidth,
    height: _kContainerHeight,
    child: child,
  ),
  builder: (context, args) => Scaffold(
    headers: [
      AppBar(
        title: Text(args.title).titleMedium,
        trailing: const [Icon(LucideIcons.settings)],
      ),
    ],
    footers: args.showFooter
        ? [AppBar(title: const Text('Ready').bodySmall.onSurfaceVariant)]
        : const [],
    floatingActionButton: args.showFab
        ? const Fab(
            onPressed: _handleNoop,
            trigger: Icon(LucideIcons.plus),
            tooltip: 'Add note',
          )
        : null,
    floatingActionButtonLocation: args.fabLocation,
    loadingProgress: args.loading && !args.loadingIndeterminate
        ? args.loadingProgress / _kPercentMax
        : null,
    loadingProgressIndeterminate: args.loading && args.loadingIndeterminate,
    child: material.Center(child: Text(args.body)),
  ),
);

/// Scaffold with header and footer bars.
final $Default = _Story();

/// Scaffold with a floating action button and location knob.
final $FloatingActionButton = _Story(
  name: 'Floating Action Button',
  args: _Args(
    title: StringArg('Notes'),
    body: StringArg('Tap the FAB to add a note'),
    showFooter: BoolArg(false),
    showFab: BoolArg(true),
  ),
);

/// Scaffold with a loading progress bar under the header.
final $Loading = _Story(
  args: _Args(
    title: StringArg('Uploading'),
    body: StringArg('Uploading files...'),
    showFooter: BoolArg(false),
    loading: BoolArg(true),
  ),
);
