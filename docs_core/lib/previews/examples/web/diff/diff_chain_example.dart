import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDiffStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter than
/// a second `.withStyle(const CoreDiffStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class DiffChainExample extends StatelessComponent {
  const DiffChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Diff(
          ariaLabel: '보정 전과 보정 후 풍경 비교',
          beforeLabel: Text('전'),
          afterLabel: Text('후'),
          before: _Landscape(vivid: false),
          after: _Landscape(vivid: true),
        )
        .withStyle(
          const CoreDiffStyle(
            resizerColor: CoreColor.token(CoreColors.tertiary),
            resizerWidth: CoreStrokeWidth.stroke4,
            aspectRatio: 4 / 3,
          ),
        )
        .radius16;
  }
}

/// A sky, a sun and two hills drawn from colour tokens. Every size and
/// position is a fraction of the frame, so the scene scales with it.
class _Landscape extends StatelessComponent {
  const _Landscape({required this.vivid});

  /// Muted greys when false, the status colours when true.
  final bool vivid;

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final sky = vivid ? cs.infoContainer : cs.surfaceContainer;
    final sun = vivid ? cs.warning : cs.outlineVariant;
    final farHill = vivid ? cs.info : cs.outlineVariant;
    final nearHill = vivid ? cs.success : cs.outline;

    return div(
      [
        _disc(sun, left: '42%', top: '12%', size: '16%'),
        _disc(farHill, left: '-42%', top: '55%', size: '160%'),
        _disc(nearHill, left: '15%', top: '72%', size: '130%'),
      ],
      classes: 'relative w-full h-full overflow-hidden bg-$sky',
    );
  }

  Component _disc(
    CoreColor? color, {
    required String left,
    required String top,
    required String size,
  }) {
    return div(
      const [],
      classes: 'absolute rounded-${CoreRadius.scale.radius9999} bg-$color',
      styles: Styles(
        raw: {'left': left, 'top': top, 'width': size, 'aspect-ratio': '1'},
      ),
    );
  }
}
