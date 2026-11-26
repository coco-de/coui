/// Derived geometry for the status bar a `MockupDevice` draws over the top of
/// its screen.
library;

import 'dart:math' as math;

import 'package:coui_core/src/component/contracts/frame/core_main_axis_alignment.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_rect.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_style.dart';
import 'package:coui_core/src/shape/vector_glyph.dart';
import 'package:meta/meta.dart';

/// One thing a status bar group draws.
///
/// Lengths are in unscaled logical px — the status bar's iOS lengths already
/// multiplied by `CoreMockupDeviceLayout.systemBarScale`. A group lays its
/// items out in a row in order, [gapAfter] apart; a platform flows them (a
/// `Row`, a flexbox, an auto-layout frame) because the width of a text item is
/// the platform's to measure.
@immutable
sealed class CoreMockupStatusBarItem {
  const CoreMockupStatusBarItem({required this.gapAfter});

  /// Space between this item and the next one in its group (logical px); `0`
  /// for the last item.
  final double gapAfter;
}

/// A piece of sample text — the clock, the date or the battery percentage —
/// set in the status bar's text style.
///
/// It has no width here: how wide "9:41" is depends on the font the platform
/// sets it in.
final class CoreMockupStatusBarText extends CoreMockupStatusBarItem {
  /// Creates a [CoreMockupStatusBarText].
  const CoreMockupStatusBarText({required this.text, required super.gapAfter});

  /// What the text says.
  final String text;
}

/// A vector glyph filling a [width] × [height] box (logical px); the path is
/// scaled from the glyph's own box to it.
final class CoreMockupStatusBarGlyph extends CoreMockupStatusBarItem {
  /// Creates a [CoreMockupStatusBarGlyph].
  const CoreMockupStatusBarGlyph({
    required this.glyph,
    required this.width,
    required this.height,
    required super.gapAfter,
  });

  /// The drawing.
  final CoreVectorGlyph glyph;

  /// Width of the box the glyph fills (logical px).
  final double width;

  /// Height of the box the glyph fills (logical px).
  final double height;
}

/// The phone's battery: an outline, a level inside it and a nub beside it, all
/// in one [width] × [height] box.
///
/// The nub is a drawing; the outline and the level are plain rounded
/// rectangles. Every rectangle is relative to the battery box's own top-left.
final class CoreMockupStatusBarBattery extends CoreMockupStatusBarItem {
  /// Creates a [CoreMockupStatusBarBattery].
  const CoreMockupStatusBarBattery({
    required this.width,
    required this.height,
    required this.border,
    required this.borderWidth,
    required this.borderRadius,
    required this.capacity,
    required this.capacityRadius,
    required this.cap,
    required this.capGlyph,
    required super.gapAfter,
  });

  /// Width of the whole battery — outline, gap and nub (logical px).
  final double width;

  /// Height of the whole battery (logical px).
  final double height;

  /// The outline's box. Its stroke is drawn inside it.
  final CoreMockupDeviceRect border;

  /// The outline's stroke width (logical px).
  final double borderWidth;

  /// The outline's corner radius (logical px).
  final double borderRadius;

  /// The level's box — the outline's box shrunk evenly.
  final CoreMockupDeviceRect capacity;

  /// The level's corner radius (logical px).
  final double capacityRadius;

  /// The nub's box.
  final CoreMockupDeviceRect cap;

  /// The nub's drawing, filled into [cap].
  final CoreVectorGlyph capGlyph;
}

/// A row of status bar items and the area it lays out in.
@immutable
final class CoreMockupStatusBarGroup {
  /// Creates a [CoreMockupStatusBarGroup].
  const CoreMockupStatusBarGroup({
    required this.box,
    required this.alignment,
    required this.items,
  });

  /// The area (screen-space) the row is laid out in. It is symmetric about
  /// [CoreMockupStatusBarLayout.contentCenter], so centring the row vertically
  /// in it puts every item on that line.
  final CoreMockupDeviceRect box;

