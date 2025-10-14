// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class NamedColor {
  final String name;
  final Color color;

  const NamedColor(this.name, this.color);
}

class ItemPickerExample4 extends StatefulWidget {
  const ItemPickerExample4({super.key});

  @override
  State<ItemPickerExample4> createState() => _ItemPickerExample4State();
}

class _ItemPickerExample4State extends State<ItemPickerExample4> {
  final List<NamedColor> colors = const [
    NamedColor('Red', Colors.red),
    NamedColor('Green', Colors.green),
    NamedColor('Blue', Colors.blue),
    NamedColor('Yellow', Colors.yellow),
    NamedColor('Purple', Colors.purple),
    NamedColor('Cyan', Colors.cyan),
    NamedColor('Orange', Colors.orange),
    NamedColor('Pink', Colors.pink),
    NamedColor('Teal', Colors.teal),
    NamedColor('Amber', Colors.amber),
  ];
  int selectedColor = 0;
  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Show Item Picker'),
      onPressed: () {
        showItemPickerDialog<NamedColor>(
          context,
          builder: (context, item) {
            return ItemPickerOption(
              label: Text(item.name),
              value: item,
              child: Container(
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
                width: 40,
                height: 40,
              ),
            );
          },
          initialValue: colors[selectedColor],
          items: ItemList(colors),
          layout: ItemPickerLayout.list,
          title: const Text('Pick a color'),
        ).then((value) {
          if (value != null) {
            selectedColor = colors.indexOf(value);
            showToast(
              builder: (context, overlay) {
                return SurfaceCard(child: Text('You picked ${value.name}!'));
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
