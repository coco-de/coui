import 'package:coui_flutter/coui_flutter.dart';

class PopupDefaultExample extends StatelessWidget {
  const PopupDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Popup(
      children: [
        Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space8,
            vertical: CoreSpace.space4,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('프로필').bodyMedium,
        ),
        Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space8,
            vertical: CoreSpace.space4,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('설정').bodyMedium,
        ),
        Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space8,
            vertical: CoreSpace.space4,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('로그아웃').bodyMedium,
        ),
      ],
    );
  }
}
