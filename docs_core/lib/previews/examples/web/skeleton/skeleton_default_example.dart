import 'package:coui_web/coui_web.dart';

class SkeletonDefaultExample extends StatefulComponent {
  const SkeletonDefaultExample({super.key});

  @override
  State<SkeletonDefaultExample> createState() => _SkeletonDefaultExampleState();
}

class _SkeletonDefaultExampleState extends State<SkeletonDefaultExample> {
  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-${CoreSpace.scale.space8}', [
      Skeleton(width: '200px', height: '20px'),
      Skeleton(width: '150px', height: '20px'),
      Skeleton(width: '180px', height: '20px'),
    ]);
  }
}
