import 'package:coui_flutter/coui_flutter.dart';

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
}
