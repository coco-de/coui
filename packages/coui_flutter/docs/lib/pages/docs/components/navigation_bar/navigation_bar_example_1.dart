import 'package:coui_flutter/coui_flutter.dart';

class NavigationBarExample1 extends StatefulWidget {
  const NavigationBarExample1({super.key});

  @override
  State<NavigationBarExample1> createState() => _NavigationBarExample1State();
}

class _NavigationBarExample1State extends State<NavigationBarExample1> {
  int selected = 0;

  NavigationBarAlignment alignment = NavigationBarAlignment.spaceAround;
  bool expands = true;
  NavigationLabelType labelType = NavigationLabelType.none;
  bool customButtonStyle = true;
  bool expanded = true;

  NavigationItem _buildButton(String label, IconData icon) {
    return NavigationItem(
      label: Text(label),
      selectedStyle: customButtonStyle
          ? const ButtonStyle.fixed(density: ButtonDensity.icon)
          : null,
      style: customButtonStyle
          ? const ButtonStyle.muted(density: ButtonDensity.icon)
          : null,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      height: 400,
      width: 500,
      child: Scaffold(
        footers: [
          const Divider(),
          NavigationBar(
            alignment: alignment,
            expanded: expanded,
            expands: expands,
            index: selected,
            labelType: labelType,
            onSelected: (index) {
              setState(() {
                selected = index;
              });
            },
            children: [
              _buildButton('Home', BootstrapIcons.house),
              _buildButton('Explore', BootstrapIcons.compass),
              _buildButton('Library', BootstrapIcons.musicNoteList),
              _buildButton('Profile', BootstrapIcons.person),
              _buildButton('App', BootstrapIcons.appIndicator),
            ],
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(24),
          color: Colors.primaries[Colors.primaries.length - selected - 1],
          child: Card(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runAlignment: WrapAlignment.center,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Select<NavigationBarAlignment>(
                  itemBuilder:
                      (BuildContext context, NavigationBarAlignment item) {
                    return Text(item.name);
                  },
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        alignment = value;
                      });
                    }
                  },
                  popup: (context) => SelectPopup(
                    items: SelectItemList(
                      children: [
                        for (var value in NavigationBarAlignment.values)
                          SelectItemButton(
                            value: value,
                            child: Text(value.name),
                          ),
                      ],
                    ),
                  ),
                  popupWidthConstraint: PopoverConstraint.anchorFixedSize,
                  value: alignment,
                ),
                Select<NavigationLabelType>(
                  itemBuilder:
                      (BuildContext context, NavigationLabelType item) {
                    return Text(item.name);
                  },
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        labelType = value;
                      });
                    }
                  },
                  popup: (context) => SelectPopup(
                    items: SelectItemList(
                      children: [
                        for (var value in NavigationLabelType.values)
                          SelectItemButton(
                            value: value,
                            child: Text(value.name),
                          ),
                      ],
                    ),
                  ),
                  popupWidthConstraint: PopoverConstraint.anchorFixedSize,
                  value: labelType,
                ),
                Checkbox(
                  onChanged: (value) {
                    setState(() {
                      expands = value == CheckboxState.checked;
                    });
                  },
                  state:
                      expands ? CheckboxState.checked : CheckboxState.unchecked,
                  trailing: const Text('Expands'),
                ),
                Checkbox(
                  onChanged: (value) {
                    setState(() {
                      customButtonStyle = value == CheckboxState.checked;
                    });
                  },
                  state: customButtonStyle
                      ? CheckboxState.checked
                      : CheckboxState.unchecked,
                  trailing: const Text('Custom Button Style'),
                ),
                Checkbox(
                  onChanged: (value) {
                    setState(() {
                      expanded = value == CheckboxState.checked;
                    });
                  },
                  state: expanded
                      ? CheckboxState.checked
                      : CheckboxState.unchecked,
                  trailing: const Text('Expanded'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
