import 'package:coui_web/src/base/styling.dart';

/// Marker interface for any utility that can be passed to a Skeleton's `style` list.
abstract class _SkeletonStyling implements Styling {}

/// Public interface for SkeletonStyling.
typedef SkeletonStyling = _SkeletonStyling;
