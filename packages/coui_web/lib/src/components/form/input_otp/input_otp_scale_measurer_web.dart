/// Web implementation of [InputOtpScaleMeasurer].
///
/// Mirrors the Flutter twin's `FittedBox(fit: scaleDown, alignment:
/// centerLeft)` around the visual cell row: when the row's intrinsic
/// width exceeds the container's available width, the row is scaled
/// down proportionally (cells, gaps and glyphs together); once the
/// container is wide enough again the transform is removed and the row
/// renders at its natural size, left-aligned.
///
/// A [web.ResizeObserver] watches both the container and the row, so
/// the ratio re-evaluates on viewport resizes and on row content
/// changes. The scale is written as an imperative `transform` on the
/// row element — a CSS transform does not participate in layout, so
/// `offsetWidth` keeps reporting the untransformed intrinsic width and
/// the measurement never feeds back into itself.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web orchestrator for a single `InputOtp` visual row.
class InputOtpScaleMeasurer {
  /// Creates an [InputOtpScaleMeasurer].
  InputOtpScaleMeasurer({required this.rowId});

  /// `id` of the visual cell-row `<div>` (the transform target). The
  /// available width is read from its parent element (the group root).
  final String rowId;

  web.HTMLElement? _row;
  web.ResizeObserver? _resizeObserver;

  /// Resolves the row, attaches a [web.ResizeObserver] to the row and
  /// its parent, and applies the initial scale state. Idempotent.
  void attach() {
    if (_row != null) return;
    final row = web.document.getElementById(rowId);
    final parent = row?.parentElement;
    if (row == null || parent == null) return;
    _row = row as web.HTMLElement;

    _resizeObserver = web.ResizeObserver(_handleResize.toJS)
      ..observe(parent)
      ..observe(_row!);

    _applyScale();
  }

  /// Disconnects the observer and clears the transform. Idempotent.
  void dispose() {
    _resizeObserver?.disconnect();
    _resizeObserver = null;
    final row = _row;
    if (row != null) {
      final _ = row.style.removeProperty('transform');
      final _ = row.style.removeProperty('transform-origin');
    }
    _row = null;
  }

  void _handleResize(JSAny entries, JSAny observer) {
    _applyScale();
  }

  void _applyScale() {
    final row = _row;
    final parent = row?.parentElement;
    if (row == null || parent == null) return;
    final available = parent.clientWidth;
    // `offsetWidth` ignores the transform — always the intrinsic width.
    final intrinsic = row.offsetWidth;
    if (available <= 0 || intrinsic <= 0) return;
    if (intrinsic > available) {
      row.style.transform = 'scale(${available / intrinsic})';
      row.style.transformOrigin = 'left center';
    } else {
      final _ = row.style.removeProperty('transform');
      final _ = row.style.removeProperty('transform-origin');
    }
  }
}
