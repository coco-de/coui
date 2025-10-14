import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ResizableExample4 extends StatefulWidget {
  const ResizableExample4({super.key});

  @override
  State<ResizableExample4> createState() => _ResizableExample4State();
}

class _ResizableExample4State extends State<ResizableExample4> {
  final AbsoluteResizablePaneController controller1 =
      AbsoluteResizablePaneController(80);
  final AbsoluteResizablePaneController controller2 =
      AbsoluteResizablePaneController(80);
  final AbsoluteResizablePaneController controller3 =
      AbsoluteResizablePaneController(120);
  final AbsoluteResizablePaneController controller4 =
      AbsoluteResizablePaneController(80);
  final AbsoluteResizablePaneController controller5 =
      AbsoluteResizablePaneController(80);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedContainer(
          clipBehavior: Clip.antiAlias,
          child: ResizablePanel.horizontal(
            children: [
              ResizablePane.controlled(
                controller: controller1,
                child: const NumberedContainer(
                  index: 0,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                controller: controller2,
                child: const NumberedContainer(
                  index: 1,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                controller: controller3,
                maxSize: 200,
                child: const NumberedContainer(
                  index: 2,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                controller: controller4,
                child: const NumberedContainer(
                  index: 3,
                  height: 200,
                  fill: false,
                ),
              ),
              ResizablePane.controlled(
                collapsedSize: 20,
                controller: controller5,
                minSize: 80,
                child: const NumberedContainer(
                  index: 4,
                  height: 200,
                  fill: false,
                ),
              ),
            ],
          ),
        ),
        const Gap(48),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PrimaryButton(
              child: const Text('Reset'),
              onPressed: () {
                controller1.size = 80;
                controller2.size = 80;
                controller3.size = 120;
                controller4.size = 80;
                controller5.size = 80;
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 2'),
              onPressed: () {
                controller3.tryExpandSize(20);
              },
            ),
            PrimaryButton(
              child: const Text('Shrink Panel 2'),
              onPressed: () {
                controller3.tryExpandSize(-20);
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 1'),
              onPressed: () {
                controller2.tryExpandSize(20);
              },
            ),
            PrimaryButton(
              child: const Text('Shrink Panel 1'),
              onPressed: () {
                controller2.tryExpandSize(-20);
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 4'),
              onPressed: () {
                controller5.tryExpandSize(20);
              },
            ),
            PrimaryButton(
              child: const Text('Shrink Panel 4'),
              onPressed: () {
                controller5.tryExpandSize(-20);
              },
            ),
            PrimaryButton(
              child: const Text('Collapse Panel 4'),
              onPressed: () {
                controller5.tryCollapse();
              },
            ),
            PrimaryButton(
              child: const Text('Expand Panel 4'),
              onPressed: () {
                controller5.tryExpand();
              },
            ),
          ],
        ),
      ],
    );
  }
}
