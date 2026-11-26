import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'bottom_sheet.stories.g.dart';

// BottomSheet widgetbook constants.
//
// The sheet fills the width it is given, so the harness hands it a phone
// screen's width. The harness has no device frame, so its safe area is zero.
const double _kScreenWidth = CoreLayout.layout400;
const int _kOptionCount = 3;

void _handleNoop() {}

/// Knob input for [BottomSheet] stories.
class BottomSheetInput {
  /// Creates a [BottomSheetInput].
  const BottomSheetInput({
    this.title = 'Sort by',
    this.description = 'Choose how the list is ordered.',
    this.showHandle = CoreBottomSheetContract.defaultShowHandle,
    this.showCloseButton = CoreBottomSheetContract.defaultShowCloseButton,
    this.showDivider = CoreBottomSheetContract.defaultShowDivider,
    this.showContent = true,
    this.showFooter = true,
  });

  /// The sheet's name.
  final String title;

  /// Line under the title (hidden when empty).
  final String description;

  /// Whether the grab handle is drawn.
  final bool showHandle;

  /// Whether the close button is drawn.
  final bool showCloseButton;

  /// Whether the hairline between the header and the content is drawn.
  final bool showDivider;

  /// Whether the content slot is filled.
  final bool showContent;

  /// Whether the footer slot is filled.
  final bool showFooter;
}

/// Builds a [BottomSheet] from [args].
BottomSheet _sheet(_Args args) => BottomSheet(
  title: Text(args.title),
  description: args.description.isEmpty ? null : Text(args.description),
  showHandle: args.showHandle,
  showCloseButton: args.showCloseButton,
  showDivider: args.showDivider,
  onClose: _handleNoop,
  content: args.showContent
      ? OptionList(
          children: [
            for (var index = 0; index < _kOptionCount; index++)
              OptionItem(
                label: Text('Option ${index + 1}'),
                selected: index == 0,
                onPressed: _handleNoop,
              ),
          ],
        )
      : null,
  footer: args.showFooter
      ? const BottomActionBar(
          primaryAction: Button(
            size: .xl,
            onPressed: _handleNoop,
            child: Text('Apply'),
          ),
        )
      : null,
);

/// Navigation metadata for the BottomSheet component.
const kComponentMeta = ComponentMeta(name: 'BottomSheet', path: 'layout');

/// Story metadata for [BottomSheet].
const kMeta = Meta(BottomSheet.new, argsType: BottomSheetInput.new);

/// Default builder mapping [BottomSheetInput] args to a [BottomSheet].
final BottomSheetDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kScreenWidth, child: child),
  builder: (context, args) => _sheet(args),
);

/// Handle, title, description, three options and the bottom bar.
final $Default = _Story();

/// The close button and the divider on, the handle off.
final $Close = _Story(
  name: 'Close',
  args: _Args(
    showHandle: BoolArg(false),
    showCloseButton: BoolArg(true),
    showDivider: BoolArg(true),
  ),
);
