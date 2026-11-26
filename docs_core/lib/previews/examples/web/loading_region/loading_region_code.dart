/// Returns a Web code snippet string for the LoadingRegion component.
String loadingRegionCode(String? variant) {
  return switch (variant) {
    _ =>
      '''
class LoadingRegionDefaultExample extends StatefulComponent {
  const LoadingRegionDefaultExample({super.key});

  @override
  State<LoadingRegionDefaultExample> createState() => _LoadingRegionDefaultExampleState();
}

class _LoadingRegionDefaultExampleState extends State<LoadingRegionDefaultExample> {
  @override
  Component build(BuildContext context) {
    return LoadingRegion(
      semanticLabel: '주문 목록을 불러오는 중',
      child: div(classes: 'flex flex-col gap-\${CoreSpace.scale.space8}', [
        Skeleton(width: '200px', height: '20px'),
        Skeleton(width: '150px', height: '20px'),
        Skeleton(width: '180px', height: '20px'),
      ]),
    );
  }
}''',
  };
}
