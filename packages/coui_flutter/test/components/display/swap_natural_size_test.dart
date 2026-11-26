import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _rows = <Map<String, Object?>>[];
int _mountSerial = 0;

class _Face extends StatefulWidget {
  const _Face(this.name, this.size, {this.useFrame = false, super.key});
  final String name;
  final Size size;
  final bool useFrame;
  @override
  State<_Face> createState() => _FaceState();
}

class _FaceState extends State<_Face> {
  final int serial = ++_mountSerial;
  @override
  Widget build(BuildContext context) {
    if (widget.useFrame) {
      return Frame(
        key: ValueKey('frame-${widget.name}'),
        width: widget.size.width,
        height: widget.size.height,
        backgroundColor: widget.name == 'on'
            ? const CoreColor(0xff209060)
            : const CoreColor(0xff3050a0),
      );
    }
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: ColoredBox(
        color: widget.name == 'on'
            ? const Color(0xff209060)
            : const Color(0xff3050a0),
      ),
    );
  }
}

class _Harness extends StatefulWidget {
  const _Harness(
    this.animation,
    this.off,
    this.on, {
    this.interactive = false,
    this.useFrames = false,
    this.parentSize = const Size(240, 160),
    super.key,
  });
  final CoreSwapAnimation animation;
  final Size off;
  final Size on;
  final bool interactive;
  final bool useFrames;
  final Size parentSize;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool checked = false;
  int callbacks = 0;
  final values = <bool>[];
  void setChecked(bool value) => setState(() => checked = value);
  @override
  Widget build(BuildContext context) => material.MaterialApp(
    home: Theme(
      data: ThemeData.fromCore(CoreThemePresets.light),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          key: const ValueKey('stage'),
          width: widget.parentSize.width,
          height: widget.parentSize.height,
          child: Align(
            alignment: Alignment.topLeft,
            child: Swap(
              key: const ValueKey('swap'),
              checked: checked,
              animation: widget.animation,
              offContent: _Face(
                'off',
                widget.off,
                useFrame: widget.useFrames,
                key: const ValueKey('off'),
              ),
              onContent: _Face(
                'on',
                widget.on,
                useFrame: widget.useFrames,
                key: const ValueKey('on'),
              ),
              onToggle: widget.interactive
                  ? (value) {
                      callbacks++;
                      values.add(value);
                      setChecked(value);
                    }
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
}

Map<String, Object?> _observe(
  WidgetTester tester,
  String name,
  _HarnessState host,
  String phase,
) {
  final swap = find.byKey(const ValueKey('swap'));
  final size = tester.getSize(swap);
  final faces = <String, Object?>{};
  for (final face in ['off', 'on']) {
    final finder = find.byKey(ValueKey(face));
    if (finder.evaluate().isEmpty) {
      faces[face] = null;
    } else {
      final state = tester.state<_FaceState>(finder);
      final box = tester.renderObject<RenderBox>(finder);
      faces[face] = {
        'serial': state.serial,
        'width': box.size.width,
        'height': box.size.height,
      };
    }
  }
  final builders = find
      .descendant(of: swap, matching: find.byType(AnimatedBuilder))
      .evaluate();
  final animation =
      (builders.first.widget as AnimatedBuilder).animation as Animation<double>;
  final row = <String, Object?>{
    'case': name,
    'variant': host.widget.animation.name,
    'phase': phase,
    'checked': host.checked,
    'easedAnimationValue': animation.value,
    'width': size.width,
    'height': size.height,
    'faces': faces,
    'callbacks': host.callbacks,
    'values': host.values.toList(),
  };
  _rows.add(row);
  return row;
}

Size _expected(_Harness host, bool checked) =>
    host.animation == CoreSwapAnimation.flip
    ? (checked ? host.on : host.off)
    : Size(
        host.off.width > host.on.width ? host.off.width : host.on.width,
        host.off.height > host.on.height ? host.off.height : host.on.height,
      );

void main() {
  tearDownAll(() {
    final out = Platform.environment['SWAP_EVIDENCE'];
    if (out != null) {
      File('$out/native-observed.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({'records': _rows}),
      );
    }
  });
  for (final (name, off, on) in [
    ('horizontal', const Size(16, 24), const Size(80, 24)),
    ('vertical', const Size(24, 16), const Size(24, 80)),
    ('same-size', const Size(24, 24), const Size(24, 24)),
  ]) {
    for (final variant in CoreSwapAnimation.values) {
      testWidgets(
        '$name ${variant.name} owns the existing Native natural-size policy',
        (tester) async {
          final key = GlobalKey<_HarnessState>();
          final config = _Harness(variant, off, on, key: key);
          await tester.pumpWidget(config);
          await tester.pumpAndSettle();
          final host = key.currentState!;
          final initial = _observe(tester, name, host, 'false');
          expect(
            tester.getSize(find.byKey(const ValueKey('swap'))),
            _expected(config, false),
          );
          host.setChecked(true);
          await tester.pump();
          if (variant == CoreSwapAnimation.flip) {
            for (final delay in [0, 40, 80, 180]) {
              await tester.pump(Duration(milliseconds: delay));
              final row = _observe(tester, name, host, 'forward-pump+$delay');
              final showingOn = (row['easedAnimationValue']! as double) >= .5;
              expect(
                tester.getSize(find.byKey(const ValueKey('swap'))),
                showingOn ? on : off,
              );
            }
          }
          await tester.pumpAndSettle();
          final selected = _observe(tester, name, host, 'true-settled');
          expect(
            tester.getSize(find.byKey(const ValueKey('swap'))),
            _expected(config, true),
          );
          host.setChecked(false);
          await tester.pumpAndSettle();
          final restored = _observe(tester, name, host, 'false-restored');
          expect(
            tester.getSize(find.byKey(const ValueKey('swap'))),
            _expected(config, false),
          );
          if (variant != CoreSwapAnimation.flip) {
            expect(selected['faces'], initial['faces']);
            expect(restored['faces'], initial['faces']);
          }
          expect(host.callbacks, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final (name, off, on) in [
    ('horizontal', const Size(16, 24), const Size(80, 24)),
    ('vertical', const Size(24, 16), const Size(24, 80)),
  ]) {
    testWidgets(
      '$name natural-size interactive owner keeps focus '
      'and distant pointer hits',
      (tester) async {
        final key = GlobalKey<_HarnessState>();
        await tester.pumpWidget(
          _Harness(
            CoreSwapAnimation.none,
            off,
            on,
            key: key,
            interactive: true,
          ),
        );
        await tester.pumpAndSettle();
        final host = key.currentState!;
        _observe(tester, name, host, 'interactive-false');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        var insideSwap = false;
        FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
          element,
        ) {
          if (element.widget is Swap) insideSwap = true;
          return true;
        });
        expect(insideSwap, isTrue);
        _rows.add({'case': name, 'phase': 'focus', 'insideSwap': insideSwap});
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(host.values, [true]);
        _observe(tester, name, host, 'keyboard-true');
        final origin = tester.getTopLeft(find.byKey(const ValueKey('swap')));
        final point = name == 'horizontal'
            ? origin + const Offset(70, 12)
            : origin + const Offset(12, 70);
        await tester.tapAt(point);
        await tester.pumpAndSettle();
        expect(host.values, [true, false]);
        _observe(tester, name, host, 'distant-pointer-false');
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final (name, off, on) in [
    ('horizontal', const Size(16, 24), const Size(80, 24)),
    ('vertical', const Size(24, 16), const Size(24, 80)),
  ]) {
    for (final variant in CoreSwapAnimation.values) {
      testWidgets(
        '$name ${variant.name} characterizes a tight24 parent '
        'without layout corrections',
        (tester) async {
          final key = GlobalKey<_HarnessState>();
          final config = _Harness(
            variant,
            off,
            on,
            key: key,
            parentSize: const Size(24, 24),
          );
          await tester.pumpWidget(config);
          await tester.pumpAndSettle();
          for (final checked in [false, true, false]) {
            key.currentState!.setChecked(checked);
            await tester.pumpAndSettle();
            final row = _observe(
              tester,
              name,
              key.currentState!,
              'tight24-$checked',
            );
            final natural = _expected(config, checked);
            expect(row['width'], natural.width.clamp(0, 24));
            expect(row['height'], natural.height.clamp(0, 24));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
  for (final variant in CoreSwapAnimation.values) {
    testWidgets('${variant.name} characterizes inline alphabetic baseline', (
      tester,
    ) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: ThemeData.fromCore(CoreThemePresets.light),
            child: Align(
              alignment: Alignment.topLeft,
              child: RichText(
                key: const ValueKey('inline-line'),
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'A'),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Swap(
                        key: const ValueKey('inline-swap'),
                        animation: variant,
                        offContent: const SizedBox(width: 16, height: 24),
                        onContent: const SizedBox(width: 80, height: 24),
                      ),
                    ),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: SizedBox.shrink(key: ValueKey('baseline-marker')),
                    ),
                    const TextSpan(text: 'Z'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final swap = find.byKey(const ValueKey('inline-swap'));
      final marker = find.byKey(const ValueKey('baseline-marker'));
      final size = tester.getSize(swap);
      final top = tester.getTopLeft(swap);
      final baseline = tester.getTopLeft(marker);
      _rows.add({
        'case': 'horizontal',
        'variant': variant.name,
        'phase': 'inline-baseline',
        'width': size.width,
        'height': size.height,
        'topY': top.dy,
        'baselineY': baseline.dy,
        'baselineFromTop': baseline.dy - top.dy,
        'lineHeight': tester
            .getSize(find.byKey(const ValueKey('inline-line')))
            .height,
      });
      expect(size, Size(variant == CoreSwapAnimation.flip ? 16 : 80, 24));
      expect(baseline.dy - top.dy, 24);
      expect(tester.takeException(), isNull);
    });
  }
  for (final (name, off, on) in [
    ('horizontal', const Size(16, 24), const Size(80, 24)),
    ('vertical', const Size(24, 16), const Size(24, 80)),
  ]) {
    for (final variant in [CoreSwapAnimation.none, CoreSwapAnimation.rotate]) {
      for (final tight in [false, true]) {
        for (final interactive in [false, true]) {
          testWidgets(
            'Frame $name ${variant.name} tight=$tight '
            'interactive=$interactive '
            'preserves actual public face sizes and centers',
            (tester) async {
              final key = GlobalKey<_HarnessState>();
              await tester.pumpWidget(
                _Harness(
                  variant,
                  off,
                  on,
                  key: key,
                  interactive: interactive,
                  useFrames: true,
                  parentSize: tight ? const Size(24, 24) : const Size(240, 160),
                ),
              );
              await tester.pumpAndSettle();
              final host = key.currentState!;
              final expectedRoot = tight
                  ? const Size(24, 24)
                  : name == 'horizontal'
                  ? const Size(80, 24)
                  : const Size(24, 80);
              final expectedOn = tight ? const Size(24, 24) : on;
              Map<String, Object?> snapshot(String phase) {
                final row = _observe(tester, 'Frame-$name', host, phase);
                final root = tester.renderObject<RenderBox>(
                  find.byKey(const ValueKey('swap')),
                );
                expect(root.size, expectedRoot);
                final actualFrames = <String, Object?>{};
                for (final (face, declared, expected) in [
                  ('off', off, off),
                  ('on', on, expectedOn),
                ]) {
                  final finder = find.byKey(ValueKey('frame-$face'));
                  final publicFrame = tester.widget<Frame>(finder);
                  expect(publicFrame.width, declared.width);
                  expect(publicFrame.height, declared.height);
                  final box = tester.renderObject<RenderBox>(finder);
                  final center = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2),
                    ancestor: root,
                  );
                  expect(box.size, expected);
                  expect(
                    center,
                    Offset(root.size.width / 2, root.size.height / 2),
                  );
                  actualFrames[face] = {
                    'type': publicFrame.runtimeType.toString(),
                    'declared': [publicFrame.width, publicFrame.height],
                    'size': [box.size.width, box.size.height],
                    'center': [center.dx, center.dy],
                  };
                }
                row['publicFrames'] = actualFrames;
                row['parent'] = tight ? 'tight24' : 'loose240x160';
                row['interactive'] = interactive;
                return row;
              }

              final initial = snapshot('false');
              for (final checked in [true, false]) {
                if (interactive) {
                  await tester.tap(find.byKey(const ValueKey('swap')));
                } else {
                  host.setChecked(checked);
                }
                await tester.pumpAndSettle();
                expect(host.checked, checked);
                final observed = snapshot(checked ? 'true' : 'false-restored');
                expect(observed['publicFrames'], initial['publicFrames']);
                expect(observed['faces'], initial['faces']);
                expect(
                  host.values,
                  interactive ? (checked ? [true] : [true, false]) : <bool>[],
                );
                expect(tester.takeException(), isNull);
              }
              expect(host.callbacks, interactive ? 2 : 0);
            },
          );
        }
      }
    }
  }
}
