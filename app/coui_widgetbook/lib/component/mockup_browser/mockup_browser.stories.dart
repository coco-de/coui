import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'mockup_browser.stories.g.dart';

/// Style override applied when the styled knob is enabled.
const _kCustomStyle = CoreMockupBrowserStyle(
  borderColor: CoreColor.token(CoreColors.primary),
  borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
  addressBarBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
  addressBarBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
  controlCloseColor: CoreColor.token(CoreColors.error),
  controlMinimizeColor: CoreColor.token(CoreColors.warning),
  controlMaximizeColor: CoreColor.token(CoreColors.success),
);

/// Knob input for [MockupBrowser] stories.
class MockupBrowserInput {
  /// Creates a [MockupBrowserInput].
  const MockupBrowserInput({
    this.addressBar = 'example.com',
    this.showAddressBar = true,
    this.showControls = true,
    this.pageContent = 'Content',
    this.styled = false,
  });

  /// Address bar URL text.
  final String addressBar;

  /// Whether the browser affordances are drawn. Off passes
  /// `addressBar: null` — the desktop app-window composition.
  final bool showAddressBar;

  /// Whether the three window controls are drawn.
  final bool showControls;

  /// Page body content text.
  final String pageContent;

  /// Whether the custom style override is applied.
  final bool styled;
}

/// Navigation metadata for the MockupBrowser component.
const kComponentMeta = ComponentMeta(name: 'MockupBrowser', path: 'display');

/// Story metadata for [MockupBrowser].
const kMeta = Meta(MockupBrowser.new, argsType: MockupBrowserInput.new);

/// Default builder mapping [MockupBrowserInput] args to a [MockupBrowser].
final MockupBrowserDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      SizedBox(width: 380, height: 200, child: child),
  builder: (context, args) => MockupBrowser(
    showControls: args.showControls,
    addressBar: args.showAddressBar ? args.addressBar : null,
    mockupBrowserStyle: args.styled ? _kCustomStyle : null,
    child: Center(child: Text(args.pageContent)),
  ),
);

/// Browser mockup with editable address bar and content knobs.
final $Default = _Story();

/// Desktop app window — `MockupBrowser(addressBar: null)`, the composition
/// the retired `MockupWindow` used to draw.
final $AppWindow = _Story(
  name: 'App Window',
  args: _Args(
    showAddressBar: BoolArg(false),
    pageContent: StringArg('App content'),
  ),
);

/// Browser mockup with a custom style override.
final $CustomStyle = _Story(
  name: 'Custom Style',
  args: _Args(
    addressBar: StringArg('https://coui.dev'),
    pageContent: StringArg('Styled page content'),
    styled: BoolArg(true),
  ),
);
