import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'fab.stories.g.dart';

// FAB widgetbook constants.
const _kBodyText = 'FAB Demo Content';
const _kActionEdit = 'Edit';
const _kActionShare = 'Share';
const _kActionDelete = 'Delete';
const _kActionCamera = 'Camera';
const _kActionGallery = 'Gallery';
const _kActionVideo = 'Video';
const _kActionAudio = 'Audio';

void _handleNoop() {}

/// Expandable action presets for [FabDemo].
enum FabDemoActions {
  /// Edit / share / delete actions.
  edit,

  /// Camera / gallery / video / audio actions.
  media,

  /// Plain FAB without expandable actions.
  none,
}

/// Interactive demo host placing a [Fab] in a `Scaffold`'s
/// `floatingActionButton` slot — the FAB no longer owns positioning.
class FabDemo extends StatelessWidget {
  /// Creates a [FabDemo].
  const FabDemo({
    super.key,
    this.size = CoreFabSize.regular,
    this.expandDirection = CoreFabExpandDirection.up,
    this.actions = FabDemoActions.none,
    this.enabled = true,
    this.showLabels = true,
    this.tooltip = 'Add item',
  });

  /// FAB size preset.
  final CoreFabSize size;

  /// Direction the actions expand toward.
  final CoreFabExpandDirection expandDirection;

  /// Expandable action preset.
  final FabDemoActions actions;

  /// Whether the FAB responds to presses.
  final bool enabled;

  /// Whether the edit actions show text labels.
  final bool showLabels;

  /// Tooltip shown on the trigger.
  final String tooltip;

  IconName get _triggerIcon => switch (actions) {
    .none => LucideIcons.plus,
    .edit => LucideIcons.menu,
    .media => LucideIcons.layoutGrid,
  };

  List<FabAction>? get _fabActions => switch (actions) {
    .none => null,
    .edit => [
      FabAction(
        onPressed: _handleNoop,
        icon: const Icon(LucideIcons.pencil),
        label: showLabels ? const Text(_kActionEdit) : null,
        tooltip: _kActionEdit,
      ),
      FabAction(
        onPressed: _handleNoop,
        icon: const Icon(LucideIcons.share),
        label: showLabels ? const Text(_kActionShare) : null,
        tooltip: _kActionShare,
      ),
      FabAction(
        onPressed: _handleNoop,
        icon: const Icon(LucideIcons.trash2),
        label: showLabels ? const Text(_kActionDelete) : null,
        tooltip: _kActionDelete,
      ),
    ],
    .media => [
      const FabAction(
        onPressed: _handleNoop,
        icon: Icon(LucideIcons.camera),
        tooltip: _kActionCamera,
      ),
      const FabAction(
        onPressed: _handleNoop,
        icon: Icon(LucideIcons.image),
        tooltip: _kActionGallery,
      ),
      const FabAction(
        onPressed: _handleNoop,
        icon: Icon(LucideIcons.video),
        tooltip: _kActionVideo,
      ),
      const FabAction(
        onPressed: _handleNoop,
        icon: Icon(LucideIcons.mic),
        tooltip: _kActionAudio,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      body: const Center(
        child: Text(_kBodyText),
      ),
      floatingActionButton: Fab(
        onPressed: enabled ? _handleNoop : null,
        trigger: Icon(_triggerIcon),
        actions: _fabActions,
        size: size,
        expandDirection: expandDirection,
        tooltip: tooltip,
      ),
    );
  }
}

/// Navigation metadata for the Fab component.
const kComponentMeta = ComponentMeta(name: 'Fab', path: 'control');

/// Story metadata for [FabDemo].
const kMeta = Meta(FabDemo.new);

/// Plain regular FAB with editable knobs.
final $Default = _Story();

/// FAB expanding edit / share / delete actions.
final $WithActions = _Story(
  name: 'With Actions',
  args: _Args(
    actions: EnumArg(FabDemoActions.edit, values: FabDemoActions.values),
    tooltip: StringArg('Open menu'),
  ),
);

/// Mini-sized FAB.
final $Mini = _Story(
  args: _Args(
    size: EnumArg(CoreFabSize.mini, values: CoreFabSize.values),
    tooltip: StringArg('Quick add'),
  ),
);

/// Media actions expanding in a quarter-circle fan pattern.
final $FanPattern = _Story(
  name: 'Fan Pattern',
  args: _Args(
    expandDirection: EnumArg(
      CoreFabExpandDirection.fan,
      values: CoreFabExpandDirection.values,
    ),
    actions: EnumArg(FabDemoActions.media, values: FabDemoActions.values),
    tooltip: StringArg('Media options'),
  ),
);
