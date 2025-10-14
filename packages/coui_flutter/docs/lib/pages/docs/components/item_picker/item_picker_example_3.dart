// ignore_for_file: use_build_context_synchronously
import 'package:coui_flutter/coui_flutter.dart';

class NamedColor {
  final String name;
  final Color color;

  const NamedColor(this.name, this.color);
}

class ItemPickerExample3 extends StatefulWidget {
  const ItemPickerExample3({super.key});

  @override
  State<ItemPickerExample3> createState() => _ItemPickerExample3State();
}

class _ItemPickerExample3State extends State<ItemPickerExample3> {
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
              selectedStyle: const ButtonStyle.primary(
                shape: ButtonShape.circle,
              ),
              style: const ButtonStyle.ghost(shape: ButtonShape.circle),
              value: item,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
                width: 100,
                height: 100,
              ),
            );
          },
          initialValue: colors[selectedColor],
          items: ItemList(colors),
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