  /// Where along [box]'s width the row sits: `start`, `center` or `end`. A
  /// device whose groups hug the screen edges aligns its two groups to the
  /// two ends of one box — space between; a device with wings centres each in
  /// its own.
  final CoreMainAxisAlignment alignment;

  /// The row's items, first to last.
  final List<CoreMockupStatusBarItem> items;
}

/// The status bar over the top of a `MockupDevice` screen.
///
/// Authored in iOS points and drawn at `scale` of them — the mockup is a
/// small picture of a real screen, so the clock is a fraction of a real
/// clock's size. Everything here is already in unscaled logical px,
/// screen-space (origin at the screen's top-left).
@immutable
final class CoreMockupStatusBarLayout {
  const CoreMockupStatusBarLayout._({
    required this.rect,
    required this.scale,
    required this.contentCenter,
    required this.leading,
    required this.trailing,
  });

  /// Computes the status bar from settled values.
  ///
  /// [scale] turns iOS points into logical px; every other length is in
  /// points. A device with wings ([wingWidth] above `0`) centres its groups
  /// in fixed-width boxes anchored to each screen edge. One without wings
  /// hugs the two edges with its content.
  factory CoreMockupStatusBarLayout.compute({
    required CoreMockupDevice device,
    required double screenWidth,
    required double scale,
    required double height,
    required double inset,
    required double contentCenter,
    required double wingWidth,
    required double trailingInset,
    required double trailingSpacing,
    required double clockSpacing,
    required double leadingSpacing,
  }) {
    final barHeight = height * scale;
    final centerY = contentCenter * scale;
    // The part of the bar symmetric about the content line, reaching the
    // nearer of the bar's two edges.
    final half = math.max<double>(
      math.min(centerY, barHeight - centerY),
      0,
    );
    final boxTop = centerY - half;
    final boxHeight = half * 2;
    final edge = inset * scale;

    final CoreMockupDeviceRect leadingBox;
    final CoreMockupDeviceRect trailingBox;
    final CoreMainAxisAlignment leadingAlignment;
    final CoreMainAxisAlignment trailingAlignment;
    if (wingWidth > 0) {
      // Each group is centred in a wing: the leading wing is wingWidth wide
      // at the leading edge, the trailing one wingWidth minus its extra outer
      // inset, at the trailing edge.
      final wing = wingWidth * scale;
      leadingBox = (left: edge, top: boxTop, width: wing, height: boxHeight);
      trailingBox = (
        left: screenWidth - edge - wing,
        top: boxTop,
        width: math.max<double>(wing - trailingInset * scale, 0),
        height: boxHeight,
      );
      leadingAlignment = CoreMainAxisAlignment.center;
      trailingAlignment = CoreMainAxisAlignment.center;
    } else {
      // One box between the two insets; the groups are pushed to its ends.
      final box = (
        left: edge,
        top: boxTop,
        width: math.max<double>(screenWidth - edge * 2, 0),
        height: boxHeight,
      );
      leadingBox = box;
      trailingBox = box;
      leadingAlignment = CoreMainAxisAlignment.start;
      trailingAlignment = CoreMainAxisAlignment.end;
    }

    CoreMockupStatusBarGlyph glyphItem(CoreVectorGlyph glyph, double gap) =>
        CoreMockupStatusBarGlyph(
          glyph: glyph,
          width: glyph.width * scale,
          height: glyph.height * scale,
          gapAfter: gap * scale,
        );

    final leadingItems = switch (device) {
      .phone => <CoreMockupStatusBarItem>[
        const CoreMockupStatusBarText(
          text: CoreMockupDeviceStyle.sampleTime,
          gapAfter: 0,
        ),
      ],
      .tablet => <CoreMockupStatusBarItem>[
        CoreMockupStatusBarText(
          text: CoreMockupDeviceStyle.sampleTime,
          gapAfter: clockSpacing * scale,
        ),
        CoreMockupStatusBarText(
          text: CoreMockupDeviceStyle.sampleMeridiem,
          gapAfter: leadingSpacing * scale,
        ),
        const CoreMockupStatusBarText(
          text: CoreMockupDeviceStyle.sampleDate,
          gapAfter: 0,
        ),
      ],
    };
    final trailingItems = switch (device) {
      .phone => <CoreMockupStatusBarItem>[
        glyphItem(CoreMockupDeviceStyle.phoneCellularGlyph, trailingSpacing),
        glyphItem(CoreMockupDeviceStyle.phoneWifiGlyph, trailingSpacing),
        _phoneBattery(scale),
      ],
      .tablet => <CoreMockupStatusBarItem>[
        glyphItem(CoreMockupDeviceStyle.tabletWifiGlyph, trailingSpacing),
        CoreMockupStatusBarText(
          text: CoreMockupDeviceStyle.sampleBatteryLevel,
          gapAfter: trailingSpacing * scale,
        ),
        glyphItem(CoreMockupDeviceStyle.tabletBatteryGlyph, 0),
      ],
    };

    return CoreMockupStatusBarLayout._(
      rect: (left: 0, top: 0, width: screenWidth, height: barHeight),
      scale: scale,
      contentCenter: centerY,
      leading: CoreMockupStatusBarGroup(
        box: leadingBox,
        alignment: leadingAlignment,
        items: leadingItems,
      ),
      trailing: CoreMockupStatusBarGroup(
        box: trailingBox,
        alignment: trailingAlignment,
        items: trailingItems,
      ),
    );
  }

