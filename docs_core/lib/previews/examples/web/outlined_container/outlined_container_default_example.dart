import 'package:coui_web/coui_web.dart';

class OutlinedContainerDefaultExample extends StatelessComponent {
  const OutlinedContainerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return OutlinedContainer(
      containerStyle: const CoreOutlinedContainerStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
      ),
      child: Text('테두리 컨테이너').bodyMedium,
    );
  }
}
