import 'package:coui_flutter/coui_flutter.dart';

class OutlinedContainerDefaultExample extends StatelessWidget {
  const OutlinedContainerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      containerStyle: const CoreOutlinedContainerStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
      ),
      child: Text('테두리 컨테이너').bodyMedium,
    );
  }
}
