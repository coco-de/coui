import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;

/// Layout primitive tokens — the bounds a panel or overlay is allowed to
/// take: a dialog's maximum width, a list's scroll ceiling, an inline
/// panel's minimum width, an empty state's floor.
///
/// The three dimension namespaces split by *what is being measured*:
///
/// | question | namespace |
/// |---|---|
/// | how big is an element (icon, control, avatar)? | [CoreSize] |
/// | how far apart are two elements? | [CoreSpace] |
/// | what may a panel or overlay grow or shrink to? | [CoreLayout] |
///
/// [CoreSize] stops at 128 on purpose — a 200px "element" does not exist,
/// that is a panel. [CoreSpace] reaches 256 but is a rhythm namespace: a
/// list that scrolls at `space/256` moves the moment density tuning
/// shrinks spacing, which is a different decision from "how tall may this
/// list be". Panel bounds were being written into whichever of the two had
/// the number, and that is the gap this ladder closes.
///
/// Flutter: `CoreLayout.layout640` → 640.0 (const double).
/// Web: `CoreLayout.scale.layout640` → 'layout640' (Tailwind key, resolves
/// to `var(--coui-layout-640)`).
///
/// ## A few steps, not a ladder
///
/// This is not an interval scale. Each value is a bound some component
/// actually states, and the set grows only when a component states a new
/// one — a bound nobody states is a number waiting to be picked for no
/// reason.
///
/// Widths themselves are not tokens. An inline panel takes its parent's
/// width and a fullscreen one takes the viewport's; what a token carries
/// is the *constraint* — a floor or a ceiling — never the rendered size.
///
/// The same steps are `Primitives/layout/*` in Figma (scope
/// `WIDTH_HEIGHT`), so a bound bound on the canvas and a bound read by a
/// resolver name the same variable.
abstract final class CoreLayout {
  const CoreLayout._();

  // === Values (double) ===

  /// 160px — a compact action menu's minimum width: icon-and-short-label
  /// rows on a phone (the `Fab` speed-dial panel). Below [layout240], the
  /// floor of a `Menu` that also carries shortcuts, submenus and
  /// description lines.
  static const layout160 = 160.0;

  /// 240px — an inline panel's minimum width; an empty state's minimum
  /// height (so a panel does not collapse when its results vanish).
  static const layout240 = 240.0;

  /// 248px — a sidebar panel's width (`Sidebar` `standard`): a 216 row
  /// with 16 at each side.
  static const layout248 = 248.0;

  /// A menu panel's ceiling — M3 and Flutter's shared menu maximum
  /// (8 × 35). The floor is [layout240] (Button · Menu 개편 §8-2).
  static const layout280 = 280.0;

  /// 320px — an inline list's scroll ceiling.
  static const layout320 = 320.0;

  /// 400px — a dialog list's scroll ceiling.
  static const layout400 = 400.0;

  /// 560px — a dialog panel's maximum width.
  static const layout560 = 560.0;

  /// 640px — a command palette dialog's maximum width.
  static const layout640 = 640.0;

  // === Scale Names (String for Web) ===

  /// Tailwind class name record for compile-safe interpolation.
  ///
  /// `'max-w-${CoreLayout.scale.layout640}'` → `max-w-layout640`.
  static const ({
    String layout160,
    String layout240,
    String layout248,
    String layout280,
    String layout320,
    String layout400,
    String layout560,
    String layout640,
  })
  scale = (
    layout160: 'layout160',
    layout240: 'layout240',
    layout248: 'layout248',
    layout280: 'layout280',
    layout320: 'layout320',
    layout400: 'layout400',
    layout560: 'layout560',
    layout640: 'layout640',
  );

  /// Every step, in ascending order — for tests and tooling that walk the
  /// palette rather than name a member.
  static const List<double> values = [
    layout160,
    layout240,
    layout248,
    layout280,
    layout320,
    layout400,
    layout560,
    layout640,
  ];
}
