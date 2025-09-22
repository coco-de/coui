// ignore_for_file: format-comment, member-ordering
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class Alignment extends CommonStyle<Alignment> {
  // stretch

  const Alignment(super.cssClass, {super.modifiers})
    : super(type: StyleType.layout);
  // Justify content - Controls how flex and grid items are positioned
  // along container's main axis
  static const justifyStart = Alignment('justify-start'); // flex-start

  static const justifyEnd = Alignment('justify-end'); // flex-end
  static const justifyCenter = Alignment('justify-center'); // center
  static const justifyBetween = Alignment('justify-between'); // space-between
  static const justifyAround = Alignment('justify-around'); // space-around
  static const justifyEvenly = Alignment('justify-evenly'); // space-evenly
  static const justifyStretch = Alignment('justify-stretch'); // stretch
  static const justifyBaseline = Alignment('justify-baseline'); // baseline
  static const justifyNormal = Alignment('justify-normal'); // normal

  // Utilities for controlling how grid items are aligned along their
  // inline axis.
  static const justifyItemsStart = Alignment('justify-items-start'); // start

  static const justifyItemsEnd = Alignment('justify-items-end'); // end
  static const justifyItemsCenter = Alignment('justify-items-center'); // center
  static const justifyItemsStretch = Alignment(
    'justify-items-stretch',
  ); // stretch
  static const justifyItemsNormal = Alignment('justify-items-normal'); // normal

  // Controls how an individual flex or grid item is justified
  // along its inline axis relative to its container
  static const justifySelfAuto = Alignment('justify-self-auto'); // auto

  static const justifySelfStart = Alignment('justify-self-start'); // start
  static const justifySelfEnd = Alignment('justify-self-end'); // end
  static const justifySelfCenter = Alignment('justify-self-center'); // center
  static const justifySelfStretch = Alignment(
    'justify-self-stretch',
  ); // stretch

  // Controls alignment of wrapped lines in flex containers
  // and alignment of grid tracks in grid containers
  static const contentNormal = Alignment('content-normal'); // normal

  static const contentCenter = Alignment('content-center'); // center
  static const contentStart = Alignment('content-start'); // flex-start
  static const contentEnd = Alignment('content-end'); // flex-end
  static const contentBetween = Alignment('content-between'); // space-between
  static const contentAround = Alignment('content-around'); // space-around
  static const contentEvenly = Alignment('content-evenly'); // space-evenly
  static const contentBaseline = Alignment('content-baseline'); // baseline
  static const contentStretch = Alignment('content-stretch'); // stretch

  // Controls how flex and grid items are positioned
  // along a container's cross axis
  static const itemsStart = Alignment('items-start'); // flex-start

  static const itemsEnd = Alignment('items-end'); // flex-end
  static const itemsCenter = Alignment('items-center'); // center
  static const itemsBaseline = Alignment('items-baseline'); // baseline
  static const itemsStretch = Alignment('items-stretch'); // stretch

  // Controls how an individual flex or grid item is aligned
  // along its cross axis relative to its container
  static const alignSelfAuto = Alignment('self-auto'); // auto

  static const alignSelfStart = Alignment('self-start'); // flex-start
  static const alignSelfEnd = Alignment('self-end'); // flex-end
  static const alignSelfCenter = Alignment('self-center'); // center
  static const alignSelfStretch = Alignment('self-stretch'); // stretch
  static const alignSelfBaseline = Alignment('self-baseline'); // baseline

  // Controls alignment of grid and flexbox content in both directions
  // simultaneously
  // Shorthand for align-content and justify-content
  static const placeContentCenter = Alignment('place-content-center'); // center

  static const placeContentStart = Alignment('place-content-start'); // start
  static const placeContentEnd = Alignment('place-content-end'); // end
  static const placeContentBetween = Alignment(
    'place-content-between',
  ); // space-between
  static const placeContentAround = Alignment(
    'place-content-around',
  ); // space-around
  static const placeContentEvenly = Alignment(
    'place-content-evenly',
  ); // space-evenly
  static const placeContentBaseline = Alignment(
    'place-content-baseline',
  ); // baseline
  static const placeContentStretch = Alignment(
    'place-content-stretch',
  ); // stretch

  // Controls how items are placed on both axes at once,
  // shorthand for align-items and justify-items
  static const placeItemsStart = Alignment('place-items-start'); // start

  static const placeItemsEnd = Alignment('place-items-end'); // end
  static const placeItemsCenter = Alignment('place-items-center'); // center
  static const placeItemsBaseline = Alignment(
    'place-items-baseline',
  ); // baseline
  static const placeItemsStretch = Alignment('place-items-stretch'); // stretch

  // Controls how an individual flex or grid item is justified and aligned
  // Shorthand for align-self and justify-self properties
  static const placeSelfAuto = Alignment('place-self-auto'); // auto

  static const placeSelfStart = Alignment('place-self-start'); // start
  static const placeSelfEnd = Alignment('place-self-end'); // end
  static const placeSelfCenter = Alignment('place-self-center'); // center
  static const placeSelfStretch = Alignment('place-self-stretch');

  @override
  Alignment create(List<PrefixModifier> modifiers) {
    return Alignment(cssClass, modifiers: modifiers);
  }
}
