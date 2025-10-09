import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for [ScrollableClient].
class ScrollableClientTheme {
  const ScrollableClientTheme({
    this.clipBehavior,
    this.diagonalDragBehavior,
    this.dragStartBehavior,
    this.hitTestBehavior,
    this.keyboardDismissBehavior,
    this.overscroll,
  });

  final DiagonalDragBehavior? diagonalDragBehavior;
  final DragStartBehavior? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final Clip? clipBehavior;
  final HitTestBehavior? hitTestBehavior;

  final bool? overscroll;

  @override
  bool operator ==(Object other) =>
      other is ScrollableClientTheme &&
      other.diagonalDragBehavior == diagonalDragBehavior &&
      other.dragStartBehavior == dragStartBehavior &&
      other.keyboardDismissBehavior == keyboardDismissBehavior &&
      other.clipBehavior == clipBehavior &&
      other.hitTestBehavior == hitTestBehavior &&
      other.overscroll == overscroll;

  @override
  String toString() =>
      'ScrollableClientTheme(diagonalDragBehavior: $diagonalDragBehavior, dragStartBehavior: $dragStartBehavior, keyboardDismissBehavior: $keyboardDismissBehavior, clipBehavior: $clipBehavior, hitTestBehavior: $hitTestBehavior, overscroll: $overscroll)';

  @override
  int get hashCode => Object.hash(
    diagonalDragBehavior,
    dragStartBehavior,
    keyboardDismissBehavior,
    clipBehavior,
    hitTestBehavior,
    overscroll,
  );
}

typedef ScrollableBuilder =
    Widget Function(
      BuildContext context,
      Offset offset,
      Size viewportSize,
      Widget? child,
    );

class ScrollableClient extends StatelessWidget {
  const ScrollableClient({
    required this.builder,
    this.child,
    this.clipBehavior,
    this.diagonalDragBehavior,
    this.dragStartBehavior,
    this.hitTestBehavior,
    this.horizontalDetails = const ScrollableDetails.horizontal(),
    super.key,
    this.keyboardDismissBehavior,
    this.mainAxis = Axis.vertical,
    this.overscroll,
    this.primary,
    this.verticalDetails = const ScrollableDetails.vertical(),
  });

  final bool? primary;
  final Axis mainAxis;
  final ScrollableDetails verticalDetails;
  final ScrollableDetails horizontalDetails;
  final ScrollableBuilder builder;
  final Widget? child;
  final DiagonalDragBehavior? diagonalDragBehavior;
  final DragStartBehavior? dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final Clip? clipBehavior;
  final HitTestBehavior? hitTestBehavior;

  final bool? overscroll;

  Widget _buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
    bool overscroll,
    Clip clipBehavior,
  ) {
    return ScrollableClientViewport(
      clipBehavior: clipBehavior,
      delegate: TwoDimensionalChildBuilderDelegate(
        builder: (context, vicinity) {
          return ListenableBuilder(
            listenable: Listenable.merge([verticalOffset, horizontalOffset]),
            builder: (context, child) {
              final horizontalPixels = horizontalOffset.pixels;
              final verticalPixels = verticalOffset.pixels;

              return builder(
                context,
                Offset(horizontalPixels, verticalPixels),
                (vicinity as _ScrollableClientChildVicinity).viewportSize,
                child,
              );
            },
            child: child,
          );
        },
      ),
      horizontalAxisDirection: horizontalDetails.direction,
      horizontalOffset: horizontalOffset,
      mainAxis: mainAxis,
      overscroll: overscroll,
      verticalAxisDirection: verticalDetails.direction,
      verticalOffset: verticalOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      axisDirectionToAxis(verticalDetails.direction) == Axis.vertical,
      'TwoDimensionalScrollView.verticalDetails are not Axis.vertical.',
    );
    assert(
      axisDirectionToAxis(horizontalDetails.direction) == Axis.horizontal,
      'TwoDimensionalScrollView.horizontalDetails are not Axis.horizontal.',
    );

    final compTheme = ComponentTheme.maybeOf<ScrollableClientTheme>(context);
    final diag =
        diagonalDragBehavior ??
        compTheme?.diagonalDragBehavior ??
        DiagonalDragBehavior.none;
    final dragStart =
        dragStartBehavior ??
        compTheme?.dragStartBehavior ??
        DragStartBehavior.start;
    final keyboardDismiss =
        keyboardDismissBehavior ??
        compTheme?.keyboardDismissBehavior ??
        ScrollViewKeyboardDismissBehavior.manual;
    final clip = clipBehavior ?? compTheme?.clipBehavior ?? Clip.hardEdge;
    final hitTest =
        hitTestBehavior ?? compTheme?.hitTestBehavior ?? HitTestBehavior.opaque;
    final overscroll = this.overscroll ?? compTheme?.overscroll ?? false;

    ScrollableDetails mainAxisDetails = switch (mainAxis) {
      Axis.vertical => verticalDetails,
      Axis.horizontal => horizontalDetails,
    };

    final effectivePrimary =
        primary ??
        mainAxisDetails.controller == null &&
            PrimaryScrollController.shouldInherit(context, mainAxis);

    if (effectivePrimary) {
      // Using PrimaryScrollController for mainAxis.
      assert(
        mainAxisDetails.controller == null,
        'TwoDimensionalScrollView.primary was explicitly set to true, but a '
        'ScrollController was provided in the ScrollableDetails of the '
        'TwoDimensionalScrollView.mainAxis.',
      );
      mainAxisDetails = mainAxisDetails.copyWith(
        controller: PrimaryScrollController.of(context),
      );
    }

    final scrollable = TwoDimensionalScrollable(
      horizontalDetails: switch (mainAxis) {
        Axis.horizontal => mainAxisDetails,
        Axis.vertical => horizontalDetails,
      },
      verticalDetails: switch (mainAxis) {
        Axis.vertical => mainAxisDetails,
        Axis.horizontal => verticalDetails,
      },
      viewportBuilder: (context, vOffset, hOffset) =>
          _buildViewport(context, vOffset, hOffset, overscroll, clip),
      diagonalDragBehavior: diag,
      dragStartBehavior: dragStart,
      hitTestBehavior: hitTest,
    );

    final scrollableResult = effectivePrimary
        // Further descendant ScrollViews will not inherit the same PrimaryScrollController
        ? PrimaryScrollController.none(child: scrollable)
        : scrollable;

    return keyboardDismiss == ScrollViewKeyboardDismissBehavior.onDrag
        ? NotificationListener<ScrollUpdateNotification>(
            onNotification: (ScrollUpdateNotification notification) {
              final currentScope = FocusScope.of(context);
              if (notification.dragDetails != null &&
                  !currentScope.hasPrimaryFocus &&
                  currentScope.hasFocus) {
                FocusManager.instance.primaryFocus?.unfocus();
              }

              return false;
            },
            child: scrollableResult,
          )
        : scrollableResult;
  }
}

