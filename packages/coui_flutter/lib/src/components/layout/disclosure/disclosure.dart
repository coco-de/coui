import 'package:coui_flutter/coui_flutter.dart';

// ---------------------------------------------------------------------------
// Disclosure
// ---------------------------------------------------------------------------

/// A titled section the reader opens and closes, owning no state the
/// caller has to hold.
///
/// The Web twin renders `<details>/<summary>`, where the browser drives
/// the toggle with no script at all — which is the point of the
/// component. Flutter has no such hand-off (there is nothing to
/// hydrate), so it keeps the open state internally and exposes the same
/// surface: [open] seeds it, [onToggle] reports it.
///
/// ```dart
/// Disclosure(
///   title: 'What is CoUI?',
///   content: Text('A cross-platform design system.'),
/// )
/// ```
///
/// Use `Collapsible` when the caller must own the open state or the
/// reveal has to animate, and `Accordion` when opening one section
/// should close its siblings.
class Disclosure extends StatefulWidget
    implements CoreDisclosureContract<Widget> {
  /// Creates a [Disclosure].
  ///
  /// Supply either [title] or [trigger]; [trigger] wins when both are
  /// given.
  const Disclosure({
    required this.content,
    super.key,
    this.onToggle,
    this.title,
    this.trigger,
    this.open = false,
    this.disclosureStyle,
  }) : assert(
         trigger != null || title != null,
         'Provide either trigger or title.',
       );

  @override
  final String? title;

  @override
  final Widget? trigger;

  @override
  final Widget content;

  @override
  final bool open;

  @override
  final void Function(bool)? onToggle;

  @override
  final CoreDisclosureStyle? disclosureStyle;

  /// Returns a copy of this [Disclosure] with the given fields replaced.
  Disclosure copyWith({
    Key? key,
    void Function(bool)? onToggle,
    String? title,
    Widget? trigger,
    Widget? content,
    bool? open,
    CoreDisclosureStyle? disclosureStyle,
  }) {
    return Disclosure(
      key: key ?? this.key,
      onToggle: onToggle ?? this.onToggle,
      title: title ?? this.title,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      open: open ?? this.open,
      disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    );
  }

  @override
  State<Disclosure> createState() => _DisclosureState();
}

/// Chain sugar mirroring the Web `Disclosure.withStyle` extension —
/// merges a [CoreDisclosureStyle] patch into [Disclosure.disclosureStyle]
/// via the existing [Disclosure.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDisclosureStyle.merge` right-side-wins semantics).
extension DisclosureStyleChain on Disclosure {
  /// Returns a copy of this [Disclosure] with [patch] merged into
  /// [disclosureStyle] (patch fields win on conflict).
  Disclosure withStyle(CoreDisclosureStyle patch) => copyWith(
    disclosureStyle: (disclosureStyle ?? const CoreDisclosureStyle()).merge(
      patch,
    ),
  );
}

class _DisclosureState extends State<Disclosure> {
  late bool _open;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _open = widget.open;
  }

  @override
  void didUpdateWidget(covariant Disclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `open` is a seed, not a controlled value — re-seed only when the
    // caller actually changes it, so a rebuild does not slam the section
    // shut under the reader.
    if (widget.open != oldWidget.open) {
      _open = widget.open;
    }
  }

  void handleToggle() {
    setState(() => _open = !_open);
    widget.onToggle?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    // Single entry point — the resolver applies the merge chain.
    final resolved = resolveDisclosure(
      context,
      disclosureStyle: widget.disclosureStyle,
    );

    final header = Clickable(
      onPressed: handleToggle,
      onHover: (hovered) => setState(() => _hovering = hovered),
      clickableStyle: resolved.clickableStyle,
      child: Semantics(
        button: true,
        expanded: _open,
        child: Padding(
          padding: resolved.contentInset,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: .centerStart,
                  child: DefaultTextStyle.merge(
                    // The hover underline is interaction state, layered
                    // on the paint-ready role from the resolver — Web
                    // parity for `hover:underline`. `decorationColor`
                    // tracks the resolved foreground so light/dark stays
                    // consistent.
                    style: resolved.triggerTextStyle.copyWith(
                      decoration: _hovering ? .underline : .none,
                      decorationColor: resolved.triggerTextStyle.color,
                    ),
                    child: widget.trigger ?? Text(widget.title!),
                  ),
                ),
              ),
              Gap(gapStyle: resolved.iconLabelGapStyle),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: resolved.duration,
                curve: resolved.curve,
                child: Icon(
                  LucideIcons.chevronDown,
                  iconStyle: resolved.iconStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        header,
        // Absent from the tree while closed, mirroring `<details>`:
        // the browser does not render closed content either, so nothing
        // here needs `inert` to stay out of the reading order.
        if (_open)
          Padding(
            padding: .only(top: resolved.contentInset.top),
            child: DefaultTextStyle.merge(
              style: resolved.contentTextStyle,
              child: widget.content,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DisclosureGroup
// ---------------------------------------------------------------------------

/// A stack of independent [Disclosure]s.
///
/// Opening one leaves the others alone — that is the whole difference
/// from `Accordion`, and it is why the group needs no state: each child
/// already owns its own.
///
/// ```dart
/// DisclosureGroup(
///   items: [
///     Disclosure(title: 'First', open: true, content: Text('…')),
///     Disclosure(title: 'Second', content: Text('…')),
///   ],
/// )
/// ```
class DisclosureGroup extends StatelessWidget
    implements CoreDisclosureGroupContract<Widget> {
  /// Creates a [DisclosureGroup].
  const DisclosureGroup({
    required this.items,
    super.key,
    this.disclosureStyle,
  });

  @override
  final List<Widget> items;

  @override
  final CoreDisclosureStyle? disclosureStyle;

  /// Returns a copy of this [DisclosureGroup] with the given fields
  /// replaced.
  DisclosureGroup copyWith({
    Key? key,
    List<Widget>? items,
    CoreDisclosureStyle? disclosureStyle,
  }) {
    return DisclosureGroup(
      key: key ?? this.key,
      items: items ?? this.items,
      disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDisclosure(
      context,
      disclosureStyle: disclosureStyle,
    );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: resolved.itemSpacing,
      children: items,
    );
  }
}

/// Chain sugar mirroring [DisclosureStyleChain] for the group.
extension DisclosureGroupStyleChain on DisclosureGroup {
  /// Returns a copy of this [DisclosureGroup] with [patch] merged into
  /// [disclosureStyle] (patch fields win on conflict).
  DisclosureGroup withStyle(CoreDisclosureStyle patch) => copyWith(
    disclosureStyle: (disclosureStyle ?? const CoreDisclosureStyle()).merge(
      patch,
    ),
  );
}
