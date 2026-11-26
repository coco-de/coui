import 'package:coui_web/coui_web.dart';

class AppBarProminentExample extends StatelessComponent {
  const AppBarProminentExample({super.key});

  @override
  Component build(BuildContext context) {
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
