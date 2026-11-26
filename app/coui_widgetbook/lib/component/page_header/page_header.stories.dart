import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'page_header.stories.g.dart';

// PageHeader widgetbook constants.
//
// The header fills the width it is given, so the harness hands it a page
// column's width. The narrow story hands it less than the text keeps beside
// two buttons, so the actions move under the text.
const double _kPageWidth = CoreLayout.layout640;
const double _kNarrowWidth = CoreLayout.layout320;

/// The most actions a story draws — the last one is the primary.
const int _kMaxActions = 3;

void _handleNoop() {}

/// Knob input for [PageHeader] stories.
class PageHeaderInput {
  /// Creates a [PageHeaderInput].
  const PageHeaderInput({
    this.eyebrow = 'Workspace',
    this.title = 'Settings',
    this.description = 'Members, billing and integrations.',
    this.actionCount = 2,
    this.headingLevel = CorePageHeaderContract.defaultHeadingLevel,
  });

  /// Eyebrow text over the title (hidden when empty).
  final String eyebrow;

  /// Page title text.
  final String title;

  /// Sentence under the title (hidden when empty).
  final String description;

  /// How many actions sit at the end of the row, 0–3. The last is the
  /// primary, the others secondary.
  final int actionCount;

  /// Heading level of the title, 1–6.
  final int headingLevel;
}

/// The actions of [count] — secondaries first, the primary last.
List<Widget> _actions(int count) {
  final n = count.clamp(0, _kMaxActions);
  return [
    for (var i = 0; i < n; i++)
      if (i == n - 1)
        const Button(onPressed: _handleNoop, child: Text('Save changes'))
      else
        Button(
          variant: .secondary,
          onPressed: _handleNoop,
          child: Text(i == 0 ? 'Cancel' : 'Preview'),
        ),
  ];
}

/// Builds a [PageHeader] from [args].
PageHeader _header(_Args args) => PageHeader(
  eyebrow: args.eyebrow.isEmpty ? null : Text(args.eyebrow),
  title: Text(args.title),
  description: args.description.isEmpty ? null : Text(args.description),
  actions: _actions(args.actionCount),
  headingLevel: args.headingLevel.clamp(1, 6),
);

/// Navigation metadata for the PageHeader component.
const kComponentMeta = ComponentMeta(name: 'PageHeader', path: 'layout');

/// Story metadata for [PageHeader].
const kMeta = Meta(PageHeader.new, argsType: PageHeaderInput.new);

/// Default builder mapping [PageHeaderInput] args to a [PageHeader].
final PageHeaderDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kPageWidth, child: child),
  builder: (context, args) => _header(args),
);

/// Eyebrow, title, description and a secondary + primary pair at the end of
/// the row, bottoms lined up.
final $Default = _Story();

/// Title only — no eyebrow, no description, no actions.
final $TitleOnly = _Story(
  name: 'Title Only',
  args: _Args(
    eyebrow: StringArg(''),
    description: StringArg(''),
    actionCount: IntArg(0),
  ),
);

/// A width under the text floor plus the actions: the actions move under
/// the text, start aligned.
final $Narrow = _Story(
  setup: (context, child, args) => SizedBox(width: _kNarrowWidth, child: child),
);