class ScrollableClientViewport extends TwoDimensionalViewport {
  const ScrollableClientViewport({
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    required super.delegate,
    required super.horizontalAxisDirection,
    required super.horizontalOffset,
    super.key,
    required super.mainAxis,
    required this.overscroll,
    required super.verticalAxisDirection,
    required super.verticalOffset,
  });

  final bool overscroll;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderScrollableClientViewport(
      cacheExtent: cacheExtent,
      childManager: context as TwoDimensionalChildManager,
      clipBehavior: clipBehavior,
      delegate: delegate,
      horizontalAxisDirection: horizontalAxisDirection,
      horizontalOffset: horizontalOffset,
      mainAxis: mainAxis,
      overscroll: overscroll,
      verticalAxisDirection: verticalAxisDirection,
      verticalOffset: verticalOffset,
    );
  }
}

class RenderScrollableClientViewport extends RenderTwoDimensionalViewport {
  RenderScrollableClientViewport({
    super.cacheExtent,
    required super.childManager,
    super.clipBehavior = Clip.hardEdge,
    required super.delegate,
    required super.horizontalAxisDirection,
    required super.horizontalOffset,
    required super.mainAxis,
    required this.overscroll,
    required super.verticalAxisDirection,
    required super.verticalOffset,
  });

  final bool overscroll;

  @override
  void layoutChildSequence() {
    double horizontalPixels = horizontalOffset.pixels;
    double verticalPixels = verticalOffset.pixels;
    final viewportDimension = this.viewportDimension;
    final vicinity = _ScrollableClientChildVicinity(
      viewportSize: viewportDimension,
      xIndex: 0,
      yIndex: 0,
    );
    final child = buildOrObtainChildFor(vicinity)!;
    child.layout(
      BoxConstraints(
        minWidth: constraints.maxWidth,
        minHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );
    if (!overscroll) {
      horizontalPixels = max(0, horizontalPixels);
      verticalPixels = max(0, verticalPixels);
      final maxHorizontalPixels = child.size.width - viewportDimension.width;
      final maxVerticalPixels = child.size.height - viewportDimension.height;
      horizontalPixels = min(horizontalPixels, maxHorizontalPixels);
      verticalPixels = min(verticalPixels, maxVerticalPixels);
    }
    parentDataOf(child).layoutOffset = Offset(
      -horizontalPixels,
      -verticalPixels,
    );
    horizontalOffset.applyContentDimensions(
      0,
      (child.size.width - viewportDimension.width).clamp(0.0, double.infinity),
    );
    verticalOffset.applyContentDimensions(
      0,
      (child.size.height - viewportDimension.height).clamp(
        0.0,
        double.infinity,
      ),
    );
    horizontalOffset.applyViewportDimension(viewportDimension.width);
    verticalOffset.applyViewportDimension(viewportDimension.height);
  }
}

class _ScrollableClientChildVicinity extends ChildVicinity {
  const _ScrollableClientChildVicinity({
    required this.viewportSize,
    required super.xIndex,
    required super.yIndex,
  });
  final Size viewportSize;
}
