import 'package:coui_flutter/coui_flutter.dart';

class LoadingRegionDefaultExample extends StatefulWidget {
  const LoadingRegionDefaultExample({super.key});

  @override
  State<LoadingRegionDefaultExample> createState() => _LoadingRegionDefaultExampleState();
}

class _LoadingRegionDefaultExampleState extends State<LoadingRegionDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return LoadingRegion(
      semanticLabel: '주문 목록을 불러오는 중',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          Skeleton(width: 200, height: 20),
          Skeleton(width: 150, height: 20),
          Skeleton(width: 180, height: 20),
        ],
      ),
    );
  }
}
