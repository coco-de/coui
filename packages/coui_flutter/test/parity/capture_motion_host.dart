import 'package:flutter/widgets.dart';

import '../../../../tool/parity/src/model/capture_motion.dart';

/// Freeze the ticker before its first tick; font/image settling can then
/// advance the test clock without changing the sampled animation phase.
Widget captureMotionHost({required String component, required Widget child}) =>
    kFixedTimeCaptureComponents.contains(component)
    ? TickerMode(enabled: false, child: child)
    : child;
