import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'footer.stories.g.dart';

const List<CoreFooterNavData<Widget>> _kSections = [
  CoreFooterNavData<Widget>(
    title: 'Services',
    children: [
      Text('Branding'),
      Text('Design'),
      Text('Marketing'),
    ],
  ),
  CoreFooterNavData<Widget>(
    title: 'Company',
    children: [
      Text('About us'),
      Text('Contact'),
      Text('Jobs'),
    ],
  ),
  CoreFooterNavData<Widget>(
    title: 'Legal',
    children: [
      Text('Terms'),
      Text('Privacy'),
      Text('Cookies'),
    ],
  ),
];

/// Knob input for [Footer] stories.
class FooterInput {
  /// Creates a [FooterInput].
  const FooterInput({this.layout = CoreFooterLayout.horizontal});

  /// Section arrangement of the footer.
  final CoreFooterLayout layout;
}

/// Navigation metadata for the Footer component.
const kComponentMeta = ComponentMeta(name: 'Footer', path: 'layout');

/// Story metadata for [Footer].
const kMeta = Meta(Footer.new, argsType: FooterInput.new);

/// Default builder mapping [FooterInput] args to a [Footer].
final FooterDefaults defaults = _Defaults(
  setup: (context, child, args) => SingleChildScrollView(child: child),
  builder: (context, args) => Footer(
    sections: _kSections,
    aside: const Text('(c) 2026 CoUI - Industrial Ltd.'),
    layout: args.layout,
  ),
);

/// Horizontal footer with editable knobs.
final $Default = _Story();

/// Vertically stacked, left-aligned sections.
final $Vertical = _Story(
  args: _Args(
    layout: EnumArg(
      CoreFooterLayout.vertical,
      values: CoreFooterLayout.values,
    ),
  ),
);

/// Vertically stacked, centre-aligned sections.
final $Center = _Story(
  args: _Args(
    layout: EnumArg(
      CoreFooterLayout.center,
      values: CoreFooterLayout.values,
    ),
  ),
);
