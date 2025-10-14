import 'package:coui_flutter/coui_flutter.dart';

class AccordionExample1 extends StatelessWidget {
  const AccordionExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Accordion(
      items: [
        AccordionItem(
          content: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
            'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
            'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
            'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
          ),
          trigger: AccordionTrigger(child: Text('Lorem ipsum dolor sit amet')),
        ),
        AccordionItem(
          content: Text(
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
            'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
            'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
            'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
          ),
          trigger: AccordionTrigger(
            child: Text(
              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua',
            ),
          ),
        ),
        AccordionItem(
          content: Text(
            'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
            'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
            'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
          ),
          trigger: AccordionTrigger(
            child: Text(
              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat',
            ),
          ),
        ),
      ],
    );
  }
}
