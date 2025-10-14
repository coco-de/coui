// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class ItemPickerExample2 extends StatelessWidget {
  const ItemPickerExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPickerDialog<int>(
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
          ),
          title: const Text('Pick a number'),
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
