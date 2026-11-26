import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

// Carousel component animation and physics constants

/// 캐러셀의 크기 제약 (`CoreCarouselSizeConstraint` 의 Flutter 별칭).
///
/// 고정 픽셀 크기 또는 비율 기반 크기를 지원합니다. 타입 자체는
/// `coui_core` 에 있어 Web 캐러셀과 같은 값을 공유합니다.
typedef CarouselSizeConstraint = CoreCarouselSizeConstraint;

/// 고정 캐러셀 크기 제약 (`CoreCarouselFixedConstraint` 의 Flutter 별칭).
typedef CarouselFixedConstraint = CoreCarouselFixedConstraint;

/// 비율 기반 캐러셀 크기 제약
/// (`CoreCarouselFractionalConstraint` 의 Flutter 별칭).
typedef CarouselFractionalConstraint = CoreCarouselFractionalConstraint;

/// 캐러셀 아이템의 정렬 방식 (`CoreCarouselAlignment` 의 Flutter 별칭).
///
/// 뷰포트 내에서 캐러셀 아이템의 위치를 결정합니다.
typedef CarouselAlignment = CoreCarouselAlignment;

/// 캐러셀 전환 레이아웃.
///
/// `CoreCarouselTransition`(전환 모드 + 슬라이드 간격) 위에 Flutter
/// 렌더러의 슬라이드 배치([layout])를 얹은 추상 베이스 클래스입니다.
/// 모드와 간격은 Core 에 있으므로 Web 캐러셀이 같은 값을 읽어 같은
/// 전환을 그립니다.
abstract class CarouselTransition extends CoreCarouselTransition {
  /// 캐러셀 레이아웃을 생성합니다.
  const CarouselTransition();

  /// 슬라이딩 캐러셀 레이아웃을 생성합니다.
  ///
  /// [gap]은 아이템 사이의 간격입니다.
  const factory CarouselTransition.sliding({double gap}) =
      SlidingCarouselTransition;

  /// 페이딩 캐러셀 레이아웃을 생성합니다.
  ///
  /// 아이템 간 전환 시 페이드 인/아웃 효과를 사용합니다.
  const factory CarouselTransition.fading() = FadingCarouselTransition;

  /// 캐러셀 아이템을 레이아웃합니다.
  ///
  /// 매개변수:
  /// * [context]: 빌드 컨텍스트.
  /// * [progress]: 캐러셀의 진행 상태.
  /// * [constraints]: 캐러셀의 박스 제약.
  /// * [alignment]: 캐러셀의 정렬.
  /// * [direction]: 캐러셀의 방향 (수평/수직)
  /// * [sizeConstraint]: 캐러셀의 크기 제약.
  /// * [progressedIndex]: 진행된 인덱스.
  /// * [itemCount]: 아이템 수.
  /// * [itemBuilder]: 아이템 빌더.
  /// * [wrap]: 순환 여부.
  /// * [reverse]: 역방향 여부.
  List<Widget> layout(
    BuildContext context, {
    required CarouselAlignment alignment,
    required BoxConstraints constraints,
    required Axis direction,
    required CarouselItemBuilder itemBuilder,
    required int? itemCount,
    required double progress,
    required double progressedIndex,
    required bool reverse,
    required CarouselSizeConstraint sizeConstraint,
    required bool wrap,
  });
}

/// 슬라이딩 캐러셀 전환.
///
/// 아이템이 수평 또는 수직으로 슬라이드하며 전환되는 레이아웃입니다
/// 전통적인 캐러셀 동작을 제공합니다.
class SlidingCarouselTransition extends CarouselTransition {
  /// 슬라이딩 캐러셀 전환을 생성합니다.
  ///
  /// [gap]은 아이템 사이의 간격 (픽셀 단위)입니다.
  const SlidingCarouselTransition({this.gap = 0});

  /// 캐러셀 아이템 사이의 간격.
  ///
  /// 타입: `double`, 기본값: `0`. 아이템 사이에 추가할 픽셀 간격을 정의합니다.
  @override
  final double gap;

  @override
  CoreCarouselTransitionMode get mode => .sliding;

