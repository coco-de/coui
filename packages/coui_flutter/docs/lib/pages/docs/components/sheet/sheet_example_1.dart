import 'package:coui_flutter/coui_flutter.dart';

class SheetExample1 extends StatefulWidget {
  const SheetExample1({super.key});

  @override
  State<SheetExample1> createState() => _SheetExample1State();
}

class _SheetExample1State extends State<SheetExample1> {
  final FormController controller = FormController();

  void saveProfile() {
    showDialog(
      builder: (context) {
        return AlertDialog(
          actions: [
            PrimaryButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
          content: Text('Content: ${controller.values}'),
          title: const Text('Profile updated'),
        );
      },
      context: context,
    );
  }

  Widget buildSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        controller: controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child: const Text('Edit profile').large().medium()),
                TextButton(
                  onPressed: () {
                    closeSheet(context);
                  },
                  density: ButtonDensity.icon,
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const Gap(8),
            const Text(
              'Make changes to your profile here. Click save when you\'re done.',
            ).muted(),
            const Gap(16),
            FormTableLayout(
              rows: [
                FormField<String>(
                  key: const FormKey(#name),
                  label: const Text('Name'),
                  validator:
                      const NotEmptyValidator() & const LengthValidator(min: 4),
                  child: const TextField(
                    initialValue: 'Thito Yalasatria Sunarya',
                    placeholder: Text('Your fullname'),
                  ),
                ),
                FormField<String>(
                  key: const FormKey(#username),
                  label: const Text('Username'),
                  validator:
                      const NotEmptyValidator() & const LengthValidator(min: 4),
                  child: const TextField(
                    initialValue: '@sunarya-thito',
                    placeholder: Text('Your username'),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FormErrorBuilder(
                builder: (context, errors, child) {
                  return PrimaryButton(
                    onPressed: errors.isNotEmpty
                        ? null
                        : () {
                            context.submitForm().then((value) {
                              if (value.errors.isEmpty) {
                                closeSheet(context).then((value) {
                                  saveProfile();
                                });
                              }
                            });
                          },
                    child: const Text('Save changes'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Open Sheet'),
      onPressed: () {
        openSheet(
          builder: (context) {
            return buildSheet(context);
          },
          context: context,
          position: OverlayPosition.end,
        );
      },
    );
  }
}
