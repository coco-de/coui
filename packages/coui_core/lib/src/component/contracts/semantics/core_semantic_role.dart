/// How a component announces *what it is* to assistive technology.
///
/// This is the platform-neutral seat for the one piece of accessibility
/// metadata that was previously a raw ARIA string living in
/// `coui_core` — a platform-neutral package holding one platform's
/// vocabulary, which `core/layer-mapping.md` forbids. Each platform
/// adapter translates a value here into its own mechanism.
///
/// ## Not a style, and not a component parameter
///
/// A role is an **invariant**, not a knob. `Tabs` is always a tab list.
/// Putting it on a Style would let a surface-style preset rewrite a
/// component's role; exposing it as a constructor parameter would
/// invite `Tabs(role: banner)`. Components state their role as a
/// constant and the adapters do the rest.
///
/// ## Values carry an emit site
///
/// Every value below is emitted by at least one component today. A new
/// role arrives together with the component that states it — a value
/// nothing emits is a declaration with no reader, which reads as
/// support that does not exist.
library;

/// What a platform can actually do with a [CoreSemanticRole].
///
/// The four states exist because "Flutter has no `listbox` role" and
/// "Flutter would crash on `tooltip`" are different facts with
/// different futures, and collapsing them into "unsupported" loses the
/// one that will change.
enum CoreSemanticRoleSupport {
  /// Both platforms have a native role for this. Nothing is lost.
  mapped,

  /// The platform has no role, but its **canonical** mechanism for
  /// this concept is a semantics flag — an idiom, not a degradation.
  /// Some of these flags are carried by the component's own state
  /// (`checked:` / `toggled:`) rather than derived from the role.
  flagged,

  /// No expression exists on one platform. Nothing is emitted there,
  /// and the asymmetry is recorded with its condition — the escape
  /// `core/theme-axis-composition.md` allows when a capability is
  /// genuinely absent rather than unimplemented.
  absent,

  /// The platform *can* express it, but doing so is unsafe on the
  /// current SDK. Each value below documents the condition that has to
  /// change before it moves to [mapped].
  deferred,
}

/// The role a component announces.
///
/// Flutter's own `SemanticsRole` is narrower than ARIA and — for five
/// of its values — asserts in debug builds when used, so the mapping is
/// deliberately not one-to-one. See [CoreSemanticRoleSupport].
enum CoreSemanticRole {
  // ─── mapped — both platforms have a native role ───

  /// The container of a tab set. Flutter calls this `tabBar`.
  tabList(.mapped),

  /// One tab within a [tabList].
  tab(.mapped),

  /// The panel a [tab] reveals.
  tabPanel(.mapped),

  /// A modal or non-modal dialog surface.
  dialog(.mapped),

  /// A menu of commands.
  menu(.mapped),

  /// A horizontal bar of menu triggers.
  menuBar(.mapped),

  /// One command inside a [menu] or [menuBar].
  menuItem(.mapped),

  /// A menu entry that toggles.
  ///
  /// Distinct from [menuItem] because a reader announces the checked
  /// state, and from [checkbox] because it belongs to a menu.
  menuItemCheckbox(.mapped),

  /// A menu entry that selects one of a set.
  menuItemRadio(.mapped),

  /// A list of items.
  list(.mapped),

  /// An entry in a [list].
  ///
  /// Only meaningful inside one — a reader announces "1 of 5" from the
  /// parent, and an item without that parent says a position it does
  /// not have.
  listItem(.mapped),

  /// A set of mutually exclusive radio inputs.
  radioGroup(.mapped),

  /// A determinate or indeterminate progress indicator.
  progressBar(.mapped),

  /// A structure of data arranged in rows and columns, read-only.
  table(.mapped),

  /// An interactive structure of data arranged in rows and columns —
  /// distinct from [table] because ARIA gives the two different
  /// semantics (a grid's cells may be individually focusable/editable).
  /// Flutter has no separate concept for this; both answer with the
  /// same native [table] role.
  grid(.mapped),

  /// A row of [cell]s, [gridCell]s or [columnHeader]s in a [table] or
  /// [grid]. ARIA does not distinguish a table's row from a grid's.
  row(.mapped),

  /// A [table] cell that does not carry column or row header
  /// information.
  cell(.mapped),

  /// A [grid] cell that does not carry column or row header
  /// information.
  ///
  /// Distinct from [cell] because ARIA gives a grid's cells a different
  /// role than a table's — see [grid]. Flutter has no separate concept
  /// for this either; both answer with the same native [cell] role.
  gridCell(.mapped),

  /// A cell that carries header information for a column, in either a
  /// [table] or a [grid]. ARIA does not distinguish the two.
  columnHeader(.mapped),

  /// The landmark holding a page's primary content.
  ///
  /// One per page. It is what a screen-reader user jumps to in order to
  /// skip the header and navigation, and a page without it makes that
  /// jump land nowhere.
  main(.mapped),

  /// A landmark holding navigation links.
  navigation(.mapped),

  /// A generic landmark region.
  region(.mapped),

  /// The footer landmark of a page or section.
  contentInfo(.mapped),

  // ─── flagged — the platform's canonical mechanism is a flag ───

  /// A control that performs an action. Flutter: `button:`.
  button(.flagged),

  /// A navigational link. Flutter: `link:`.
  link(.flagged),

  /// Graphical content. Flutter: `image:`. ARIA spells this `img`.
  image(.flagged),

  /// A two-state input. Flutter carries this on the component's own
  /// `checked:` state rather than deriving it from the role — the role
  /// alone cannot say whether the box is ticked.
  checkbox(.flagged),

