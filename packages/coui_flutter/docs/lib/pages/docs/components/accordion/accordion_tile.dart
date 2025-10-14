import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class AccordionTile extends StatelessWidget implements IComponentPage {
  const AccordionTile({super.key});

  @override
  String get title => 'Accordion';

  @override
  Widget build(BuildContext context) {
    return const ComponentCard(
      name: 'accordion',
      title: 'Accordion',
      example: SizedBox(
        width: 280,
        child: Card(
          child: Accordion(
            items: [
              AccordionItem(
                content: Text('Content 1'),
                trigger: AccordionTrigger(child: Text('Accordion 1')),
              ),
              AccordionItem(
                content: Text('Content 2'),
                trigger: AccordionTrigger(child: Text('Accordion 2')),
              ),
              AccordionItem(
                content: Text('Content 3'),
                trigger: AccordionTrigger(child: Text('Accordion 3')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
