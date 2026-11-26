import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDiffStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter than
/// a second `.withStyle(const CoreDiffStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class DiffChainExample extends StatelessWidget {
  const DiffChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
class _Landscape extends StatelessWidget {
  const _Landscape({required this.vivid});

  /// Muted greys when false, the status colours when true.
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sky = (vivid ? colors.infoContainer : colors.surfaceContainer).toValue();
    final sun = (vivid ? colors.warning : colors.outlineVariant).toValue();
    final farHill = (vivid ? colors.info : colors.outlineVariant).toValue();
    final nearHill = (vivid ? colors.success : colors.outline).toValue();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stacks(
          children: [
            Position.fill(child: ColoredBox(color: sky)),
            Position(
              left: width * 0.42,
              top: height * 0.12,
              width: width * 0.16,
              height: width * 0.16,
              child: ClipOval(child: ColoredBox(color: sun)),
            ),
            Position(
              left: width * -0.42,
              top: height * 0.55,
              width: width * 1.6,
              height: width * 1.6,
              child: ClipOval(child: ColoredBox(color: farHill)),
            ),
            Position(
              left: width * 0.15,
              top: height * 0.72,
              width: width * 1.3,
              height: width * 1.3,
              child: ClipOval(child: ColoredBox(color: nearHill)),
            ),
          ],
        );
      },
    );
  }
}
