import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'disclosure.stories.g.dart';

// Disclosure widgetbook constants.
const _kSectionWidth = 360.0;
const _kTitleText = 'What is CoUI?';
const _kBodyText = 'A design system whose Flutter and Web twins share one API.';
const _kCustomTriggerText = 'Shipping and returns';
const _kSiblingTitle = 'How do I install it?';
const _kSiblingBody = 'Add coui_flutter to pubspec.yaml.';

/// Knob input for [Disclosure] stories.
class DisclosureInput {
  /// Creates a [DisclosureInput].
  const DisclosureInput({
    this.title = _kTitleText,
    this.body = _kBodyText,
    this.open = false,
    this.customTrigger = false,
    this.grouped = false,
  });

  /// Plain-text header.
  final String title;

  /// Text revealed while the section is open.
  final String body;

  /// Whether the section starts open. A seed, not a controlled value —
  /// the widget owns the state from there.
  final bool open;

  /// Whether an icon row replaces the plain [title] as the header.
  /// `trigger` wins when both are supplied.
  final bool customTrigger;

  /// Whether the section is stacked with independent siblings in a
  /// [DisclosureGroup].
  final bool grouped;
}

/// Navigation metadata for the Disclosure component.
const kComponentMeta = ComponentMeta(name: 'Disclosure', path: 'layout');

/// Story metadata for [Disclosure].
const kMeta = Meta(Disclosure.new, argsType: DisclosureInput.new);

/// Default builder mapping [DisclosureInput] args to a [Disclosure],
/// optionally stacked with independent siblings.
final DisclosureDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: _kSectionWidth,
    child: args.grouped
        ? DisclosureGroup(
            items: [
              child,
              // Seeded open next to a closed sibling: the two states
              // coexist because neither section can reach the other.
              const Disclosure(
                title: _kSiblingTitle,
                open: true,
                content: Text(_kSiblingBody),
              ),
            ],
          )
        : child,
  ),
  builder: (context, args) => Disclosure(
    title: args.title,
    trigger: args.customTrigger
        ? const Row(
            mainAxisSize: .min,
            children: [
              // A bare Icon fills whatever main-axis extent the Row
              // offers, so the leading glyph is sized to match the
              // chevron the resolver draws on the other end.
              Icon(
                LucideIcons.truck,
                iconStyle: CoreIconStyle(
                  size: CoreDisclosureStyle.defaultArrowIconSize,
                ),
              ),
              Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
              Flexible(child: Text(_kCustomTriggerText)),
            ],
          )
        : null,
    open: args.open,
    content: Text(args.body),
  ),
);

/// Closed section with a plain-text header — tap it to reveal the body.
final $Default = _Story();

/// Section seeded open, so the body is in the tree on first build.
final $Open = _Story(args: _Args(open: BoolArg(true)));

/// Icon row header supplied through the trigger slot instead of
/// [DisclosureInput.title].
final $CustomTrigger = _Story(
  name: 'Custom Trigger',
  args: _Args(customTrigger: BoolArg(true)),
);

/// Stack of independent sections — opening one leaves its siblings
/// alone, which is the whole difference from Accordion.
final $Group = _Story(args: _Args(grouped: BoolArg(true)));
