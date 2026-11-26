/// Returns a Web code snippet string for the Skeleton component.
String skeletonCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SkeletonChainExample extends StatefulComponent {
  const SkeletonChainExample({super.key});

  @override
  State<SkeletonChainExample> createState() => _SkeletonChainExampleState();
}

class _SkeletonChainExampleState extends State<SkeletonChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Skeleton(width: '200px', height: '20px').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(fromOpacity)까지 한 번에.
        Skeleton(width: '200px', height: '20px').withStyle(
          const CoreSkeletonStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            fromOpacity: CoreOpacity.opacity20,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'circle' =>
      '''
class SkeletonCircleExample extends StatefulComponent {
  const SkeletonCircleExample({super.key});

  @override
  State<SkeletonCircleExample> createState() => _SkeletonCircleExampleState();
}

class _SkeletonCircleExampleState extends State<SkeletonCircleExample> {
  @override
  Component build(BuildContext context) {
    return Skeleton.circle(size: '48px');
  }
}''',
    'text' =>
      '''
class SkeletonTextExample extends StatefulComponent {
  const SkeletonTextExample({super.key});

  @override
  State<SkeletonTextExample> createState() => _SkeletonTextExampleState();
}

class _SkeletonTextExampleState extends State<SkeletonTextExample> {
  @override
  Component build(BuildContext context) {
    return Skeleton.text(
      skeletonStyle: const CoreSkeletonStyle(lines: 3),
    );
  }
}''',
    _ =>
      '''
class SkeletonDefaultExample extends StatefulComponent {
  const SkeletonDefaultExample({super.key});

  @override
  State<SkeletonDefaultExample> createState() => _SkeletonDefaultExampleState();
}

class _SkeletonDefaultExampleState extends State<SkeletonDefaultExample> {
  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-\${CoreSpace.scale.space8}', [
      Skeleton(width: '200px', height: '20px'),
      Skeleton(width: '150px', height: '20px'),
      Skeleton(width: '180px', height: '20px'),
    ]);
  }
}''',
  };
}
