import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'refresh_trigger.stories.g.dart';

// RefreshTrigger widgetbook constants.
const _kExampleHeight = 300.0;
const _kItemCount = 20;
const _kRefreshDelay = Duration(seconds: 1);

/// Interactive demo host for [RefreshTrigger] stories.
///
/// Wraps a scrollable list and counts completed pull-to-refresh gestures.
class RefreshTriggerDemo extends material.StatefulWidget {
  /// Creates a [RefreshTriggerDemo].
  const RefreshTriggerDemo({
    super.key,
    this.direction = CoreRefreshDirection.vertical,
    this.reverse = false,
  });

  /// Pull direction that triggers the refresh.
  final CoreRefreshDirection direction;

  /// Whether the pull direction is reversed.
  final bool reverse;

  @override
  material.State<RefreshTriggerDemo> createState() =>
      _RefreshTriggerDemoState();
}

class _RefreshTriggerDemoState extends material.State<RefreshTriggerDemo> {
  int _refreshCount = 0;

  Future<void> handleRefresh() async {
    // Simulate network delay for the refresh operation.
    await Future<void>.delayed(_kRefreshDelay);
    if (!mounted) return;
    setState(() => _refreshCount += 1);
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.SizedBox(
      height: _kExampleHeight,
      child: RefreshTrigger(
        direction: widget.direction,
        reverse: widget.reverse,
        onRefresh: handleRefresh,
        child: material.ListView.builder(
          scrollDirection: widget.direction == CoreRefreshDirection.horizontal
              ? Axis.horizontal
              : Axis.vertical,
          reverse: widget.reverse,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) => Padding(
            padding: const .all(CoreSpace.space16),
            child: Text(
              index == 0 ? 'Refreshed $_refreshCount times' : 'Item $index',
            ),
          ),
          itemCount: _kItemCount,
        ),
      ),
    );
  }
}

/// Navigation metadata for the RefreshTrigger component.
const kComponentMeta = ComponentMeta(name: 'RefreshTrigger', path: 'overlay');

/// Story metadata for [RefreshTriggerDemo].
const kMeta = Meta(RefreshTriggerDemo.new);

/// Pull-to-refresh list with direction and reverse knobs.
final $Default = _Story();
