/// Where each action of a stretched `Dialog` actions row goes — decided
/// once for both platforms.
///
/// The Web never calls this: it states the row in CSS — a wrapping flex row
/// whose cells start at an equal share of the row (`flex-basis`), never go
/// narrower than their action (`min-width: fit-content`) and grow to fill
/// what is left — and the browser lays it out. Flutter has no such row, so
/// its render object asks this class where each action lands. Kept here so
/// the two cannot disagree about it, and pinned by one vector table
/// (`test/fixtures/dialog_actions_stretch_vectors.json`) that the Core and
/// Flutter tests and a real-Chrome probe all read.
library;

import 'package:meta/meta.dart';

/// One action's intrinsic widths, in logical pixels — what the row reads to
/// place it.
@immutable
class CoreDialogStretchAction {
  /// Creates a [CoreDialogStretchAction].
  const CoreDialogStretchAction({
    required this.minWidth,
    required this.maxWidth,
  });

  /// The narrowest the action can be laid out without overflowing — its
  /// label broken at every opportunity (CSS `min-content`). Flutter states it
  /// held to the row's width, since it never lays an action out wider than
  /// its row; CSS states it as it is.
  final double minWidth;

  /// The width the action takes when nothing limits it — its label on one
  /// line (CSS `max-content`).
  final double maxWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDialogStretchAction &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth;

  @override
  int get hashCode => Object.hash(minWidth, maxWidth);

  @override
  String toString() => 'CoreDialogStretchAction($minWidth, $maxWidth)';
}

/// Where one action of the row lands.
@immutable
class CoreDialogStretchCell {
  /// Creates a [CoreDialogStretchCell].
  const CoreDialogStretchCell({
    required this.line,
    required this.start,
    required this.width,
  });

  /// The row the action sits on, counted from 0 at the top.
  final int line;

  /// How far the action's start edge sits from the row's start edge — the
  /// left edge when the text runs left to right, the right edge when it runs
  /// right to left. Negative only when one action alone is wider than the
  /// row (it overflows at the start, as the row keeps its end aligned) —
  /// which only CSS states, as Flutter holds every narrowest width to the
  /// row.
  final double start;

  /// The action's width.
  final double width;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDialogStretchCell &&
          line == other.line &&
          start == other.start &&
          width == other.width;

  @override
  int get hashCode => Object.hash(line, start, width);

  @override
  String toString() => 'CoreDialogStretchCell(line $line, $start, $width)';
}

/// The stretched actions row: every action starts at an equal share of the
/// row and the row fills its width.
///
/// It is the CSS the Web states, worked out the way CSS works it out
/// (CSS Flexible Box Layout §9.3 and §9.7):
///
/// * each action's **share** is the row less the gaps between all of them,
///   split evenly — the cell's `flex-basis`;
/// * no action goes narrower than its **fit** — its natural width, or the
///   row's width when the natural width is wider, but never under its
///   narrowest width (`min-width: fit-content`);
/// * actions are collected onto a line while their larger of share and fit,
///   plus the gaps, still fit the row; the first action that does not fit
///   starts the next line;
/// * on each line the free width is handed out evenly, an action held at its
///   fit takes no more, and what it leaves goes to the others
///   (`flex-grow: 1`).
///
/// So one action fills the row; two that each fit their half split it in
/// half; and when either of two does not fit its half, both stack, each the
/// full width. Three or more fill a line as far as they fit and the next
/// line takes the rest, every line filling its width.
abstract final class CoreDialogActionsStretch {
  const CoreDialogActionsStretch._();

  /// How far apart two widths may be and still count as equal — far below
  /// the 1/64 px a browser lays out in, far above the rounding the
  /// arithmetic here can pile up.
  static const double tolerance = 1e-6;

