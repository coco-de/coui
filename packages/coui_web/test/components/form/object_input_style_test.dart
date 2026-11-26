import 'package:coui_web/coui_web.dart';
// object_input_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/form/object_input/object_input_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Rules owned by this frame, independently of its composed children.
Finder _frameStyles(ComponentTester tester) {
  final id = _divs(tester).first.id;
  return find.byComponentPredicate((component) {
    if (id == null || component is! DomComponent || component.tag != 'style') {
      return false;
    }
    final css =
        component.children
            ?.whereType<RawText>()
            .map((text) => text.text)
            .join() ??
        '';
    return css.contains('#$id:');
  });
}

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveObjectInput` / `resolveObjectInputRules` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// A raw (token-less) colour — the case that has no Tailwind class and used
/// to throw `token!.name` when routed onto a pseudo-state class.
const _kRawGreen = CoreColor(0xFF00FF00);

const _kFields = [
  CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4),
  CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2),
];

/// The root `className` as a set of whole classes. A substring assertion
/// cannot tell `hover:border-outline` from a class that merely contains it,
/// and this axis is exactly about which classes are present.
Set<String> _classes(String className) =>
    className.split(' ').where((c) => c.isNotEmpty).toSet();

Set<String> _rootClasses(
  BuildContext context, {
  bool enabled = true,
  bool focused = false,
  CoreObjectInputStyle? style,
}) => _classes(
  resolveObjectInput(
    context,
    enabled: enabled,
    focused: focused,
    objectInputStyle: style,
  ).root.className,
);

String _rules(
  BuildContext context, {
  String scopeId = 'co-object-input-test',
  bool enabled = true,
  bool focused = false,
  CoreObjectInputStyle? style,
}) => resolveObjectInputRules(
  context,
  scopeId: scopeId,
  enabled: enabled,
  focused: focused,
  objectInputStyle: style,
).css;

/// Every `<div>` in the pumped tree, for id / child assertions.
Iterable<DomComponent> _divs(ComponentTester tester) =>
    find.tag('div').evaluate().map((e) => e.component as DomComponent);

void main() {
  // The container is the box and the fields inside it are chromeless, so
  // hover has to ride the container's border: `disabled > focus > hover >
  // rest`. Focus is tracked in Dart (`focusin` / `focusout`) and swaps the
  // resting border for the focus one.
  group('ObjectInput container hover border — default (class) path', () {
    testComponents(
      'an unfocused container steps via hover:border-outline and emits no '
      'scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        final classes = _rootClasses(context);

        expect(classes, contains('border-outline-variant'));
        expect(classes, contains('hover:border-outline'));
        expect(_rules(context), isEmpty);
      },
    );

    testComponents(
      'focus wins: a focused container carries the focus border and no hover '
      'class at all, so no cascade order can put hover over it',
      (tester) async {
        final context = _themedContext(tester);
        final classes = _rootClasses(context, focused: true);

        expect(classes, contains('border-primary'));
        expect(classes, isNot(contains('border-outline')));
        expect(
          classes.where((c) => c.contains('hover:')),
          isEmpty,
          reason:
              'a hover class on a focused container would be the one '
              'thing that could beat the focus border',
        );
        expect(
          _rules(
            context,
            focused: true,
            style: const CoreObjectInputStyle(hoverBorderColor: _kRawGreen),
          ),
          isEmpty,
          reason: 'and a raw hover rule must not paint over focus either',
        );
      },
    );

    testComponents('a disabled container has no hover step at all', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        _rootClasses(
          context,
          enabled: false,
        ).where((c) => c.contains('hover:')),
        isEmpty,
      );
      expect(
        _rules(
          context,
          enabled: false,
          style: const CoreObjectInputStyle(hoverBorderColor: _kRawGreen),
        ),
        isEmpty,
      );
    });

    testComponents('a token hoverBorderColor override rides its own class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreObjectInputStyle(
        hoverBorderColor: CoreColor.token(CoreColors.error),
      );
      final classes = _rootClasses(context, style: style);

      expect(classes, contains('hover:border-error'));
      expect(classes, isNot(contains('hover:border-outline')));
      expect(_rules(context, style: style), isEmpty);
    });

    testComponents('a theme-level hoverBorderColor reaches the container', (
      tester,
    ) async {
      final themedData = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          objectInput: CoreObjectInputTheme(
            style: CoreObjectInputStyle(
              hoverBorderColor: CoreColor.token(CoreColors.success),
            ),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: themedData, child: _ContextCapture((c) => context = c)),
      );

      expect(_rootClasses(context), contains('hover:border-success'));
    });
  });

  group('ObjectInput container hover border — raw override (scoped-rule) '
      'path', () {
    testComponents(
      'a raw hoverBorderColor no longer throws — the hover class is dropped '
      'and the border steps via a scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreObjectInputStyle(hoverBorderColor: _kRawGreen);

        // Before the emit family this was a render-time null check on
        // `token!.name`.
        final classes = _rootClasses(context, style: style);
        expect(classes.where((c) => c.contains('hover:')), isEmpty);

        final rules = _rules(
          context,
          scopeId: 'co-object-input-raw',
          style: style,
        );
        expect(
          rules,
          contains('#co-object-input-raw:hover{border-color: rgb(0, 255, 0);}'),
        );
        // The resting border is a class here, so the rule needs no help.
        expect(rules, isNot(contains('!important')));
      },
    );

    testComponents(
      'a raw resting borderColor is inline, so the hover step has to be '
      '!important or it never shows',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreObjectInputStyle(borderColor: _kRawGreen);

        final classes = _rootClasses(context, style: style);
        // Nothing for a class to step: the inline border beats every class.
        expect(classes.where((c) => c.contains('hover:')), isEmpty);

        expect(
          _rules(context, scopeId: 'co-object-input-rawrest', style: style),
          contains(
            '#co-object-input-rawrest:hover'
            '{border-color: rgb(var(--coui-outline)) !important;}',
          ),
        );
      },
    );
  });

  group('ObjectInput container hover border — scoped-rule wiring', () {
    testComponents('the default path renders no <style> and stamps no id', (
      tester,
    ) async {
      pumpWithTheme(tester, const ObjectInput(fields: _kFields));

      expect(_frameStyles(tester), findsNothing);
      expect(_divs(tester).first.id, isNull);
    });

    testComponents(
      'a raw hover override renders the <style> child and stamps the scope id '
      'the rule targets',
      (tester) async {
        pumpWithTheme(
          tester,
          const ObjectInput(
            fields: _kFields,
            objectInputStyle: CoreObjectInputStyle(
              hoverBorderColor: _kRawGreen,
            ),
          ),
        );

        expect(_frameStyles(tester), findsOneComponent);

        final ids = [?_divs(tester).first.id];
        expect(ids, hasLength(1));
        // The selector and the element have to agree — a rule that names
        // an id nothing carries paints nothing, and it looks fine in the
        // resolver test.
        final styleText =
            _frameStyles(tester).evaluate().single.component as DomComponent;
        expect(
          (styleText.children?.first as RawText?)?.text,
          contains('#${ids.single}:hover'),
        );
      },
    );

    testComponents("a caller's own id is reused as the scope id", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ObjectInput(
          fields: _kFields,
          id: 'my-object-input',
          objectInputStyle: CoreObjectInputStyle(hoverBorderColor: _kRawGreen),
        ),
      );

      final styleText =
          _frameStyles(tester).evaluate().single.component as DomComponent;
      expect(
        (styleText.children?.first as RawText?)?.text,
        contains('#my-object-input:hover'),
      );
      expect(
        _divs(tester).map((d) => d.id),
        contains('my-object-input'),
      );
    });

    testComponents('a disabled container renders no hover <style> at all', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ObjectInput(
          fields: _kFields,
          enabled: false,
          objectInputStyle: CoreObjectInputStyle(hoverBorderColor: _kRawGreen),
        ),
      );

      expect(_frameStyles(tester), findsNothing);
    });
  });
}
