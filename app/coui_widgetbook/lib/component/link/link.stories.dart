import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'link.stories.g.dart';

/// Interactive demo host for [Link] stories.
///
/// In interactive mode the link handles taps and shows a click
/// counter below.
class LinkDemo extends StatefulWidget {
  /// Creates a [LinkDemo].
  const LinkDemo({
    super.key,
    this.text = 'Click here',
    this.external = false,
    this.underline = false,
    this.variant = CoreLinkVariant.standard,
    this.interactive = false,
  });

  /// Link label text.
  final String text;

  /// Whether the link points to an external destination.
  final bool external;

  /// Whether the link is always underlined (otherwise it shows the
  /// underline while hovered, pressed or focused).
  final bool underline;

  /// The tone the link reads in.
  final CoreLinkVariant variant;

  /// Whether taps are handled and a click counter is shown.
  final bool interactive;

  @override
  State<LinkDemo> createState() => _LinkDemoState();
}

class _LinkDemoState extends State<LinkDemo> {
  int _clickCount = 0;

  void handlePressed() {
    setState(() {
      _clickCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space12,
      children: [
        Link(
          onPressed: widget.interactive ? handlePressed : null,
          href: widget.interactive ? 'https://example.com' : '#',
          external: widget.external,
          underline: widget.underline,
          variant: widget.variant,
          child: Text(widget.text),
        ),
        if (widget.interactive) Text('Clicked: $_clickCount'),
      ],
    );
  }
}

/// Navigation metadata for the Link component.
const kComponentMeta = ComponentMeta(name: 'Link', path: 'text');

/// Story metadata for [LinkDemo].
const kMeta = Meta(LinkDemo.new);

/// Static link with editable knobs.
final $Default = _Story();

/// Link in a supporting position — the secondary text colour.
final $Muted = _Story(
  args: _Args(
    text: StringArg('Terms of service'),
    variant: EnumArg(CoreLinkVariant.muted, values: CoreLinkVariant.values),
  ),
);

/// Link that is always underlined.
final $Underlined = _Story(
  args: _Args(
    text: StringArg('Always underlined'),
    underline: BoolArg(true),
  ),
);

/// Tap-handling link with a click counter.
final $Interactive = _Story(
  args: _Args(
    text: StringArg('Visit Example'),
    interactive: BoolArg(true),
  ),
);
