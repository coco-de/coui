import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

const _labels = {
  'en': 'Available for a conversation with a new partner',
  'ko': '새로운 대화 상대와 함께 이야기할 수 있어요',
  'ja': '新しい会話のパートナーとお話しできます',
  'zh': '可以与新的聊天伙伴一起开始对话',
  'de': 'Bereit für ein Gespräch mit einem neuen Partner',
  'fr': 'Disponible pour discuter avec un nouveau partenaire',
  'es': 'Disponible para conversar con una nueva persona',
  'pt': 'Disponível para conversar com uma nova pessoa',
  'ru': 'Можно начать разговор с новым собеседником',
  'ar': 'متاح للمحادثة مع شريك جديد في الدردشة',
  'hi': 'नए साथी के साथ बातचीत शुरू करने के लिए उपलब्ध',
};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => tester.pumpWidget(
  material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: Center(child: child),
        ),
      ),
    ),
  ),
);

Finder _box() => find.descendant(
  of: find.byType(Badge),
  matching: find.byType(AnimatedContainer),
);

void main() {
  group('bounded badge labels', () {
    for (final label in _labels.entries) {
      for (final scale in [1.0, 2.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('${label.key} at $scale × $direction', (tester) async {
            await _pump(
              tester,
              SizedBox(
                width: 160,
                child: Badge(
                  showDot: true,
                  leading: const SizedBox.square(
                    dimension: 16,
                    key: ValueKey('leading'),
                  ),
                  trailing: const SizedBox.square(
                    dimension: 16,
                    key: ValueKey('trailing'),
                  ),
                  child: Text(label.value),
                ),
              ),
              scale: scale,
              direction: direction,
            );
            expect(tester.takeException(), isNull);
            final box = tester.getRect(_box());
            final text = tester.getRect(find.text(label.value));
            expect(box.width, 160);
            expect(box.height, greaterThan(24));
            expect(text.left, greaterThanOrEqualTo(box.left));
            expect(text.right, lessThanOrEqualTo(box.right));
            expect(text.bottom, lessThanOrEqualTo(box.bottom));
            final lead = tester.getRect(find.byKey(const ValueKey('leading')));
            final trail = tester.getRect(
              find.byKey(const ValueKey('trailing')),
            );
            expect(lead.width, 16);
            expect(trail.width, 16);
            expect(
              direction == TextDirection.ltr
                  ? lead.right <= text.left
                  : lead.left >= text.right,
              isTrue,
            );
            expect(
              direction == TextDirection.ltr
                  ? trail.left >= text.right
                  : trail.right <= text.left,
              isTrue,
            );
          });
        }
      }
    }
  });

  // BottariFX phone-auth: 320px viewport minus 20px on each side,
  // Center > primary/sm Badge(title), with no dot or icon slots.
  for (final label in ['Проверка телефона', 'التحقق من الهاتف']) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'phone-auth title at actual 280px / 2x: $label / $direction',
        (tester) async {
          await _pump(
            tester,
            SizedBox(
              width: 280,
              child: Center(
                child: Badge(
                  tone: CoreBadgeTone.primary,
                  size: CoreComponentSize.sm,
                  child: Text(label),
                ),
              ),
            ),
            scale: 2,
            direction: direction,
          );
          expect(tester.takeException(), isNull);
          final box = tester.getRect(_box());
          final text = tester.getRect(find.text(label));
          expect(box.width, lessThanOrEqualTo(280));
          expect(text.left, greaterThanOrEqualTo(box.left));
          expect(text.right, lessThanOrEqualTo(box.right));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(Badge),
              matching: find.byType(RichText),
            ),
          );
          final lines = paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: label.length),
              )
              .map((box) => box.top)
              .toSet();
          expect(lines.length, lessThanOrEqualTo(2));
        },
      );
    }
  }

  for (final label in ['Номер телефона подтверждён', 'تم تأكيد رقم الهاتف']) {
    for (final direction in TextDirection.values) {
      testWidgets('completion badge at 120px / 2x: $label / $direction', (
        tester,
      ) async {
        await _pump(
          tester,
          SizedBox(
            width: 120,
            child: Badge(
              tone: CoreBadgeTone.success,
              leading: const Icon(LucideIcons.check),
              child: Text(label),
            ),
          ),
          scale: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        final box = tester.getRect(_box());
        final text = tester.getRect(find.text(label));
        expect(box.width, 120);
        expect(box.height, greaterThan(24));
        expect(text.left, greaterThanOrEqualTo(box.left));
        expect(text.right, lessThanOrEqualTo(box.right));
        expect(text.bottom, lessThanOrEqualTo(box.bottom));
      });
    }
  }

  testWidgets('unbroken text wraps and retains the complete semantics label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const label = 'Donaudampfschifffahrtsgesellschaftskapitän';
    await _pump(
      tester,
      const SizedBox(width: 120, child: Badge(child: Text(label))),
      scale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_box()).height, greaterThan(24));
    expect(find.bySemanticsLabel(label), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('short labels retain their natural size under loose bounds', (
    tester,
  ) async {
    await _pump(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Badge(child: Text('Tag'))],
      ),
    );
    final natural = tester.getSize(_box());
    await _pump(tester, const Badge(child: Text('Tag')));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_box()), natural);
    expect(natural.height, 24);
  });

  testWidgets('long labels stay natural in unbounded and intrinsic layouts', (
    tester,
  ) async {
    const badge = Badge(child: Text('Available for a new conversation'));
    await _pump(
      tester,
      const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: badge,
      ),
      scale: 2,
    );
    final natural = tester.getSize(_box());
    expect(tester.takeException(), isNull);
    await _pump(tester, const IntrinsicWidth(child: badge), scale: 2);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_box()), natural);
  });

  testWidgets('explicit one-line overflow remains caller controlled', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 120,
        child: Badge(
          child: material.Text(
            'A long label with an explicit line limit',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText).last,
    );
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(tester.getSize(_box()).height, 24);
  });

  for (final variant in CoreBadgeVariant.values) {
    testWidgets('$variant keeps a pressable count on one line', (
      tester,
    ) async {
      var presses = 0;
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        SizedBox(
          width: 160,
          child: Badge(
            variant: variant,
            form: CoreBadgeForm.count,
            onPressed: () => presses++,
            child: const Text('123456789012345678901234567890'),
          ),
        ),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(Badge),
          matching: find.byType(RichText),
        ),
      );
      final lines = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 30),
          )
          .map((box) => box.top)
          .toSet();
      expect(lines, hasLength(1));
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(
        find.bySemanticsLabel('123456789012345678901234567890'),
        findsOneWidget,
      );
      await tester.tap(find.byType(Badge));
      expect(presses, 1);
      semantics.dispose();
    });
  }
}
