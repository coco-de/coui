import 'package:coui_core/src/size/size.dart';

/// Semantic size constraint — form-control height alignment.
///
/// Guarantees that form controls placed side by side in one row share
/// the same height at each [heightXs]–[heightXl2] step. This is a
/// *constraint*, not a scale: unlike color's semantic layer there is no
/// global `size-md` that covers icons, avatars and buttons at once —
/// an icon's medium is 24, an avatar's 40, a chip's 32. Only the
/// cross-component contracts live here.
///
/// Applies to the components that can sit in one row: Button,
/// TextField, Select · Dropdown (and future TextField-family inputs —
/// Combobox, DatePicker, SearchField). An icon-only affordance is
/// `Button(variant: .plain, child: Icon(...))`, so it inherits the
/// alignment automatically rather than needing its own entry.
///
/// Deliberately NOT applied to: Chip (its own intentionally different
/// height ladder — 28 · 32 · 40), Checkbox · Radio · Toggle (no
/// row-alignment contract), Tabs (navigation, not a form control).
///
/// Component styles reference these members *directly* as their height
/// defaults instead of minting per-component height tokens — a
/// `ButtonTokens.heightMd` middleman would let one side drift without
/// touching the contract, which is exactly the silent failure this
/// layer exists to prevent. The alignment is additionally pinned by a
/// regression test comparing the participating `defaultsBySize` maps.
///
/// The corner follows the height. Button, TextField and TextArea state
/// their radius on their own size rows as the height × 0.25 — 6 · 8 · 10 ·
/// 12 · 14 · 16, each a `CoreRadius` rung — and a Core test pins that ratio
/// against these members. A standalone MenuItem states its own 8 · 8 · 12:
/// its `md` row is 36, which is not a rung here, and 36 × 0.25 = 9 is not a
/// `CoreRadius` rung either. The radii live on the rows rather than here:
/// this class is the heights the rows align to, and a row a panel hosts (a
/// menu row, a select option, a command row) takes its host's corner
/// instead of the ladder.
///
/// A chip is on its own ladder but takes the same ratio: it states its corner
/// on its own size rows as its height × 0.25 — 8 and 10 for the 32 and 40
/// rows. The 28 row's 7 is not a `CoreRadius` rung, so it snaps to the rung
/// below it, 6. A corner off the radius ladder would miss a surface style's
/// redistribution and the Web `--coui-radius-*` variables, so the exception
/// is "the ratio is not a rung", not a size.
///
/// A density moves these heights one rung of this ladder
/// (`CoreDensity.controlHeight`), and the corners that follow them one rung
/// of the same ladder at [cornerRatio] — the primitive palette and
/// icon/touch-target sizes stay where they are.
abstract final class CoreControlSize {
  const CoreControlSize._();

  /// 24px — smallest control row (Carbon xs · Fluent sm · Ant SM).
  static const double heightXs = CoreSize.size24;

  /// 32px — the default control size across surveyed systems · M3 XS
  /// button.
  static const double heightSm = CoreSize.size32;

  /// 40px — CoUI's default control height (Carbon md · Fluent lg ·
  /// Ant LG).
  static const double heightMd = CoreSize.size40;

  /// 48px — Carbon lg · Flutter `kMinInteractiveDimension`.
  static const double heightLg = CoreSize.size48;

  /// 56px — M3 M button · Flutter `kToolbarHeight`.
  static const double heightXl = CoreSize.size56;

  /// 64px — M3 app bar · Carbon xl.
  static const double heightXl2 = CoreSize.size64;

  /// Every rung of the ladder, in ascending order.
  static const List<double> steps = [
    heightXs,
    heightSm,
    heightMd,
    heightLg,
    heightXl,
    heightXl2,
  ];

  /// Whether [px] is a rung of the ladder.
  ///
  /// The one question "can a density move this row?" turns on: a height off
  /// the ladder (a standalone MenuItem's 36) is not a row of it and nothing
  /// re-points it.
  static bool isRung(double px) => steps.contains(px);

  /// A control's corner as a share of its row height.
  ///
  /// The rows state their corners as constants (6 · 8 · 10 · 12 · 14 · 16);
  /// this names the rule those constants follow, for the one reader that
  /// has to derive a corner from a height it moved rather than read one
  /// off a row — a density.
  static const double cornerRatio = 0.25;
}
