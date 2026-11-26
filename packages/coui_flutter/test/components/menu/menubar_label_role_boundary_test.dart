import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart' as c;
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/widgets.dart' as fw;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../parity/parity_fonts.dart';

final _records = <Map<String, Object?>>[];

void main() {
  setUpAll(loadParityFonts);
  tearDownAll(() {
    final path = Platform.environment['MENUBAR_BOUNDARY_OBSERVATIONS'];
    if (path != null) File(path).writeAsStringSync(jsonEncode(_records));
  });
  for (final opened in [false, true]) {
    final state = opened ? 'open' : 'rest';
    testWidgets('label-only role boundary $state', (tester) async {
      final key = fw.GlobalKey();
      addTearDown(() async {
        await tester.pumpWidget(const fw.SizedBox.shrink());
        await tester.pumpAndSettle();
      });
      await pumpTestApp(
        tester,
        c.Menubar(
          key: key,
          menus: const [
            c.CoreMenubarMenu(
              label: 'File',
              entries: [c.CoreMenubarEntry.action(label: 'New boundary file')],
            ),
            c.CoreMenubarMenu(
              label: 'Edit',
              entries: [c.CoreMenubarEntry.action(label: 'Boundary selection')],
            ),
          ],
          menubarStyle: const c.CoreMenubarStyle(
            labelTextStyle: c.CoreTextStyle.token(c.CoreTextStyles.bodyLarge),
          ),
        ),
        theme: c.ThemeData.fromCore(c.CoreThemePresets.light),
        componentTheme: const c.CoreComponentTheme(
          menubar: c.CoreMenubarTheme(
            style: c.CoreMenubarStyle(
              labelTextStyle: c.CoreTextStyle(fontSize: 18, lineHeightPx: 36),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final beforeState = tester.state(find.byKey(key));
      if (opened) {
        await tester.tap(find.text('File'));
        await tester.pumpAndSettle();
      }
      final labels = <Map<String, Object?>>[];
      for (final text in ['File', 'Edit']) {
        final finder = find.descendant(
          of: find.byKey(key),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is fw.RichText && widget.text.toPlainText() == text,
          ),
        );
        expect(finder, findsOneWidget);
        final object = tester.renderObject<rendering.RenderParagraph>(finder);
        final span = object.text as fw.TextSpan;
        labels.add({
          'text': text,
          'renderIdentity': identityHashCode(object),
          'fontSize': span.style?.fontSize,
          'heightMultiplier': span.style?.height,
          'fontWeight': span.style?.fontWeight?.value,
          'size': [object.size.width, object.size.height],
        });
      }
      final sameState = identical(beforeState, tester.state(find.byKey(key)));
      final visible = find.text('New boundary file').evaluate().isNotEmpty;
      _records.add({
        'case': 'label-only role boundary $state',
        'input': 'theme.label(raw18,px36,no-role) then widget.label(bodyLarge)',
        'contract':
            'Existing Core no-role.merge(role) preserves raw18/px36; '
            'do not re-associate a default token before this named-field merge',
        'actualLabels': labels,
        'openedByPublicTriggerTap': opened,
        'panelVisible': visible,
        'menubarStateRetained': sameState,
      });
      expect(sameState, isTrue);
      expect(visible, opened);
      expect(tester.takeException(), isNull);
      for (final label in labels) {
        expect(label['fontSize'], 18);
        expect(label['heightMultiplier'], 2);
        expect(
          label['fontWeight'],
          opened && label['text'] == 'File' ? 500 : 400,
        );
      }
    });
  }
}
