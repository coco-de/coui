import 'package:coui_web/coui_web.dart';

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
}
