import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Marker interface for any utility that can be passed to a Skeleton's `style` list.
abstract class _SkeletonStyling implements Styling {}

/// Public interface for SkeletonStyling.
typedef SkeletonStyling = _SkeletonStyling;
