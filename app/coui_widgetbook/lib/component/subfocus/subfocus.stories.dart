import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'subfocus.stories.g.dart';

/// Demo host for [SubfocusScope] stories.
class SubfocusScopeDemo extends StatelessWidget {
  /// Creates a [SubfocusScopeDemo].
  const SubfocusScopeDemo({
    super.key,
    this.autofocus = true,
    this.orientation = CoreSubfocusOrientation.vertical,
    this.middleItemEnabled = true,
  });

  /// Whether the scope grabs focus on mount.
  final bool autofocus;

  /// Arrow-key navigation orientation.
  final CoreSubfocusOrientation orientation;

  /// Whether the middle item participates in focus traversal.
  final bool middleItemEnabled;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      Subfocus(
        focusId: 'a',
        child: Card(
          child: const Text('Item A (navigate with arrow keys)').bodyMedium,
        ),
      ),
      Subfocus(
        focusId: 'b',
        enabled: middleItemEnabled,
        child: Card(
          child: Text(
            middleItemEnabled ? 'Item B' : 'Item B (disabled, skipped)',
          ).bodyMedium,
        ),
      ),
      Subfocus(
        focusId: 'c',
        child: Card(child: const Text('Item C').bodyMedium),
      ),
    ];

    final isHorizontal = orientation == .horizontal;
    final group = isHorizontal
        ? Row(
            mainAxisSize: .min,
            spacing: CoreSpace.space8,
            children: items,
          )
        : Column(
            mainAxisSize: .min,
            spacing: CoreSpace.space8,
            children: items,
          );

    return SubfocusScope(
      autofocus: autofocus,
      orientation: orientation,
      child: group,
    );
  }
}

/// Navigation metadata for the Subfocus component.
const kComponentMeta = ComponentMeta(name: 'Subfocus', path: 'infra');

/// Story metadata for [SubfocusScopeDemo].
const kMeta = Meta(SubfocusScopeDemo.new);

/// Focusable item group with editable knobs.
final $Default = _Story();

/// Middle item disabled and skipped during traversal.
final $DisabledItem = _Story(
  name: 'Disabled Item',
  args: _Args(middleItemEnabled: BoolArg(false)),
);
