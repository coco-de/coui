import 'package:docs/pages/docs/components_page.dart';
import 'package:flutter/material.dart' as material;
import 'package:coui_flutter/coui_flutter.dart';

class DialogTile extends StatelessWidget implements IComponentPage {
  const DialogTile({super.key});

  @override
  String get title => 'Dialog';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'dialog',
      title: 'Dialog',
      example: AlertDialog(
        actions: [
          PrimaryButton(child: const Text('Save changes'), onPressed: () {}),
        ],
        barrierColor: material.Colors.transparent,
        content: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Make changes to your profile here. Click save when you\'re done',
              ),
              const Gap(16),
              const Form(
                child: FormTableLayout(
                  rows: [
                    FormField<String>(
                      key: FormKey(#name),
                      label: Text('Name'),
                      child: TextField(
                        initialValue: 'Thito Yalasatria Sunarya',
                      ),
                    ),
                    FormField<String>(
                      key: FormKey(#username),
                      label: Text('Username'),
                      child: TextField(initialValue: '@sunaryathito'),
                    ),
                  ],
                ),
              ).withPadding(vertical: 16),
            ],
          ),
        ),
        title: const Text('Edit profile'),
      ),
    );
  }
}
