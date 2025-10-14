import 'package:coui_flutter/coui_flutter.dart';

class TreeExample1 extends StatefulWidget {
  const TreeExample1({super.key});

  @override
  State<TreeExample1> createState() => _TreeExample1State();
}

class _TreeExample1State extends State<TreeExample1> {
  bool expandIcon = false;
  bool usePath = true;
  bool recursiveSelection = false;
  List<TreeNode<String>> treeItems = [
    TreeItem(
      children: [
        TreeItem(
          children: [
            TreeItem(data: 'Red Apple 1'),
            TreeItem(data: 'Red Apple 2'),
          ],
          data: 'Red Apple',
        ),
        TreeItem(data: 'Green Apple'),
      ],
      data: 'Apple',
      expanded: true,
    ),
    TreeItem(
      children: [
        TreeItem(data: 'Yellow Banana'),
        TreeItem(
          children: [
            TreeItem(data: 'Green Banana 1'),
            TreeItem(data: 'Green Banana 2'),
            TreeItem(data: 'Green Banana 3'),
          ],
          data: 'Green Banana',
        ),
      ],
      data: 'Banana',
    ),
    TreeItem(
      children: [
        TreeItem(data: 'Red Cherry'),
        TreeItem(data: 'Green Cherry'),
      ],
      data: 'Cherry',
    ),
    TreeItem(data: 'Date'),
    // Tree Root acts as a parent node with no data,
    // it will flatten the children into the parent node
    TreeRoot(
      children: [
        TreeItem(
          children: [
            TreeItem(data: 'Black Elderberry'),
            TreeItem(data: 'Red Elderberry'),
          ],
          data: 'Elderberry',
        ),
        TreeItem(
          children: [
            TreeItem(data: 'Green Fig'),
            TreeItem(data: 'Purple Fig'),
          ],
          data: 'Fig',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedContainer(
          child: SizedBox(
            width: 250,
            height: 300,
            child: TreeView(
              branchLine: usePath ? BranchLine.path : BranchLine.line,
              builder: (context, node) {
                return TreeItemView(
                  leading: node.leaf
                      ? const Icon(BootstrapIcons.fileImage)
                      : Icon(
                          node.expanded
                              ? BootstrapIcons.folder2Open
                              : BootstrapIcons.folder2,
                        ),
                  onExpand: TreeView.defaultItemExpandHandler(treeItems, node, (
                    value,
                  ) {
                    setState(() {
                      treeItems = value;
                    });
                  }),
                  onPressed: () {
                    // TODOS: will be implemented later.
                  },
                  trailing: node.leaf
                      ? Container(
                          alignment: Alignment.center,
                          width: 16,
                          height: 16,
                          child: const CircularProgressIndicator(),
                        )
                      : null,
                  child: Text(node.data),
                );
              },
              expandIcon: expandIcon,
              nodes: treeItems,
              onSelectionChanged: TreeView.defaultSelectionHandler(treeItems, (
                value,
              ) {
                setState(() {
                  treeItems = value;
                });
              }),
              recursiveSelection: recursiveSelection,
              shrinkWrap: true,
            ),
          ),
        ),
        const Gap(16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              child: const Text('Expand All'),
              onPressed: () {
                setState(() {
                  treeItems = treeItems.expandAll();
                });
              },
            ),
            const Gap(8),
            PrimaryButton(
              child: const Text('Collapse All'),
              onPressed: () {
                setState(() {
                  treeItems = treeItems.collapseAll();
                });
              },
            ),
          ],
        ),
        const Gap(8),
        Checkbox(
          onChanged: (value) {
            setState(() {
              expandIcon = value == CheckboxState.checked;
            });
          },
          state: expandIcon ? CheckboxState.checked : CheckboxState.unchecked,
          trailing: const Text('Expand Icon'),
        ),
        const Gap(8),
        Checkbox(
          onChanged: (value) {
            setState(() {
              usePath = value == CheckboxState.checked;
            });
          },
          state: usePath ? CheckboxState.checked : CheckboxState.unchecked,
          trailing: const Text('Use Path Branch Line'),
        ),
        const Gap(8),
        Checkbox(
          onChanged: (value) {
            setState(() {
              recursiveSelection = value == CheckboxState.checked;
              if (recursiveSelection) {
                treeItems = treeItems.updateRecursiveSelection();
              }
            });
          },
          state: recursiveSelection
              ? CheckboxState.checked
              : CheckboxState.unchecked,
          trailing: const Text('Recursive Selection'),
        ),
      ],
    );
  }
}
