// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class ItemPickerExample1 extends StatelessWidget {
  const ItemPickerExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPicker<int>(
          context,
          builder: (context, item) {
            return ItemPickerOption(
              value: item,
              child: Text(item.toString()).large,
            );
          },
          items: ItemBuilder(
            itemBuilder: (index) {
              return index;
            },
            itemCount: 1000,
          ),
          title: const Text('Pick an item'),
        ).then((value) {
          if (value != null) {
            showToast(
              builder: (context, overlay) {
                return SurfaceCard(child: Text('You picked $value!'));
              },
              context: context,
            );
          } else {
            showToast(
              builder: (context, overlay) {
                return const SurfaceCard(child: Text('You picked nothing!'));
              },
              context: context,
            );
          }
        });
      },
    );
  }
}
