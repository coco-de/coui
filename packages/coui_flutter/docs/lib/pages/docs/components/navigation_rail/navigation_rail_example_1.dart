import 'package:coui_flutter/coui_flutter.dart';

class NavigationRailExample1 extends StatefulWidget {
  const NavigationRailExample1({super.key});

  @override
  State<NavigationRailExample1> createState() => _NavigationRailExample1State();
}

class _NavigationRailExample1State extends State<NavigationRailExample1> {
  int selected = 0;

  NavigationRailAlignment alignment = NavigationRailAlignment.start;
  NavigationLabelType labelType = NavigationLabelType.none;
  NavigationLabelPosition labelPosition = NavigationLabelPosition.bottom;
  bool customButtonStyle = false;
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
    return Scaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            alignment: alignment,
            expanded: expanded,
            index: selected,
            labelPosition: labelPosition,
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
              const NavigationDivider(),
              const NavigationLabel(child: Text('Settings')),
              _buildButton('Profile', BootstrapIcons.person),
              _buildButton('App', BootstrapIcons.appIndicator),
              const NavigationDivider(),
              const NavigationGap(12),
              const NavigationWidget(child: FlutterLogo()),
            ],
          ),
          const VerticalDivider(),
          Expanded(
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
                    Select<NavigationRailAlignment>(
                      itemBuilder:
                          (BuildContext context, NavigationRailAlignment item) {
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
                            for (var value in NavigationRailAlignment.values)
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
                      popupConstraints: BoxConstraints.tight(
                        const Size(200, 200),
                      ),
                      value: labelType,
                    ),
                    Select<NavigationLabelPosition>(
                      itemBuilder:
                          (BuildContext context, NavigationLabelPosition item) {
                        return Text(item.name);
                      },
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            labelPosition = value;
                          });
                        }
                      },
                      popup: (context) => SelectPopup(
                        items: SelectItemList(
                          children: [
                            for (var value in NavigationLabelPosition.values)
                              SelectItemButton(
                                value: value,
                                child: Text(value.name),
                              ),
                          ],
                        ),
                      ),
                      value: labelPosition,
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
        ],
      ),
    );
  }
}
