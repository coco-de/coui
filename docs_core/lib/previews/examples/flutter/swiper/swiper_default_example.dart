import 'package:coui_flutter/coui_flutter.dart';

/// Default Swiper example for docs_site Flutter preview.
///
/// Mirrors the shadcn_flutter demo: pick the edge with the position
/// buttons, then swipe the card toward the opposite direction (or tap
/// Open) to reveal the drawer-style overlay. The open panel inherits
/// the composed Drawer's slide animation and can be swiped shut.
class SwiperDefaultExample extends StatefulWidget {
  const SwiperDefaultExample({super.key});

  @override
  State<SwiperDefaultExample> createState() => _SwiperDefaultExampleState();
}

class _SwiperDefaultExampleState extends State<SwiperDefaultExample> {
  CoreSwiperPosition _position = CoreSwiperPosition.left;
  bool _open = false;

  Widget _positionButton(CoreSwiperPosition position, String label) {
    return Button(
      variant: _position == position ? .primary : .outline,
      size: .sm,
      onPressed: () => setState(() => _position = position),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Swiper(
      position: _position,
      open: _open,
      onOpenChanged: (isOpen) => setState(() => _open = isOpen),
      // Centered like the shadcn demo via `mainAxisAlignment` —
      // alignment is caller-owned (the drawer never centers content
      // itself). On the full-height left / right sides the column is
      // forced tall so the alignment centers; on content-sized
      // top / bottom sides the column wraps and it is a no-op.
      overlayContent: Padding(
        padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            const Text('대시보드'),
            const Text('설정'),
            const Text('프로필'),
            Button(
              variant: .outline,
              size: .sm,
              onPressed: () => setState(() => _open = false),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
      // The whole preview area is the swipe surface (the gesture layer
      // covers the Swiper child) — the card just labels it.
      child: SizedBox(
        width: double.infinity,
        height: CoreSpace.space256,
        child: Center(
          child: Card(
            child: Padding(
              padding: const CoreEdgeInsets.all(CoreSpace.space24).toValue(geometry: Theme.of(context).geometry),
              child: Column(
                mainAxisSize: .min,
                children: [
                  const Text('밀어 보세요!').titleMedium.onSurface,
                  const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
                  Join(
                    children: [
                      _positionButton(CoreSwiperPosition.left, '왼쪽'),
                      _positionButton(CoreSwiperPosition.right, '오른쪽'),
                      _positionButton(CoreSwiperPosition.top, '위'),
                      _positionButton(CoreSwiperPosition.bottom, '아래'),
                    ],
                  ),
                  const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
                  Button(
                    onPressed: () => setState(() => _open = true),
                    child: const Text('스와이퍼 열기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
