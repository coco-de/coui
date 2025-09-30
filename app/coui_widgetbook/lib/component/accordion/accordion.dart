import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Accordion] use case.
@UseCase(
  name: 'default',
  type: coui.Accordion,
)
Widget buildAccordionDefaultUseCase(BuildContext context) {
  return coui.Accordion(
    items: [
      coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text(
            context.knobs.string(
              initialValue: 'Section 1',
              label: 'section 1 title',
            ),
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Content of section 1'),
        ),
      ),
      const coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text('Section 2'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Content of section 2'),
        ),
      ),
      const coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text('Section 3'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Content of section 3'),
        ),
      ),
    ],
  );
}

/// A [coui.Accordion] with single expand use case.
@UseCase(
  name: 'single expand',
  type: coui.Accordion,
)
Widget buildAccordionSingleExpandUseCase(BuildContext _) {
  return coui.Accordion(
    items: const [
      coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text('Item 1'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Only one item can be open at a time'),
        ),
      ),
      coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text('Item 2'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Opening this will close others'),
        ),
      ),
      coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text('Item 3'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('This follows the same pattern'),
        ),
      ),
    ],
  );
}

/// A [coui.Accordion] with default open use case.
@UseCase(
  name: 'default open',
  type: coui.Accordion,
)
Widget buildAccordionDefaultOpenUseCase(BuildContext _) {
  return coui.Accordion(
    items: const [
      coui.AccordionItem(
        expanded: true,
        trigger: coui.AccordionTrigger(
          child: Text('Opened by default'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('This section starts expanded'),
        ),
      ),
      coui.AccordionItem(
        trigger: coui.AccordionTrigger(
          child: Text('Closed by default'),
        ),
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Text('This section starts collapsed'),
        ),
      ),
    ],
  );
}
