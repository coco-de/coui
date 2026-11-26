/// Where a context menu's preview goes, decided once for both platforms.
///
/// The menu is placed by each seat's overlay engine — at the pointer, flipped
/// and shifted until it is inside the viewport, held to the room it has. The
/// preview cannot be placed before that: it goes where the menu *ended up*.
/// So the seat measures the menu and the preview and asks this one rule, which
/// is pinned by a vector table (`test/fixtures/context_menu_preview_vectors.json`)
/// that the Core, Flutter and Web tests read, so the two seats cannot place the
/// same preview in different places.
library;

import 'package:coui_core/src/component/contracts/context_menu/context_menu_contract.dart';
import 'package:coui_core/src/component/contracts/stacks/core_text_direction.dart';
import 'package:coui_core/src/context_menu/context_menu_geometry.dart';
import 'package:meta/meta.dart';

/// Which side of the menu the preview sits on.
enum CorePreviewSide {
  /// Over the menu: the preview's bottom edge is the gap above the menu's top.
  above,

  /// Under the menu: the preview's top edge is the gap below the menu's bottom.
  below,

  /// At the menu's end in reading direction: right in left-to-right text, left
  /// in right-to-left.
  end,

  /// At the menu's start in reading direction: left in left-to-right text,
  /// right in right-to-left.
  start,
}

/// Where a preview sits and how large it may be there.
@immutable
class CorePreviewPlacement {
  /// Creates a placement.
  const CorePreviewPlacement({
    required this.side,
    required this.box,
    required this.capped,
  });

  /// The side of the menu the preview is on.
  final CorePreviewSide side;

  /// The preview's box: its corner, and the size it may take. The seat lays
  /// the preview out at its natural size inside this box as a *maximum*, so a
  /// preview that fits keeps its size and one that does not is held to the
  /// room.
  final CoreMenuBox box;

  /// Whether the box is smaller than the preview's natural size — the room, or
  /// the viewport itself, held it.
  final bool capped;

  /// Whether there is any room to show it in. A viewport the menu fills
  /// leaves none, and the preview is left out rather than drawn over the menu
  /// or off the screen.
  bool get visible => !box.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePreviewPlacement &&
          side == other.side &&
          box == other.box &&
          capped == other.capped;

  @override
  int get hashCode => Object.hash(side, box, capped);

  @override
  String toString() => 'CorePreviewPlacement($side, $box, capped: $capped)';
}

/// The rule that places a preview around an open menu.
abstract final class CoreContextMenuPreview {
  const CoreContextMenuPreview._();

  /// Places a preview of natural size [previewWidth] × [previewHeight] around
  /// the [menu] inside [viewport].
  ///
  /// The sides are tried **above, below, end, start** and the first whose room
  /// holds the preview at its natural size wins. Vertical sides come first
  /// because the viewports that need this are phones, where the width beside
  /// a 240–280 wide menu is the scarce one.
  ///
  /// A preview wider or taller than the viewport is first reduced to the
  /// viewport. If no side holds it, it takes the side with **the most room**
  /// (ties go to the earlier side) and is held to that room along that side's
  /// axis — it is never drawn over the menu and never leaves the viewport. A
  /// side with no room at all leaves nothing to draw, and
  /// [CorePreviewPlacement.visible] is false.
  ///
  /// Along the side's own axis the preview sits [gap] from the menu. Across it
  /// the preview's start edge lines up with the menu's start edge (above and
  /// below) or its top edge with the menu's top (end and start), then slides
  /// back inside the viewport if that would leave it.
  ///
  /// [direction] decides what *end* and *start* mean and which edge counts as
  /// the start edge; everything else is physical.
  static CorePreviewPlacement place({
    required CoreMenuBox menu,
    required double previewWidth,
    required double previewHeight,
    required CoreMenuBox viewport,
    double gap = CoreContextMenuContract.defaultPreviewGap,
    CoreTextDirection direction = CoreTextDirection.ltr,
  }) {
    final rtl = direction == CoreTextDirection.rtl;
    final width = _min(previewWidth, viewport.width);
    final height = _min(previewHeight, viewport.height);

    final rooms = {
      CorePreviewSide.above: menu.top - gap - viewport.top,
      CorePreviewSide.below: viewport.bottom - (menu.bottom + gap),
      // Physical right and left, named by reading direction.
      if (rtl) ...{
        CorePreviewSide.end: menu.left - gap - viewport.left,
        CorePreviewSide.start: viewport.right - (menu.right + gap),
      } else ...{
        CorePreviewSide.end: viewport.right - (menu.right + gap),
        CorePreviewSide.start: menu.left - gap - viewport.left,
      },
    };

    bool vertical(CorePreviewSide side) =>
        side == CorePreviewSide.above || side == CorePreviewSide.below;
    double needed(CorePreviewSide side) => vertical(side) ? height : width;

    // The first side, in order, that holds the preview whole, else the side
    // with the most room — which holds it only in part.
    final chosen =
        CorePreviewSide.values
            .where((side) => rooms[side]! >= needed(side))
            .firstOrNull ??
        CorePreviewSide.values.reduce(
          (best, side) => rooms[side]! > rooms[best]! ? side : best,
        );

    final room = rooms[chosen]! > 0 ? rooms[chosen]! : 0.0;
    final boxWidth = vertical(chosen) ? width : _min(width, room);
    final boxHeight = vertical(chosen) ? _min(height, room) : height;

    final double left;
    final double top;
    if (vertical(chosen)) {
      // The start edge lines up with the menu's start edge.
      final aligned = rtl ? menu.right - boxWidth : menu.left;
      left = _clamp(aligned, viewport.left, viewport.right - boxWidth);
      top = chosen == CorePreviewSide.above
          ? menu.top - gap - boxHeight
          : menu.bottom + gap;
    } else {
      // Physical right of the menu is the end side in left-to-right text and
      // the start side in right-to-left.
      final onRight = (chosen == CorePreviewSide.end) != rtl;
      left = onRight ? menu.right + gap : menu.left - gap - boxWidth;
      top = _clamp(menu.top, viewport.top, viewport.bottom - boxHeight);
    }

    return CorePreviewPlacement(
      side: chosen,
      box: CoreMenuBox.fromLTWH(left, top, boxWidth, boxHeight),
      capped: boxWidth < previewWidth || boxHeight < previewHeight,
    );
  }

  static double _min(double a, double b) => a < b ? a : b;

  /// [value] held to [low]..[high]; when the range is empty (the box is
  /// larger than the room) the low edge wins.
  static double _clamp(double value, double low, double high) {
    if (high < low) return low;
    if (value < low) return low;

    return value > high ? high : value;
  }
}
