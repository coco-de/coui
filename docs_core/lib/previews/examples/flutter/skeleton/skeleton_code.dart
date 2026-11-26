/// Returns a Flutter code snippet string for the Skeleton component.
String skeletonCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SkeletonChainExample extends StatefulWidget {
  const SkeletonChainExample({super.key});

  @override
  State<SkeletonChainExample> createState() => _SkeletonChainExampleState();
}

class _SkeletonChainExampleState extends State<SkeletonChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Skeleton(width: 200, height: 20).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(fromOpacity)까지 한 번에.
        const Skeleton(width: 200, height: 20).withStyle(
          const CoreSkeletonStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            fromOpacity: CoreOpacity.opacity20,
          ),
        ),
      ],
    );
  }
}''',
    'circle' =>
      '''
class SkeletonCircleExample extends StatefulWidget {
  const SkeletonCircleExample({super.key});

  @override
  State<SkeletonCircleExample> createState() => _SkeletonCircleExampleState();
}

class _SkeletonCircleExampleState extends State<SkeletonCircleExample> {
  @override
  Widget build(BuildContext context) {
    return const Skeleton.circle(size: 48);
  }
}''',
    'text' =>
      '''
class SkeletonTextExample extends StatefulWidget {
  const SkeletonTextExample({super.key});

  @override
  State<SkeletonTextExample> createState() => _SkeletonTextExampleState();
}

class _SkeletonTextExampleState extends State<SkeletonTextExample> {
  @override
  Widget build(BuildContext context) {
    return const Skeleton.text(
      skeletonStyle: CoreSkeletonStyle(lines: 3),
    );
  }
}''',
    _ =>
      '''
class SkeletonDefaultExample extends StatefulWidget {
  const SkeletonDefaultExample({super.key});

  @override
  State<SkeletonDefaultExample> createState() => _SkeletonDefaultExampleState();
}

class _SkeletonDefaultExampleState extends State<SkeletonDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Theme.of(context).geometry.space(CoreSpace.space8),
      children: [
        Skeleton(width: 200, height: 20),
        Skeleton(width: 150, height: 20),
        Skeleton(width: 180, height: 20),
      ],
    );
  }
}''',
  };
}