  @override
  List<Widget> layout(
    BuildContext context, {
    required CarouselAlignment alignment,
    required BoxConstraints constraints,
    required Axis direction,
    required CarouselItemBuilder itemBuilder,
    required int? itemCount,
    required double progress,
    required double progressedIndex,
    required bool reverse,
    required CarouselSizeConstraint sizeConstraint,
    required bool wrap,
  }) {
    var additionalPreviousItems = 1;
    var additionalNextItems = 1;
    final originalSize = direction == .horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    double size;
    if (sizeConstraint is CarouselFixedConstraint) {
      size = sizeConstraint.size;
    } else if (sizeConstraint is CarouselFractionalConstraint) {
      size = originalSize * sizeConstraint.fraction;
    } else {
      size = originalSize;
    }
    final snapOffsetAlignment = (originalSize - size) * alignment.alignment;
    final gapBeforeItem = snapOffsetAlignment;
    final gapAfterItem = originalSize - size - gapBeforeItem;
    additionalPreviousItems += max(0, (gapBeforeItem / size).ceil());
    additionalNextItems += max(0, (gapAfterItem / size).ceil());
    final items = <_PlacedCarouselItem>[];
    var start = progressedIndex.floor() - additionalPreviousItems;
    var end = progressedIndex.floor() + additionalNextItems;
    if (!wrap && itemCount != null) {
      start = start.clamp(0, itemCount - 1);
      end = end.clamp(0, itemCount - 1);
    }
    final currentIndex = progressedIndex + (gap / size) * progressedIndex;
    for (var i = start; i <= end; i += 1) {
      double index;
      index = itemCount != null
          ? wrapDouble(itemCount.toDouble(), 0, i.toDouble())
          : i.toDouble();
      final itemIndex = reverse ? (-index).toInt() : index.toInt();
      final item = itemBuilder(context, itemIndex);
      final position = i.toDouble();

      /// 간격 오프셋 적용.
      items.add(
        _PlacedCarouselItem._(
          position: position,
          relativeIndex: i,
          child: item,
        ),
      );
    }

    return direction == .horizontal
        ? [
            for (final item in items)
              Position(
                left:
                    snapOffsetAlignment +
                    (item.position - currentIndex) * size +
                    (gap * item.relativeIndex),
                width: size,
                height: constraints.maxHeight,
                child: item.child,
              ),
          ]
        : [
            for (final item in items)
              Position(
                top:
                    snapOffsetAlignment +
                    (item.position - currentIndex) * size +
                    (gap * item.relativeIndex),
                width: constraints.maxWidth,
                height: size,
                child: item.child,
              ),
          ];
  }
}

/// 페이딩 캐러셀 전환.
///
/// 아이템이 페이드 인/아웃으로 전환되는 레이아웃입니다
/// 부드러운 시각적 전환 효과를 제공합니다.
class FadingCarouselTransition extends CarouselTransition {
  /// 페이딩 캐러셀 전환을 생성합니다.
  const FadingCarouselTransition();

  @override
  double get gap => 0;

  @override
  CoreCarouselTransitionMode get mode => .fading;

  @override
  List<Widget> layout(
    BuildContext context, {
    required CarouselAlignment alignment,
    required BoxConstraints constraints,
    required Axis direction,
    required CarouselItemBuilder itemBuilder,
    required int? itemCount,
    required double progress,
    required double progressedIndex,
    required bool reverse,
    required CarouselSizeConstraint sizeConstraint,
    required bool wrap,
  }) {
    final originalSize = direction == .horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    double size;
    if (sizeConstraint is CarouselFixedConstraint) {
      size = sizeConstraint.size;
    } else if (sizeConstraint is CarouselFractionalConstraint) {
      size = originalSize * sizeConstraint.fraction;
    } else {
      size = originalSize;
    }
    final snapOffsetAlignment = (originalSize - size) * alignment.alignment;
    final items = <_PlacedCarouselItem>[];
    var start = progressedIndex.floor() - 1;
    var end = progressedIndex.floor() + 1;
    if (!wrap && itemCount != null) {
      start = start.clamp(0, itemCount - 1);
      end = end.clamp(0, itemCount - 1);
    }
    for (var i = start; i <= end; i += 1) {
      double index;
      index = itemCount != null
          ? wrapDouble(itemCount.toDouble(), 0, i.toDouble())
          : i.toDouble();
      final itemIndex = reverse ? (-index).toInt() : index.toInt();
      final item = itemBuilder(context, itemIndex);
      final position = i.toDouble();

      /// 간격 오프셋 적용.
      items.add(
        _PlacedCarouselItem._(
          position: position,
          relativeIndex: i,
          child: item,
        ),
      );
    }

    return direction == .horizontal
        ? [
            for (final item in items)
              Position(
                left: snapOffsetAlignment,
                width: size,
                height: constraints.maxHeight,
                child: Opacity(
                  opacity: (1 - (progress - item.position).abs()).clamp(
                    0.0,
                    1.0,
                  ),
                  child: item.child,
                ),
              ),
          ]
        : [
            for (final item in items)
              Position(
                top: snapOffsetAlignment,
                width: constraints.maxWidth,
                height: size,
                child: Opacity(
                  opacity: (1 - (progress - item.position).abs()).clamp(
                    0.0,
                    1.0,
                  ),
                  child: item.child,
                ),
              ),
          ];
  }
}

