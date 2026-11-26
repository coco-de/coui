import 'package:coui_web/coui_web.dart';

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
}