  /// One option in a [radioGroup]. Flutter:
  /// `inMutuallyExclusiveGroup:` from the role, `checked:` from state.
  radio(.flagged),

  /// An on/off switch. Named for the Dart keyword clash. Flutter
  /// carries this on the component's own `toggled:` state.
  toggleSwitch(.flagged),

  /// A region whose text the user edits — a rich editor's document.
  /// Flutter carries this on the editing widget's own text-field
  /// semantics rather than deriving it from the role, the same way
  /// [checkbox] carries `checked:`.
  textbox(.flagged),

  /// A value picked along a range. Flutter: `slider:`.
  slider(.flagged),

  /// A focusable divider that resizes the regions on either side of it —
  /// the ARIA APG "window splitter" pattern (`aria-valuenow` /
  /// `aria-valuemin` / `aria-valuemax`, arrow-key adjustable). Flutter has
  /// no distinct role for this; the same `slider:` flag [slider] uses is
  /// its nearest idiom — both are a focusable, arrow-key-adjustable value
  /// along a range, and Flutter's accessibility tree does not distinguish
  /// "adjustable value" from "adjustable value that also separates
  /// content".
  ///
  /// ARIA reuses this same `role="separator"` spelling for a
  /// non-focusable variant too — e.g. a `Divider` marking a boundary
  /// between groups of [menuItem]s in a [menu], which carries no value
  /// and is never focused. The widget-vs-static distinction lives in
  /// `tabindex`/`aria-value*`, not in a second role name, so Web states
  /// the same ARIA spelling either way. Flutter has no such single
  /// mechanism: the `slider:` flag above is specific to the focusable
  /// case, so a non-focusable user of this role does not go through
  /// this enum's generic Flutter mapping at all — it states its own
  /// plain accessible name directly (the Flutter `Divider` widget does
  /// this for its `semantic: true` case), the same way the *focusable*
  /// user of this role (`Resizable`) also hand-writes its Semantics
  /// rather than delegating to the generic mapping.
  separator(.flagged),

  /// The draggable thumb of a scrollbar. Flutter has no distinct
  /// concept for this either — a scrollbar thumb reports position on
  /// the same `[0, 100]` percent range a range widget does, so both
  /// answer with the same `slider:` flag. ARIA distinguishes the two
  /// (`scrollbar` implies `aria-controls` on the region it moves),
  /// which is why this is a separate value rather than reusing
  /// [slider] outright.
  ///
  /// As with [separator], that `slider:` mapping is what this role
  /// *would* answer with, not a path anything takes: the only reader of
  /// this value in the kit is the Web `ariaRole`. The Flutter
  /// `Scrollbar` states `Semantics(slider: true)` itself, because a flag
  /// is not what it needs to say — the percent value and the
  /// increase/decrease actions that move it are, and those come from the
  /// scroll notifications the bar already listens to, which no role can
  /// know about.
  scrollbar(.flagged),

  /// The header landmark of a page. Flutter: `header:`.
  banner(.flagged),

  /// A grouping with no stronger meaning. Flutter: `container:`.
  group(.flagged),

  /// Decorative — remove this subtree from the accessibility tree.
  /// Flutter: `excludeSemantics:`.
  presentation(.flagged),

  // ─── absent — no expression on Flutter ───

  /// A region where the platform's own keyboard handling should step
  /// aside. Flutter has no equivalent: its focus traversal is not
  /// browser-style, so there is nothing to step aside from.
  application(.absent),

  /// A list of selectable options. Flutter has no `listbox` role;
  /// selection is announced through `selected:` on each option.
  listBox(.absent),

  /// One option inside a [listBox]. See [listBox].
  option(.absent),

  /// A hierarchical disclosure structure. Flutter has no `tree` role;
  /// hierarchy is conveyed by `expanded:` on each node.
  tree(.absent),

  /// One node in a [tree]. See [tree].
  treeItem(.absent),

  /// A row of controls that act on one thing — a rich editor's
  /// formatting buttons. Flutter has no `toolbar` role; each button
  /// announces itself.
  toolbar(.absent),

  // ─── deferred — expressible but unsafe on the current SDK ───

  /// A transient description of the element that owns it.
  ///
  /// Flutter's `SemanticsRole.tooltip` has no debug check registered
  /// and raises `Missing checks for role` from an assert inside
  /// `SemanticsNode._addToUpdate` — which runs in every widget test
  /// that touches semantics. Moves to [CoreSemanticRoleSupport.mapped]
  /// when the SDK registers a check for it.
  tooltip(.deferred),

  /// A text input paired with a list of suggestions.
  ///
  /// Same SDK condition as [tooltip].
  comboBox(.deferred),

  /// An advisory region that announces its own changes.
  ///
  /// Flutter asserts that a node is not *both* `status` and a live
  /// region, and Web states both (`role="status"` +
  /// `aria-live="polite"`). Of the two, the live region is what
  /// actually gets announced on Flutter today, so that is what the
  /// adapter emits. Moves to [CoreSemanticRoleSupport.mapped] when the
  /// platforms announce the role itself.
  status(.deferred),

  /// An assertive version of [status]. Same condition.
  alert(.deferred);

  const CoreSemanticRole(this.support);

  /// What the narrower platform can do with this role.
  ///
  /// Read by the platform adapters — a role that is not
  /// [CoreSemanticRoleSupport.mapped] must not produce a native role
  /// on the platform that lacks one.
  final CoreSemanticRoleSupport support;
}
