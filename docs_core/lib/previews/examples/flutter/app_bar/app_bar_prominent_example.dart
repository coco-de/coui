import 'package:coui_flutter/coui_flutter.dart';

class AppBarProminentExample extends StatelessWidget {
  const AppBarProminentExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.prominent,
      title: const Text('지도'),
      trailing: [
        Button(
          variant: CoreButtonVariant.ghost,
          buttonStyle: const CoreButtonStyle(
            foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
          ),
          onPressed: () {},
          child: const Text('목록으로'),
        ),
      ],
    );
  }
}
