import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Collapsible] use case.
@UseCase(
  name: 'default',
  type: coui.Collapsible,
)
Widget buildCollapsibleDefaultUseCase(BuildContext context) {
  return coui.Collapsible(
    isExpanded: context.knobs.boolean(initialValue: false, label: 'isExpanded'),
    children: [
      const coui.CollapsibleTrigger(
        child: Text('Click to toggle content'),
      ),
      coui.CollapsibleContent(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('This is the collapsible content.'),
              SizedBox(height: 8),
              Text('It can contain any widgets you want.'),
            ],
          ),
        ),
      ),
    ],
  );
}

/// A [coui.Collapsible] use case with rich content.
@UseCase(
  name: 'rich content',
  type: coui.Collapsible,
)
Widget buildCollapsibleRichUseCase(BuildContext context) {
  return coui.Collapsible(
    isExpanded: false,
    children: [
      coui.CollapsibleTrigger(
        child: Row(
          children: const [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Advanced Settings'),
            Spacer(),
            coui.PrimaryBadge(child: Text('New')),
          ],
        ),
      ),
      coui.CollapsibleContent(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuration Options',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Option 1'),
                value: false,
                onChanged: null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Option 2'),
                value: true,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Multiple [coui.Collapsible] widgets use case.
@UseCase(
  name: 'multiple',
  type: coui.Collapsible,
)
Widget buildCollapsibleMultipleUseCase(BuildContext context) {
  return Column(
    children: [
      coui.Collapsible(
        isExpanded: true,
        children: [
          const coui.CollapsibleTrigger(child: Text('Section 1')),
          coui.CollapsibleContent(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Text('Content for section 1'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      coui.Collapsible(
        isExpanded: false,
        children: [
          const coui.CollapsibleTrigger(child: Text('Section 2')),
          coui.CollapsibleContent(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Text('Content for section 2'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      coui.Collapsible(
        isExpanded: false,
        children: [
          const coui.CollapsibleTrigger(child: Text('Section 3')),
          coui.CollapsibleContent(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Text('Content for section 3'),
            ),
          ),
        ],
      ),
    ],
  );
}
