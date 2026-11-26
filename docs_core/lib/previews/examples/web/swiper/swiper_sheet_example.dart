import 'package:coui_web/coui_web.dart';

/// Sheet-variant Swiper example — minimal edge-to-edge surface.
///
/// Mirrors the shadcn_flutter demo: pick the edge with the position
/// buttons, then swipe the card toward the opposite direction (or tap
/// Open) to reveal the drawer-style overlay. The open panel inherits
/// the composed Drawer's slide animation and can be swiped shut.
class SwiperSheetExample extends StatefulComponent {
  const SwiperSheetExample({super.key});

  @override
  State<SwiperSheetExample> createState() => _SwiperSheetExampleState();
}

class _SwiperSheetExampleState extends State<SwiperSheetExample> {
  CoreSwiperPosition _position = CoreSwiperPosition.left;
  bool _open = false;

  Component _positionButton(CoreSwiperPosition position, String label) {
    return Button(
      variant: _position == position ? .primary : .outline,
      size: .sm,
      onPressed: () => setState(() => _position = position),
      child: Text(label),
    );
  }

  @override
  Component build(BuildContext context) {
    return Swiper(
      variant: CoreSwiperVariant.sheet,
      position: _position,
      open: _open,
      onOpenChanged: (isOpen) => setState(() => _open = isOpen),
      // Centered like the shadcn demo via `justify-center` —
      // alignment is caller-owned (the drawer never centers content
      // itself). On the full-height left / right sides `h-full` gives
      // the column room so the content centers; on content-sized
      // top / bottom sides it resolves to auto and is a no-op.
      overlayContent: div(
        classes:
            'flex h-full flex-col items-start justify-center '
            'gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
        [
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
      // The whole preview area is the swipe surface (the gesture layer
      // covers the Swiper child) — the card just labels it.
      child: div(
        classes: 'flex w-full items-center justify-center',
        styles: Styles(
          raw: {'min-height': 'var(--coui-space-${CoreSpace.space256.toInt()})'},
        ),
        [
          Card(
            child: div(
              classes:
                  'flex flex-col items-center gap-${CoreSpace.scale.space12} '
                  'p-${CoreSpace.scale.space24}',
              [
                const Text('밀어 보세요!').titleMedium.onSurface,
                Join(
                  children: [
                    _positionButton(CoreSwiperPosition.left, '왼쪽'),
                    _positionButton(CoreSwiperPosition.right, '오른쪽'),
                    _positionButton(CoreSwiperPosition.top, '위'),
                    _positionButton(CoreSwiperPosition.bottom, '아래'),
                  ],
                ),
                Button(
                  onPressed: () => setState(() => _open = true),
                  child: const Text('스와이퍼 열기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
