import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:file_drop/file_drop.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kTreeWidth = 400.0;
const _kTreeHeight = 600.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kTreeWidth,
      height: _kTreeHeight,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

void main() {
  group('CoreTreeNode', () {
    test('stores label and defaults', () {
      const node = CoreTreeNode(label: 'root');

      expect(node.label, equals('root'));
      expect(node.children, isEmpty);
      expect(node.expanded, isFalse);
      expect(node.selected, isFalse);
      expect(node.id, isNull);
    });

    test('stores children and state flags', () {
      const node = CoreTreeNode(
        label: 'parent',
        expanded: true,
        selected: true,
        id: 'p1',
        children: [CoreTreeNode(label: 'child')],
      );

      expect(node.children, hasLength(1));
      expect(node.children.first.label, equals('child'));
      expect(node.expanded, isTrue);
      expect(node.selected, isTrue);
      expect(node.id, equals('p1'));
    });

    test('equality with same label and state', () {
      const nodeA = CoreTreeNode(label: 'node');
      const nodeB = CoreTreeNode(label: 'node');

      expect(nodeA, equals(nodeB));
    });

    test('inequality with different label', () {
      const nodeA = CoreTreeNode(label: 'a');
      const nodeB = CoreTreeNode(label: 'b');

      expect(nodeA, isNot(equals(nodeB)));
    });
  });

  group('Tree', () {
    testWidgets('selectedId updates the style of a lazily loaded child', (
      tester,
    ) async {
      String? selected;
      Widget build() => _buildApp(
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'src',
              label: 'src',
              canHaveChildren: true,
              expanded: true,
            ),
          ],
          selectedId: selected,
          loadChildren: (_) async => const [
            CoreTreeNode(id: 'file', label: 'file'),
          ],
        ),
      );
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      Color? rowColor() => tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text('file'),
              matching: find.byType(Container),
            ),
          )
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .first
          .color;
      expect(rowColor(), isNull);

      selected = 'file';
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      expect(rowColor(), isNotNull);
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any(
              (node) => node.properties.selected ?? false,
            ),
        isTrue,
      );
    });
    testWidgets('drop intent moves a file to a different directory once', (
      tester,
    ) async {
      final moves = <(String, String)>[];
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'src',
                label: 'src',
                expanded: true,
                children: [
                  CoreTreeNode(id: 'src/main.dart', label: 'main.dart'),
                ],
              ),
              CoreTreeNode(id: 'test', label: 'test', canHaveChildren: true),
            ],
            onNodeDrop: (source, target) => moves.add((source.id!, target.id!)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('main.dart')),
      );
      await gesture.moveTo(tester.getCenter(find.text('test')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(moves, [('src/main.dart', 'test')]);
    });

    testWidgets('dropping between leaf rows targets their containing folder', (
      tester,
    ) async {
      final moves = <(String, String)>[];
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'root',
                label: 'root',
                expanded: true,
                children: [
                  CoreTreeNode(id: 'root/a.dart', label: 'a.dart'),
                  CoreTreeNode(
                    id: 'root/sub',
                    label: 'sub',
                    expanded: true,
                    children: [
                      CoreTreeNode(id: 'root/sub/b.dart', label: 'b.dart'),
                    ],
                  ),
                ],
              ),
            ],
            onNodeDrop: (source, directory) =>
                moves.add((source.id!, directory.id!)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('b.dart')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(
        tester.getTopLeft(find.text('a.dart')) + const Offset(3, 3),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(moves, [('root/sub/b.dart', 'root')]);
    });

    testWidgets(
      'drag proxy follows a row while an indented sibling slot opens',
      (
        tester,
      ) async {
        final placed = <(String, String, CoreTreeDropPosition, int)>[];
        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: const [
                CoreTreeNode(
                  id: 'root',
                  label: 'root',
                  expanded: true,
                  children: [
                    CoreTreeNode(id: 'root/a', label: 'a'),
                    CoreTreeNode(id: 'root/b', label: 'b'),
                    CoreTreeNode(
                      id: 'root/folder',
                      label: 'folder',
                      canHaveChildren: true,
                    ),
                  ],
                ),
              ],
              virtualRowHeight: 32,
              virtualViewportHeight: 200,
              canDragNode: (node) => node.id != 'root',
              onNodePlace: (source, target) => placed.add((
                source.id!,
                target.anchor.id!,
                target.position,
                target.depth,
              )),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DragOverlay), findsOneWidget);
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('a')),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(0, 48));
        await tester.pump();
        await gesture.moveTo(
          tester.getTopLeft(find.byKey(const Key('tree-node.root/b'))) +
              const Offset(12, 3),
        );
        await tester.pump();
        expect(
          tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .any(
                (container) => container.transform?.storage[13] == 32,
              ),
          isTrue,
        );
        await gesture.up();
        await tester.pumpAndSettle();
        expect(placed, [('root/a', 'root/b', CoreTreeDropPosition.before, 1)]);
      },
    );

    testWidgets('folder centre previews a child-level placement', (
      tester,
    ) async {
      CoreTreeDropTarget? target;
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'root',
                label: 'root',
                expanded: true,
                children: [
                  CoreTreeNode(id: 'root/a', label: 'a'),
                  CoreTreeNode(
                    id: 'root/folder',
                    label: 'folder',
                    canHaveChildren: true,
                  ),
                ],
              ),
            ],
            virtualRowHeight: 32,
            virtualViewportHeight: 160,
            onNodePlace: (_, into) => target = into,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('a')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('folder')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(target?.position, CoreTreeDropPosition.inside);
      expect(target?.directory.id, 'root/folder');
      expect(target?.depth, 2);
    });

    testWidgets('windowed after-last gap reserves the whole expanded subtree', (
      tester,
    ) async {
      final scroll = material.ScrollController();
      addTearDown(scroll.dispose);
      CoreTreeDropTarget? placed;
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'root',
                label: 'root',
                expanded: true,
                children: [
                  CoreTreeNode(
                    id: 'root/folder',
                    label: 'folder',
                    expanded: true,
                    children: [
                      CoreTreeNode(id: 'root/folder/a', label: 'first'),
                      CoreTreeNode(id: 'root/folder/b', label: 'second'),
                    ],
                  ),
                  CoreTreeNode(id: 'root/last', label: 'last'),
                ],
              ),
            ],
            virtualRowHeight: 32,
            virtualViewportHeight: 160,
            scrollController: scroll,
            canDragNode: (node) => node.id != 'root',
            onNodePlace: (_, target) => placed = target,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.position.viewportDimension, 160);
      expect(scroll.position.maxScrollExtent, 0);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('folder')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      await gesture.moveTo(
        tester.getBottomLeft(find.byKey(const Key('tree-node.root/last'))) +
            const Offset(12, -2),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<DragScope>(find.byType(DragScope))
          .controller!;
      expect(controller.session, isNotNull);
      expect(controller.overId, isNotNull);
      final hovered = controller.overId!.value;
      final sliverCount = tester
          .widget<material.CustomScrollView>(
            find.byType(material.CustomScrollView),
          )
          .slivers
          .length;
      // The source and its two visible descendants occupy three rows.
      final extent = scroll.position.maxScrollExtent;
      await gesture.up();
      await tester.pumpAndSettle();
      expect(hovered, endsWith('zone:root/last'));
      expect(placed?.position, CoreTreeDropPosition.after);
      expect(sliverCount, 2);
      expect(extent, 96);
      expect(scroll.position.maxScrollExtent, 0);
    });

    testWidgets(
      'external files target a folder or a leaf parent, never a bare root leaf',
      (
        tester,
      ) async {
        final destinations = <String>[];
        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: const [
                CoreTreeNode(
                  id: 'root',
                  label: 'root',
                  expanded: true,
                  children: [
                    CoreTreeNode(id: 'root/file', label: 'nested-file'),
                  ],
                ),
                CoreTreeNode(id: 'orphan', label: 'orphan'),
              ],
              onFilesDroppedOnNode: (files, target) {
                expect(files.single.name, 'new.txt');
                destinations.add(target.id!);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final zones = tester
            .widgetList<DropTarget>(find.byType(DropTarget))
            .toList();
        expect(zones, hasLength(2));
        zones[1].onDragEntered!(
          DropEventDetails(
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(
          tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .any(
                (box) =>
                    box.decoration is BoxDecoration &&
                    (box.decoration as BoxDecoration).border?.top.width ==
                        CoreStrokeWidth.stroke2,
              ),
          isTrue,
        );
        final details = DropDoneDetails(
          files: [
            DropItemFile('/tmp/new.txt'),
          ],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        );
        zones[0].onDragDone!(details);
        zones[1].onDragDone!(details);
        await tester.pump();
        expect(destinations, ['root', 'root']);
      },
    );

    testWidgets('external file above a leaf reports its insertion anchor', (
      tester,
    ) async {
      CoreTreeDropTarget? placed;
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'root',
                label: 'root',
                expanded: true,
                children: [
                  CoreTreeNode(id: 'root/a', label: 'a'),
                ],
              ),
            ],
            virtualRowHeight: 32,
            virtualViewportHeight: 120,
            onFilesPlaced: (files, target) {
              expect(files.single.name, 'new.txt');
              placed = target;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final leaf = tester.widgetList<DropTarget>(find.byType(DropTarget)).last;
      leaf.onDragEntered!(
        DropEventDetails(
          localPosition: const Offset(10, 2),
          globalPosition: const Offset(10, 2),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .any(
              (container) => container.transform?.storage[13] == 32,
            ),
        isTrue,
      );
      leaf.onDragDone!(
        DropDoneDetails(
          files: [DropItemFile('/tmp/new.txt')],
          localPosition: const Offset(10, 2),
          globalPosition: const Offset(10, 2),
        ),
      );
      await tester.pump();
      expect(placed?.position, CoreTreeDropPosition.before);
      expect(placed?.anchor.id, 'root/a');
      expect(placed?.directory.id, 'root');
    });

    testWidgets('a virtualized desktop tree can drag without scrolling', (
      tester,
    ) async {
      final requests = <(String, String)>[];
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'src',
                label: 'src',
                expanded: true,
                children: [
                  CoreTreeNode(id: 'file', label: 'file'),
                ],
              ),
              CoreTreeNode(id: 'dest', label: 'dest', canHaveChildren: true),
            ],
            virtualRowHeight: 24,
            virtualViewportHeight: 240,
            onNodeDrop: (from, into) => requests.add((from.id!, into.id!)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('file')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('dest')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(requests, [('file', 'dest')]);
    });

    testWidgets(
      'a trackpad two-finger swipe over a short tree never drops a row',
      (tester) async {
        final moves = <(String, String)>[];
        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: const [
                CoreTreeNode(
                  id: 'src',
                  label: 'src',
                  expanded: true,
                  children: [
                    CoreTreeNode(id: 'src/main.dart', label: 'main.dart'),
                  ],
                ),
                CoreTreeNode(id: 'test', label: 'test', canHaveChildren: true),
              ],
              onNodeDrop: (source, target) =>
                  moves.add((source.id!, target.id!)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The same travel as the drop test above — only the device differs.
        // Nothing here scrolls, so the row is the only gesture claimant.
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('main.dart')),
          kind: PointerDeviceKind.trackpad,
        );
        await gesture.moveBy(
          tester.getCenter(find.text('test')) -
              tester.getCenter(find.text('main.dart')),
        );
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(moves, isEmpty);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'a windowed tree scrolls under a trackpad swipe and never places a row',
      (tester) async {
        final placed = <String>[];
        final controller = material.ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: [
                CoreTreeNode(
                  id: 'root',
                  label: 'root',
                  expanded: true,
                  children: [
                    for (var i = 0; i < 40; i++)
                      CoreTreeNode(id: 'root/f$i', label: 'file $i'),
                  ],
                ),
              ],
              virtualRowHeight: 24,
              virtualViewportHeight: 240,
              scrollController: controller,
              canDragNode: (node) => node.id != 'root',
              onNodePlace: (source, target) => placed.add(source.id!),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> swipe(List<Offset> legs) async {
          final gesture = await tester.startGesture(
            tester.getCenter(find.text('file 3')),
            kind: PointerDeviceKind.trackpad,
          );
          for (final leg in legs) {
            for (var step = 0; step < 6; step++) {
              await gesture.moveBy(leg / 6);
              await tester.pump(const Duration(milliseconds: 16));
            }
          }
          await gesture.up();
          await tester.pumpAndSettle();
        }

        // A scroll that drifts sideways first: the list's vertical recognizer
        // never reaches its slop, which left the row's drag recognizer free to
        // win — and the rest of the swipe then carried the row two rows up.
        await swipe(const [Offset(40, 0), Offset(0, -54)]);
        expect(placed, isEmpty);

        await swipe(const [Offset(0, -120)]);
        expect(placed, isEmpty);
        expect(controller.offset, greaterThan(0));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('a display-only tree has no draggable rows', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Tree(
            nodes: [CoreTreeNode(id: 'file', label: 'file')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DragItem), findsNothing);
      expect(find.byType(DropZone), findsNothing);
    });
    testWidgets('lazy directory loads once, including an empty directory', (
      tester,
    ) async {
      final calls = <String>[];
      final completer = Completer<List<CoreTreeNode>>();
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(id: 'src', label: 'src', canHaveChildren: true),
            ],
            loadChildren: (node) {
              calls.add(node.id!);
              return completer.future;
            },
          ),
        ),
      );
      await tester.tap(find.text('src'));
      await tester.pump();
      expect(calls, ['src']);
      expect(find.text('Loading'), findsOneWidget);

      completer.complete(const []);
      await tester.pumpAndSettle();
      await tester.tap(find.text('src')); // collapse
      await tester.pumpAndSettle();
      await tester.tap(find.text('src')); // expand cached empty branch
      await tester.pumpAndSettle();
      expect(calls, ['src']);
      expect(
        find.byKey(const material.ValueKey('tree-node.src')),
        findsOneWidget,
      );
    });

    testWidgets('pre-expanded lazy branch loads after mounting', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'src',
                label: 'src',
                canHaveChildren: true,
                expanded: true,
              ),
            ],
            loadChildren: (_) async {
              calls++;
              return const [CoreTreeNode(label: 'file.dart')];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('file.dart'), findsOneWidget);
    });

    testWidgets(
      'failed load is visible and can retry without resetting selection',
      (
        tester,
      ) async {
        var count = 0;
        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: const [
                CoreTreeNode(id: 'src', label: 'src', canHaveChildren: true),
              ],
              selectFolders: true,
              onNodeSelect: (_) {},
              loadChildren: (_) async {
                count++;
                if (count == 1) throw StateError('offline');
                return const [CoreTreeNode(id: 'file', label: 'a.dart')];
              },
            ),
          ),
        );
        await tester.tap(
          find.byKey(const material.ValueKey('tree-node.toggle.src')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Unable to load · Retry'), findsOneWidget);
        await tester.tap(find.text('Unable to load · Retry'));
        await tester.pumpAndSettle();
        expect(find.text('a.dart'), findsOneWidget);
        expect(count, 2);
      },
    );

    testWidgets(
      'windowed tree builds only visible rows and preserves stable keys',
      (
        tester,
      ) async {
        var rendered = 0;
        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: [
                for (var i = 0; i < 1000; i++)
                  CoreTreeNode(id: '$i', label: '$i'),
              ],
              virtualRowHeight: 32,
              virtualViewportHeight: 160,
              leadingBuilder: (context, node, {required expanded}) {
                rendered++;
                return const Text('icon');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(rendered, lessThan(30));
        expect(
          find.byKey(const material.ValueKey('tree-node.0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const material.ValueKey('tree-node.999')),
          findsNothing,
        );
      },
    );
    testWidgets('renders top-level node labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Tree(
            nodes: [
              CoreTreeNode(label: 'Documents'),
              CoreTreeNode(label: 'Pictures'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Tree), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Pictures'), findsOneWidget);
    });

    testWidgets('shows children of an expanded node', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Tree(
            nodes: [
              CoreTreeNode(
                label: 'Root',
                expanded: true,
                children: [CoreTreeNode(label: 'Leaf')],
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Leaf'), findsOneWidget);
    });

    testWidgets('onNodeSelect / onNodeToggle callbacks are wired up', (
      tester,
    ) async {
      CoreTreeNode? selected;
      CoreTreeNode? toggled;

      await tester.pumpWidget(
        _buildApp(
          Tree(
            onNodeSelect: (node) => selected = node,
            onNodeToggle: (node) => toggled = node,
            nodes: const [CoreTreeNode(label: 'Item')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Tree), findsOneWidget);
      expect(selected, isNull);
      expect(toggled, isNull);
    });

    testWidgets('parent tap toggles and does not select by default', (
      tester,
    ) async {
      CoreTreeNode? selected;

      await tester.pumpWidget(
        _buildApp(
          Tree(
            onNodeSelect: (node) => selected = node,
            nodes: const [
              CoreTreeNode(
                label: 'Root',
                children: [CoreTreeNode(label: 'Leaf')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leaf'), findsNothing);
      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();

      expect(find.text('Leaf'), findsOneWidget);
      expect(selected, isNull);
    });

    testWidgets('selectFolders selects parent label and chevron toggles', (
      tester,
    ) async {
      CoreTreeNode? selected;

      await tester.pumpWidget(
        _buildApp(
          Tree(
            selectFolders: true,
            onNodeSelect: (node) => selected = node,
            nodes: const [
              CoreTreeNode(
                label: 'Root',
                children: [CoreTreeNode(label: 'Leaf')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();

      expect(selected?.label, equals('Root'));
      expect(find.text('Leaf'), findsNothing);

      await tester.tap(find.byKey(const Key('tree-chevron-Root')));
      await tester.pumpAndSettle();

      expect(find.text('Leaf'), findsOneWidget);
    });

    testWidgets(
      'toggleFoldersOnSelect selects and toggles from the whole row; the '
      'chevron still only toggles',
      (tester) async {
        final selected = <String>[];
        final toggled = <String>[];

        await tester.pumpWidget(
          _buildApp(
            Tree(
              selectFolders: true,
              toggleFoldersOnSelect: true,
              onNodeSelect: (node) => selected.add(node.label),
              onNodeToggle: (node) => toggled.add(node.label),
              nodes: const [
                CoreTreeNode(
                  label: 'Root',
                  children: [CoreTreeNode(label: 'Leaf')],
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Root'));
        await tester.pumpAndSettle();

        expect(selected, ['Root']);
        expect(toggled, ['Root']);
        expect(find.text('Leaf'), findsOneWidget);

        await tester.tap(find.text('Root'));
        await tester.pumpAndSettle();

        expect(selected, ['Root', 'Root']);
        expect(find.text('Leaf'), findsNothing);

        await tester.tap(find.byKey(const Key('tree-chevron-Root')));
        await tester.pumpAndSettle();

        expect(selected, ['Root', 'Root'], reason: 'chevron never selects');
        expect(toggled, ['Root', 'Root', 'Root']);
        expect(find.text('Leaf'), findsOneWidget);
      },
    );

    testWidgets('toggleFoldersOnSelect without selectFolders changes nothing', (
      tester,
    ) async {
      CoreTreeNode? selected;

      await tester.pumpWidget(
        _buildApp(
          Tree(
            toggleFoldersOnSelect: true,
            onNodeSelect: (node) => selected = node,
            nodes: const [
              CoreTreeNode(
                label: 'Root',
                children: [CoreTreeNode(label: 'Leaf')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();

      expect(find.text('Leaf'), findsOneWidget);
      expect(selected, isNull);
    });

    testWidgets(
      'expansionControlled follows node.expanded and does not self-toggle',
      (
        tester,
      ) async {
        var expanded = false;
        CoreTreeNode? toggled;

        Widget buildTree() => _buildApp(
          Tree(
            expansionControlled: true,
            onNodeToggle: (node) => toggled = node,
            nodes: [
              CoreTreeNode(
                label: 'Root',
                expanded: expanded,
                children: const [CoreTreeNode(label: 'Leaf')],
              ),
            ],
          ),
        );

        await tester.pumpWidget(buildTree());
        await tester.pumpAndSettle();
        expect(find.text('Leaf'), findsNothing);

        await tester.tap(find.text('Root'));
        await tester.pumpAndSettle();
        expect(toggled?.label, equals('Root'));
        expect(find.text('Leaf'), findsNothing);

        expanded = true;
        await tester.pumpWidget(buildTree());
        await tester.pumpAndSettle();
        expect(find.text('Leaf'), findsOneWidget);
      },
    );
  });
}
