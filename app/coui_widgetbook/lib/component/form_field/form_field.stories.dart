import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'form_field.stories.g.dart';

const _kFieldWidth = 320.0;
const _kNoDescription = '';

void _handleNoop(String value) {}

/// Interactive demo host for [FormField] stories.
class FormFieldDemo extends StatefulWidget {
  /// Creates a [FormFieldDemo].
  const FormFieldDemo({
    super.key,
    this.label = 'Email',
    this.description = 'Enter your work email address.',
    this.error = '',
    this.required = true,
    this.enabled = true,
    this.interactive = false,
  });

  /// Field label text.
  final String label;

  /// Helper description below the field. Empty hides it.
  final String description;

  /// Error message below the field. Empty hides it.
  final String error;

  /// Whether the field shows the required indicator.
  final bool required;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is wired to a [FormController] with a
  /// [RequiredValidator] and a submit button that revalidates it.
  final bool interactive;

  @override
  State<FormFieldDemo> createState() => _FormFieldDemoState();
}

class _FormFieldDemoState extends State<FormFieldDemo> {
  final _controller = FormController();

  void handleSubmit() {
    _controller.revalidate(
      CoUIValidationContext(context),
      .submitted,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = FormField(
      label: widget.label,
      error: widget.error.isEmpty ? null : widget.error,
      description: widget.description.isEmpty ? null : widget.description,
      required: widget.required,
      enabled: widget.enabled,
      validator: widget.interactive ? const RequiredValidator<String>() : null,
      child: TextField(
        onChanged: _handleNoop,
        placeholder: const Text('you@company.com'),
      ),
    );

    final child = widget.interactive
        ? Form(
            controller: _controller,
            children: [
              field,
              Button(
                onPressed: handleSubmit,
                child: const Text('Submit'),
              ),
            ],
          )
        : field;

    return SizedBox(width: _kFieldWidth, child: child);
  }
}

/// Navigation metadata for the FormField component.
const kComponentMeta = ComponentMeta(name: 'FormField', path: 'form');

/// Story metadata for [FormFieldDemo].
const kMeta = Meta(FormFieldDemo.new);

/// Labelled field with editable knobs.
final $Default = _Story();

/// Field showing an inline error message.
final $WithError = _Story(
  name: 'With Error',
  args: _Args(
    error: StringArg('Please enter a valid email address.'),
  ),
);

/// Field validated through a [FormController] on submit.
final $InteractiveValidation = _Story(
  name: 'Interactive Validation',
  args: _Args(
    label: StringArg('Plan'),
    description: StringArg(_kNoDescription),
    interactive: BoolArg(true),
  ),
);
