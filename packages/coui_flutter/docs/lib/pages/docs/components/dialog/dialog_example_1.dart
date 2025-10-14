import 'package:coui_flutter/coui_flutter.dart';

class DialogExample1 extends StatelessWidget {
  const DialogExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Edit Profile'),
      onPressed: () {
        showDialog(
          builder: (context) {
            final FormController controller = FormController();
            return AlertDialog(
              actions: [
                PrimaryButton(
                  child: const Text('Save changes'),
                  onPressed: () {
                    Navigator.of(context).pop(controller.values);
                  },
                ),
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Make changes to your profile here. Click save when you\'re done',
                  ),
                  const Gap(16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      controller: controller,
                      child: const FormTableLayout(
                        rows: [
                          FormField<String>(
                            key: FormKey(#name),
                            label: Text('Name'),
                            child: TextField(
                              autofocus: true,
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
                  ),
                ],
              ),
              title: const Text('Edit profile'),
            );
          },
          context: context,
        );
      },
    );
  }
}
