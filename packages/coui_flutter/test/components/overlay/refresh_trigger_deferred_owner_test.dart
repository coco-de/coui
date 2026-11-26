import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../parity/parity_fonts.dart';

final _rows = <Map<String, Object?>>[];

Widget _app(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Theme(
    data: ThemeData.fromCore(CoreThemePresets.light),
    child: Center(child: SizedBox(width: 240, height: 160, child: child)),
  ),
);

class _Child extends StatefulWidget {
  const _Child({super.key, required this.onMount, required this.onDispose});
  final VoidCallback onMount;
  final VoidCallback onDispose;
  @override
  State<_Child> createState() => _ChildState();
}

class _ChildState extends State<_Child> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 80, height: 24);
}

class _ObservedFuture {
  _ObservedFuture(Future<void> future) {
    completion = future.then<void>(
      (_) => completed = true,
      onError: (Object error, StackTrace stack) {
        failure = error;
        failureStack = stack;
        completed = true;
      },
    );
  }

  late final Future<void> completion;
  bool completed = false;
  Object? failure;
  StackTrace? failureStack;

  Map<String, Object?> toJson() => {
    'completed': completed,
    'errorType': failure?.runtimeType.toString(),
    'error': failure?.toString(),
    'stack': failureStack?.toString(),
  };
}

void main() {
  setUpAll(loadParityFonts);
  tearDownAll(() {
    final path = Platform.environment['NATIVE_REFRESH_OBSERVATIONS'];
    if (path != null) {
      File(path).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(_rows)}\n',
      );
    }
  });

  testWidgets('queued refresh does not resume a disposed owner', (
    tester,
  ) async {
    final key = GlobalKey<RefreshTriggerState>();
    final firstWork = Completer<void>();
    var callbacks = 0;
    var disposed = false;
    final callbackAfterDispose = <bool>[];
    await tester.pumpWidget(
      _app(
        RefreshTrigger(
          key: key,
          onRefresh: () {
            callbacks++;
            callbackAfterDispose.add(disposed);
            return callbacks == 1 ? firstWork.future : Future<void>.value();
          },
          child: const SizedBox(width: 80, height: 24),
        ),
      ),
    );
    final mountedOwner = key.currentState!;
    final first = _ObservedFuture(mountedOwner.refresh());
    final queued = _ObservedFuture(mountedOwner.refresh());
    expect(mountedOwner.mounted, isTrue);
    expect(callbacks, 1);
    expect(first.completed, isFalse);
    expect(queued.completed, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    disposed = true;
    expect(mountedOwner.mounted, isFalse);
    expect(key.currentState, isNull);
    firstWork.complete();
    await tester.pump();
    await first.completion;
    await queued.completion;
    final frameworkError = tester.takeException();
    _rows.add({
      'case': 'queued-dispose',
      'refreshCallsMadeWhileMounted': 2,
      'actualOwnerRemovedBeforeFirstCompletion': !mountedOwner.mounted,
      'callbacks': callbacks,
      'callbackAfterDispose': callbackAfterDispose,
      'first': first.toJson(),
      'queued': queued.toJson(),
      'frameworkException': frameworkError?.toString(),
    });
    expect(frameworkError, isNull);
    expect(first.failure, isNull);
    expect(queued.failure, isNull);
    expect(callbackAfterDispose, [false]);
  });

  testWidgets('mounted queued refresh retains two callbacks and child', (
    tester,
  ) async {
    final key = GlobalKey<RefreshTriggerState>();
    final childKey = GlobalKey();
    final firstWork = Completer<void>();
    final secondWork = Completer<void>();
    var callbacks = 0;
    var mounts = 0;
    var disposals = 0;
    await tester.pumpWidget(
      _app(
        RefreshTrigger(
          key: key,
          onRefresh: () =>
              ++callbacks == 1 ? firstWork.future : secondWork.future,
          child: _Child(
            key: childKey,
            onMount: () => mounts++,
            onDispose: () => disposals++,
          ),
        ),
      ),
    );
    final owner = key.currentState!;
    final child = childKey.currentContext!;
    final first = _ObservedFuture(owner.refresh());
    final queued = _ObservedFuture(owner.refresh());
    expect(callbacks, 1);
    await tester.pump();
    firstWork.complete();
    await tester.pump();
    if (!child.mounted) {
      throw StateError('Mounted queue disposed its child');
    }
    expect(callbacks, 2);
    expect(key.currentState, same(owner));
    expect(childKey.currentContext, same(child));
    expect(mounts, 1);
    expect(disposals, 0);
    secondWork.complete();
    await tester.pump();
    await first.completion;
    await queued.completion;
    expect(first.failure, isNull);
    expect(queued.failure, isNull);
    expect(tester.takeException(), isNull);
    if (!child.mounted) {
      throw StateError('Completed mounted queue disposed its child');
    }
    _rows.add({
      'case': 'mounted-queue',
      'callbacks': callbacks,
      'sameState': identical(key.currentState, owner),
      'sameChildElement': identical(childKey.currentContext, child),
      'childMounts': mounts,
      'childDisposalsBeforeRemoval': disposals,
      'first': first.toJson(),
      'queued': queued.toJson(),
    });
    await tester.pumpWidget(const SizedBox.shrink());
    expect(disposals, 1);
  });

  testWidgets('single pending refresh can complete after removal', (
    tester,
  ) async {
    final key = GlobalKey<RefreshTriggerState>();
    final work = Completer<void>();
    var callbacks = 0;
    await tester.pumpWidget(
      _app(
        RefreshTrigger(
          key: key,
          onRefresh: () {
            callbacks++;
            return work.future;
          },
          child: const SizedBox(width: 80, height: 24),
        ),
      ),
    );
    final owner = key.currentState!;
    final first = _ObservedFuture(owner.refresh());
    await tester.pumpWidget(const SizedBox.shrink());
    expect(owner.mounted, isFalse);
    work.complete();
    await tester.pump();
    await first.completion;
    _rows.add({
      'case': 'single-pending-dispose',
      'callbacks': callbacks,
      'ownerMounted': owner.mounted,
      'first': first.toJson(),
    });
    expect(callbacks, 1);
    expect(first.failure, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('queued wait preserves original future error', (tester) async {
    final key = GlobalKey<RefreshTriggerState>();
    final work = Completer<void>();
    final sentinel = StateError('owned refresh failure');
    var callbacks = 0;
    await tester.pumpWidget(
      _app(
        RefreshTrigger(
          key: key,
          onRefresh: () {
            callbacks++;
            return work.future;
          },
          child: const SizedBox(width: 80, height: 24),
        ),
      ),
    );
    final owner = key.currentState!;
    final first = _ObservedFuture(owner.refresh());
    final queued = _ObservedFuture(owner.refresh());
    work.completeError(sentinel, StackTrace.current);
    await tester.pump();
    await first.completion;
    await queued.completion;
    _rows.add({
      'case': 'queued-original-error',
      'callbacks': callbacks,
      'firstSameError': identical(first.failure, sentinel),
      'queuedSameError': identical(queued.failure, sentinel),
      'first': first.toJson(),
      'queued': queued.toJson(),
    });
    expect(callbacks, 1);
    expect(first.failure, same(sentinel));
    expect(queued.failure, same(sentinel));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
