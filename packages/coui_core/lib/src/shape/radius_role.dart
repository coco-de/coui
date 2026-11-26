import 'package:coui_core/src/shape/radius_scale.dart';

/// Semantic corner roles — the five named steps of the radius ladder.
///
/// A role answers "what kind of element is this?" rather than "how round
/// is it?": a component states [panel] and the number follows. Each member
/// is an *alias* of a [CoreRadius] step, resolved at compile time, so
/// everything that already moves values along the ladder (surface style
/// presets, the `--coui-radius-*` variables on Web) reaches a role exactly
/// as it reaches the step it names. A role is not a second scale and does
/// not make a component's corner independent of the ladder.
///
/// Corners that no role answers stay primitives: fully rounded
/// ([CoreRadius.radius9999]), deliberately square ([CoreRadius.radius0]),
/// values *derived* from a role (an inner corner is the outer one minus the
/// padding and border; a focus band is the corner plus its offset), and
/// elements whose role has not been decided.
///
/// Members are plain `double` constants, so they go wherever a [CoreRadius]
/// constant goes — `CoreBorderRadius.all(CoreRadiusRole.panel)`.
abstract final class CoreRadiusRole {
  const CoreRadiusRole._();

  /// A small element inside or beside a control, or text-level emphasis —
  /// roughly under 24px: a checkbox box, a keyboard key, an inline code run,
  /// a scrollbar thumb.
  static const double part = CoreRadius.radius4;

  /// Something pressed or typed into, or one row of a list — roughly 24 to
  /// 64px, one line: a tooltip, a control with no size ladder of its own.
  /// A row a panel hosts does not take this role: its corner is derived from
  /// the panel (the panel corner minus the panel padding, 12 − 6 = 6).
  ///
  /// The one role that is not size independent where a size ladder exists:
  /// a control on the `CoreControlSize` ladder (a button, a text field, a
  /// text area) states its corner on its own size rows as the control
  /// height × 0.25, so it reads 8 only at `sm`. A standalone menu item
  /// states 8 · 8 · 12 on its own rows. Every other role is the same value
  /// at every size.
  static const double control = CoreRadius.radius8;

  /// A face that floats over the screen to hold a list or a choice, or an
  /// inline notice.
  static const double panel = CoreRadius.radius12;

  /// A card or large container that sits on the screen: a card, a drawer
  /// panel.
  static const double surface = CoreRadius.radius16;

  /// A surface that takes the whole screen's attention and blocks what is
  /// under it: a dialog, a command-palette dialog.
  ///
  /// One step rounder than [surface] because a modal is the outermost box
  /// on the screen while it is open — everything it holds sits inside it,
  /// so its corner is the largest the screen draws.
  static const double modal = CoreRadius.radius20;
}