  /// Places [actions] on a row [width] wide, [spacing] apart.
  ///
  /// The cells come back in the order of [actions]. An empty list places
  /// nothing.
  static List<CoreDialogStretchCell> place({
    required double width,
    required double spacing,
    required List<CoreDialogStretchAction> actions,
  }) {
    final count = actions.length;
    if (count == 0) return const [];
    // The cell's `flex-basis`. A negative `calc()` length clamps to 0 there.
    final share = _atLeastZero((width - spacing * (count - 1)) / count);
    // `min-width: fit-content` — min(max-content, max(min-content, row)).
    final fits = [
      for (final action in actions)
        _min(action.maxWidth, _max(action.minWidth, width)),
    ];
    // The size an action is collected onto a line with — its basis held
    // at its fit.
    final hypothetical = [for (final fit in fits) _max(share, fit)];

    final cells = <CoreDialogStretchCell>[];
    var line = 0;
    var first = 0;
    while (first < count) {
      // Collect: the first action always goes on; each next one while the
      // line, its gap and it still fit.
      var end = first + 1;
      var used = hypothetical[first];
      while (end < count &&
          used + spacing + hypothetical[end] <= width + tolerance) {
        used += spacing + hypothetical[end];
        end += 1;
      }
      final widths = _resolveLine(
        width: width,
        spacing: spacing,
        share: share,
        fits: fits.sublist(first, end),
        hypothetical: hypothetical.sublist(first, end),
      );
      // `justify-content: flex-end` — whatever the line leaves goes before
      // its first action; an overflowing line overflows at the start.
      var taken = spacing * (widths.length - 1);
      for (final w in widths) {
        taken += w;
      }
      var start = width - taken;
      for (final w in widths) {
        cells.add(CoreDialogStretchCell(line: line, start: start, width: w));
        start += w + spacing;
      }
      line += 1;
      first = end;
    }

    return cells;
  }

  /// Resolves the widths of the actions on one line — CSS §9.7 for items
  /// that all grow and shrink by 1 from the same [share], with no maximum.
  static List<double> _resolveLine({
    required double width,
    required double spacing,
    required double share,
    required List<double> fits,
    required List<double> hypothetical,
  }) {
    final count = fits.length;
    final gaps = spacing * (count - 1);
    var hypotheticalSum = gaps;
    for (final h in hypothetical) {
      hypotheticalSum += h;
    }
    final grows = hypotheticalSum < width;
    final targets = List<double>.filled(count, share);
    final frozen = List<bool>.filled(count, false);
    // An action that cannot move the way the line needs is held at the size
    // it was collected with: shrinking, one whose basis is already under it.
    if (!grows) {
      for (var i = 0; i < count; i++) {
        if (share < hypothetical[i]) {
          frozen[i] = true;
          targets[i] = hypothetical[i];
        }
      }
    }
    while (frozen.contains(false)) {
      var free = width - gaps;
      var unfrozen = 0;
      for (var i = 0; i < count; i++) {
        if (frozen[i]) {
          free -= targets[i];
        } else {
          free -= share;
          unfrozen += 1;
        }
      }
      // Every unfrozen action has the same basis and the same factor, so
      // growing and shrinking both hand the free width out evenly — and a
      // zero basis shrinks by nothing.
      final delta = grows || share > 0 ? free / unfrozen : 0.0;
      var violation = 0.0;
      final violators = <int>[];
      for (var i = 0; i < count; i++) {
        if (frozen[i]) continue;
        final target = share + delta;
        if (target < fits[i]) {
          targets[i] = fits[i];
          violation += fits[i] - target;
          violators.add(i);
        } else {
          targets[i] = target;
        }
      }
      if (violation > 0) {
        for (final i in violators) {
          frozen[i] = true;
        }
      } else {
        for (var i = 0; i < count; i++) {
          frozen[i] = true;
        }
      }
    }

    return targets;
  }

  static double _atLeastZero(double value) => value < 0 ? 0 : value;

  static double _min(double a, double b) => a < b ? a : b;

  static double _max(double a, double b) => a > b ? a : b;
}