/// 캐러셀 아이템을 빌드합니다 (`CoreCarouselItemBuilder<Widget>` 의 별칭).
///
/// `index`는 아이템의 인덱스입니다. 순환 캐러셀에서는 음수일 수 있습니다.
/// `context` 는 `coui_core` 가 프레임워크 타입을 알 수 없어 `Object` 로
/// 선언되며, 실제로는 `BuildContext` 가 전달됩니다.
typedef CarouselItemBuilder = CoreCarouselItemBuilder<Widget>;

/// 인덱스별 자동 재생 간격을 계산합니다
/// (`CoreCarouselDurationBuilder` 의 별칭).
typedef CarouselDurationBuilder = CoreCarouselDurationBuilder;

/// 캐러셀의 컨트롤러.
///
/// 캐러셀의 프로그래밍적 제어를 제공합니다. 다음/이전 아이템으로 이동,
/// 특정 인덱스로 점프, 애니메이션 상태 관리 등을 지원합니다.
class CarouselController extends Listenable {
  final _controller = AnimationQueueController();

  /// 캐러셀이 애니메이션 중인지 여부.
  ///
  /// 타입: `bool`. 애니메이션이 진행 중이면 true를 반환합니다.
  bool get shouldAnimate => _controller.shouldTick;

  /// 컨트롤러의 현재 값.
  ///
  /// 타입: `double`. 현재 캐러셀 위치를 나타냅니다
  /// 정수 값은 정확한 아이템 위치를, 소수점은 전환 중인 위치를 나타냅니다.
  double get value => _controller.value;

  /// 다음 아이템으로 애니메이션합니다.
  ///
  /// [duration]은 애니메이션 지속 시간이고, [curve]는 이징 커브입니다.
  void animateNext(Duration duration, [Curve curve = Curves.easeInOut]) {
    _controller.push(
      AnimationRequest(
        (_controller.value + 1).roundToDouble(),
        duration,
        curve,
      ),
      false,
    );
  }

  /// 이전 아이템으로 애니메이션합니다.
  ///
  /// [duration]은 애니메이션 지속 시간이고, [curve]는 이징 커브입니다.
  void animatePrevious(Duration duration, [Curve curve = Curves.easeInOut]) {
    _controller.push(
      AnimationRequest(
        (_controller.value - 1).roundToDouble(),
        duration,
        curve,
      ),
      false,
    );
  }

  /// 현재 값을 가장 가까운 정수로 스냅합니다.
  ///
  /// 드래그 종료 후 가장 가까운 아이템에 정렬하는 데 사용됩니다.
  void animateSnap(Duration duration, [Curve curve = Curves.easeInOut]) {
    _controller.push(
      AnimationRequest(_controller.value.roundToDouble(), duration, curve),
    );
  }

  /// 지정된 값으로 즉시 이동합니다.
  ///
  /// 애니메이션 없이 즉시 위치를 변경합니다.
  void jumpTo(double value) {
    _controller.value = value;
  }

  /// 지정된 값으로 애니메이션합니다.
  ///
  /// [value]는 목표 위치, [duration]은 애니메이션 지속 시간,
  /// [curve]는 이징 커브입니다.
  void animateTo(
    double value,
    Duration duration, [
    Curve curve = Curves.linear,
  ]) {
    _controller.push(AnimationRequest(value, duration, curve), false);
  }

  /// 현재 인덱스를 가져옵니다.
  ///
  /// [itemCount]가 제공되면 순환 래핑을 적용합니다.
  double getCurrentIndex(int? itemCount) {
    return itemCount == null
        ? _controller.value
        : wrapDouble(itemCount.toDouble(), 0, _controller.value);
  }

  /// 애니메이션 틱을 수행합니다.
  ///
  /// [delta]는 마지막 틱 이후 경과 시간입니다.
  void tick(Duration delta) {
    _controller.tick(delta);
  }

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }
}

class _PlacedCarouselItem {
  const _PlacedCarouselItem._({
    required this.child,
    required this.position,
    required this.relativeIndex,
  });
  final int relativeIndex;
  final Widget child;

  final double position;
}
