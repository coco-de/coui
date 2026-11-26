import 'package:test/test.dart';

import '../bin/figma_reader/ast_value.dart';
import '../bin/figma_reader/style_reader.dart';

void main() {
  test(
    'identity defaults accept only plain required positional parameters',
    () {
      final classes = readCompilationUnit('fixture.dart', '''
      class Example {
        static double defaultPlain(double value) => value;
        static double defaultNamed({required double value}) => value;
        static double defaultOptional([double value = 0]) => value;
        static double defaultFunction(double value()) => value();
        static double defaultMultiple(double value, double other) => value;
        static double defaultComputed(double value) => value * 2;
      }
    ''')!;
      final defaults = {
        for (final entry in classes.single.derivedDefaults) entry.name: entry,
      };
      for (final name in ['defaultPlain']) {
        expect(defaults[name]!.sourceField, 'value', reason: name);
        expect(defaults[name]!.parameterType, 'double', reason: name);
      }
      for (final name in [
        'defaultNamed',
        'defaultOptional',
        'defaultFunction',
        'defaultMultiple',
        'defaultComputed',
      ]) {
        expect(defaults[name]!.sourceField, isNull, reason: name);
      }
    },
  );

  test(
    'named and positional arguments and record fields survive AST changes',
    () {
      final classes = readCompilationUnit('fixture.dart', '''
      class Example {
        static final record = (42, label: 2);
        static final call = factory[0].make(12, enabled: true);
      }
    ''')!;
      final fields = {
        for (final f in classes.single.staticMembers) f.name: f.value,
      };
      final record = fields['record']! as RecordValue;
      expect(record.positionalFields, [const LiteralValue(42)]);
      expect(record.namedFields['label'], const LiteralValue(2));
      final call = fields['call']! as CallValue;
      expect(call.callee, 'make');
      expect(call.positionalArgs, [const LiteralValue(12)]);
      expect(call.namedArgs['enabled'], const LiteralValue(true));
      expect(call.receiver, isA<IndexValue>());
    },
  );
}
