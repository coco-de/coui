import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'form.stories.g.dart';

const _kFormWidth = 320.0;

void _handleNoop(String value) {}

/// Interactive demo host for [Form] stories.
class FormDemo extends StatefulWidget {
  /// Creates a [FormDemo].
  const FormDemo({super.key, this.rowSpacing = CoreSpace.space16});

  /// Vertical spacing between form rows.
  final double rowSpacing;

  @override
  State<FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<FormDemo> {
  final _controller = FormController();
  bool? _termsChecked = false;

  void handleSubmit() {
    _controller.revalidate(
      CoUIValidationContext(context),
      .submitted,
    );
  }

  void handleTermsChanged({required bool? checked}) {
    setState(() => _termsChecked = checked);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kFormWidth,
      child: Form(
        rowSpacing: widget.rowSpacing,
        controller: _controller,
        children: [
          FormField(
            label: 'Name',
            required: true,
            validator: const RequiredValidator<String>(),
            child: TextField(
              onChanged: _handleNoop,
              placeholder: const Text('Enter your name'),
            ),
          ),
          FormField(
            label: 'Email',
            required: true,
            validator: const RequiredValidator<String>(),
            child: TextField(
              onChanged: _handleNoop,
              placeholder: const Text('Enter your email'),
            ),
          ),
          Checkbox(
            onChanged: (checked) => handleTermsChanged(checked: checked),
            checked: _termsChecked,
            suffix: const Text('I agree to the terms and conditions'),
          ),
          Button(
            onPressed: handleSubmit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

/// Navigation metadata for the Form component.
const kComponentMeta = ComponentMeta(name: 'Form', path: 'form');

/// Story metadata for [FormDemo].
const kMeta = Meta(FormDemo.new);

/// Validated form with fields, checkbox and a submit button.
final $Default = _Story();
