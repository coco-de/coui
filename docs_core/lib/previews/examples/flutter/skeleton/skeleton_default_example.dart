import 'package:coui_flutter/coui_flutter.dart';

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
}
