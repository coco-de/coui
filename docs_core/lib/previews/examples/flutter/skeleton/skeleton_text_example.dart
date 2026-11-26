import 'package:coui_flutter/coui_flutter.dart';

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
}