  /// The phone's three-part battery at [scale].
  static CoreMockupStatusBarBattery _phoneBattery(double scale) {
    const width = CoreMockupDeviceStyle.phoneBatteryWidth;
    const height = CoreMockupDeviceStyle.phoneBatteryHeight;
    const inset = CoreMockupDeviceStyle.phoneBatteryCapacityInset;
    const cap = CoreMockupDeviceStyle.phoneBatteryCapGlyph;
    return CoreMockupStatusBarBattery(
      width:
          (width + CoreMockupDeviceStyle.phoneBatteryCapGap + cap.width) *
          scale,
      height: height * scale,
      border: (left: 0, top: 0, width: width * scale, height: height * scale),
      borderWidth: CoreMockupDeviceStyle.phoneBatteryBorderWidth * scale,
      borderRadius: CoreMockupDeviceStyle.phoneBatteryRadius * scale,
      capacity: (
        left: inset * scale,
        top: inset * scale,
        width: (width - inset * 2) * scale,
        height: (height - inset * 2) * scale,
      ),
      capacityRadius: CoreMockupDeviceStyle.phoneBatteryCapacityRadius * scale,
      cap: (
        left: (width + CoreMockupDeviceStyle.phoneBatteryCapGap) * scale,
        top: CoreMockupDeviceStyle.phoneBatteryCapOffset * scale,
        width: cap.width * scale,
        height: cap.height * scale,
      ),
      capGlyph: cap,
      gapAfter: 0,
    );
  }

  /// The whole bar (screen-space) — full screen width, flush with the top
  /// edge. Its background is the screen's own.
  final CoreMockupDeviceRect rect;

  /// Logical px per iOS point — the same factor the gesture bar is drawn at.
  /// A platform scales the status bar's text style by it: the role's font
  /// size shrinks with it, while its tracking and leading, being ratios,
  /// follow the size on their own.
  final double scale;

  /// The line every group's items are centred on, as a distance below the
  /// top of the screen (logical px).
  final double contentCenter;

  /// The group at the leading edge — the clock.
  final CoreMockupStatusBarGroup leading;

  /// The group at the trailing edge — the signal, wifi and battery.
  final CoreMockupStatusBarGroup trailing;
}
