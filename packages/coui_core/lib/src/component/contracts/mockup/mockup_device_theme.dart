import 'package:coui_core/src/component/contracts/mockup/mockup_device.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_finish.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MockupDevice`.
///
/// All fields flow through [style] (every device), [deviceStyles]
/// (per-[CoreMockupDevice]) and [finishStyles] (per-[CoreMockupDeviceFinish])
/// — [CoreMockupDeviceStyle] slots. The shared
/// `CoreMockupTheme.style` applies cross-variant defaults (background /
/// border / frame) for project-wide mockup recolouring.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreMockupTheme.style (shared cross-variant)
///   → CoreMockupDeviceTheme.style                     // 프로젝트 공통
///   → CoreMockupDeviceTheme.deviceStyles[device]      // 기기별
///   → CoreMockupDeviceTheme.finishStyles[finish]      // 마감별
///   → widget per-instance mockupDeviceStyle
/// ```
@immutable
class CoreMockupDeviceTheme {
  /// Creates a [CoreMockupDeviceTheme].
  const CoreMockupDeviceTheme({
    this.style,
    this.deviceStyles,
    this.finishStyles,
  });

  /// Project-wide composite style applied to every `MockupDevice`.
  ///
  /// Resolved before any per-instance `widget.mockupDeviceStyle`.
  final CoreMockupDeviceStyle? style;

  /// Per-[CoreMockupDevice] project-wide overrides (e.g. a different
  /// body radius for tablets only). Resolved after [style] and before
  /// any per-instance `widget.mockupDeviceStyle`.
  final Map<CoreMockupDevice, CoreMockupDeviceStyle>? deviceStyles;

  /// Per-[CoreMockupDeviceFinish] project-wide overrides (e.g. a different
  /// ring colour for every `flat` frame). Resolved after [deviceStyles] and
  /// before any per-instance `widget.mockupDeviceStyle`.
  final Map<CoreMockupDeviceFinish, CoreMockupDeviceStyle>? finishStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupDeviceTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(other.deviceStyles, deviceStyles) &&
          _mapEquals(other.finishStyles, finishStyles);

  @override
  int get hashCode => Object.hash(
    style,
    deviceStyles == null
        ? null
        : Object.hashAllUnordered(
            deviceStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
    finishStyles == null
        ? null
        : Object.hashAllUnordered(
            finishStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );
}

bool _mapEquals<K>(
  Map<K, CoreMockupDeviceStyle>? a,
  Map<K, CoreMockupDeviceStyle>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
