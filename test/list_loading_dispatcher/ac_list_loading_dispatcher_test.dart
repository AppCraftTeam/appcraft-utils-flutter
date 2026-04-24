// ignore_for_file: cascade_invocations, unused_element_parameter, prefer_const_constructors
import 'dart:async';

import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_dispatcher.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_params.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_parser.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_state.dart';
import 'package:test/test.dart';

import 'helpers/fake_loader.dart';

/// Minimal implementation of [ACListLoadingParamsMixin] used only in tests.
///
/// The dispatcher itself reads only [query] (for search logic, which is out of
/// US1 scope); [limit] and [offset] are carried along for symmetry with the
/// public contract and to exercise generic constraints.
final class _TestParams with ACListLoadingParamsMixin {
  const _TestParams({this.limit, this.offset, this.query});

  @override
  final int? limit;
  @override
  final int? offset;
  @override
  final String? query;
}

/// Default parser used in most tests: items are passed through verbatim and
/// `hasMore` is derived from list length (>= 2 means "more likely").
ACParseResult<int> _listParser(List<int> response) => ACParseResult<int>(
  items: response,
  hasMore: response.length >= 2,
);

/// Builds the standard dispatcher used by tests.
ACListLoadingDispatcher<int, List<int>> _buildDispatcher({
  ACListLoadingParser<int, List<int>>? parser,
}) =>
    ACListLoadingDispatcher<int, List<int>>(
      parser: parser ?? _listParser,
    );

void main() {
  group('ACListLoadingDispatcher — basic pagination (US1)', () {
    late ACListLoadingDispatcher<int, List<int>> dispatcher;
    late FakeLoader<List<int>> loader;

    setUp(() {
      dispatcher = _buildDispatcher();
      loader = FakeLoader<List<int>>();
    });

    tearDown(() async {
      await dispatcher.dispose();
    });

    test('initial getters expose empty items, not loading, hasMore=true, '
        'error=null', () {
      // Arrange & Act — dispatcher built in setUp.

      // Assert
      expect(dispatcher.items, isEmpty);
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.hasMore, isTrue);
      expect(dispatcher.error, isNull);
    });

    test('items getter returns an unmodifiable view', () {
      // Arrange
      final items = dispatcher.items;

      // Act & Assert
      expect(() => items.add(42), throwsUnsupportedError);
    });

    test('notifier replays the initial snapshot to a late subscriber '
        '(resendLastEvent=true)', () async {
      // Arrange
      final received = <ACListLoadingState<int>>[];

      // Act
      final sub = dispatcher.notifier.listen(received.add);
      // Allow the microtask/stream machinery to deliver the replayed event.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Assert
      expect(received, isNotEmpty, reason: 'initial snapshot should be delivered');
      final snapshot = received.first;
      expect(snapshot.items, isEmpty);
      expect(snapshot.isLoading, isFalse);
      expect(snapshot.hasMore, isTrue);
      expect(snapshot.error, isNull);
    });

    test('reload success replaces items, updates hasMore and toggles '
        'isLoading through true then back to false', () async {
      // Arrange
      loader.enqueueValue(<int>[1, 2, 3]);
      final loadingSamples = <bool>[];
      final sub = dispatcher.notifier.listen(
        (state) => loadingSamples.add(state.isLoading),
      );

      // Act
      final future = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // Between start and completion the dispatcher must be loading.
      expect(dispatcher.isLoading, isTrue);
      await future;
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Assert
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
      expect(dispatcher.hasMore, isTrue);
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.error, isNull);
      expect(loader.callCount, 1);
      // The emitted sequence must have contained an isLoading=true snapshot
      // followed by a final isLoading=false snapshot.
      expect(loadingSamples, contains(true));
      expect(loadingSamples.last, isFalse);
    });

    test('reload success emits a snapshot carrying the new items via notifier',
        () async {
      // Arrange
      loader.enqueueValue(<int>[10, 20]);
      final received = <ACListLoadingState<int>>[];
      final sub = dispatcher.notifier.listen(received.add);

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Assert
      expect(
        received.any((s) =>
            s.items.length == 2 &&
            s.items[0] == 10 &&
            s.items[1] == 20 &&
            s.isLoading == false),
        isTrue,
        reason: 'terminal snapshot with new items must be emitted',
      );
    });

    test('reload with a single-item response sets hasMore=false via parser',
        () async {
      // Arrange — _listParser treats length < 2 as "no more".
      loader.enqueueValue(<int>[42]);

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.items, equals(<int>[42]));
      expect(dispatcher.hasMore, isFalse);
    });

    test('loadMore success appends items at the end and updates hasMore',
        () async {
      // Arrange — first reload, then loadMore.
      loader.enqueueValue(<int>[1, 2]);
      loader.enqueueValue(<int>[3, 4]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Act
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.items, equals(<int>[1, 2, 3, 4]));
      expect(dispatcher.hasMore, isTrue);
      expect(loader.callCount, 2);
    });

    test('loadMore with a partial page (single item) flips hasMore to false '
        'and still appends', () async {
      // Arrange
      loader.enqueueValue(<int>[1, 2]);
      loader.enqueueValue(<int>[3]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Act
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
      expect(dispatcher.hasMore, isFalse);
    });

    test('loadMore is a no-op when hasMore=false — loader is not invoked',
        () async {
      // Arrange — after reload with a single item hasMore becomes false.
      loader.enqueueValue(<int>[1]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      final callsBefore = loader.callCount;
      final itemsBefore = List<int>.from(dispatcher.items);
      expect(dispatcher.hasMore, isFalse);

      // Act
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 1),
        load: loader.call,
      );

      // Assert
      expect(loader.callCount, equals(callsBefore),
          reason: 'loader must not be invoked when hasMore=false');
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, isFalse);
    });

    test('loadMore while another loadMore is already in flight is a no-op',
        () async {
      // Arrange — seed items + hasMore=true via reload.
      loader.enqueueValue(<int>[1, 2]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // The in-flight loadMore will block on a manual completer.
      final gate = Completer<List<int>>();
      Future<List<int>> slowLoad(_TestParams _) => gate.future;
      final gatedLoader = FakeLoader<List<int>>();
      gatedLoader.enqueueValue(<int>[9, 9]);

      // Act — start one loadMore (stuck on `gate`), then attempt a second.
      final firstFuture = dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: slowLoad,
      );
      expect(dispatcher.isLoading, isTrue);
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: gatedLoader.call,
      );

      // Release the first loadMore.
      gate.complete(<int>[3, 4]);
      await firstFuture;

      // Assert
      expect(gatedLoader.callCount, 0,
          reason: 'concurrent loadMore must not invoke the second loader');
      expect(dispatcher.items, equals(<int>[1, 2, 3, 4]));
    });

    test('reload cancels a prior in-flight reload: only the second result '
        'lands in items', () async {
      // Arrange — block the first loader on a completer; it should be
      // ignored when the second reload wins.
      final firstGate = Completer<List<int>>();
      Future<List<int>> firstLoad(_TestParams _) => firstGate.future;
      final secondLoader = FakeLoader<List<int>>();
      secondLoader.enqueueValue(<int>[9, 8, 7]);

      // Act
      final firstFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: firstLoad,
      );
      // Second reload starts while the first is still pending.
      final secondFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: secondLoader.call,
      );
      // Let the first loader finally resolve — its result must be ignored.
      firstGate.complete(<int>[1, 1, 1]);
      await Future.wait(<Future<void>>[firstFuture, secondFuture]);

      // Assert
      expect(dispatcher.items, equals(<int>[9, 8, 7]));
      expect(dispatcher.isLoading, isFalse);
    });

    test('reload cancels an in-flight loadMore: only the reload result is '
        'authoritative', () async {
      // Arrange — first a successful reload to get non-empty items.
      loader.enqueueValue(<int>[1, 2]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // Start a slow loadMore.
      final loadMoreGate = Completer<List<int>>();
      Future<List<int>> slowLoadMore(_TestParams _) => loadMoreGate.future;
      // The reload that should win.
      final reloadLoader = FakeLoader<List<int>>();
      reloadLoader.enqueueValue(<int>[100, 200]);

      // Act
      final loadMoreFuture = dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: slowLoadMore,
      );
      final reloadFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: reloadLoader.call,
      );
      // Resolve the loadMore after reload has already overtaken it.
      loadMoreGate.complete(<int>[3, 4]);
      await Future.wait(<Future<void>>[loadMoreFuture, reloadFuture]);

      // Assert — reload replaces items; loadMore result is discarded.
      expect(dispatcher.items, equals(<int>[100, 200]));
      expect(dispatcher.isLoading, isFalse);
    });
  });

  group('ACListLoadingDispatcher — errors (US1)', () {
    late ACListLoadingDispatcher<int, List<int>> dispatcher;
    late FakeLoader<List<int>> loader;

    setUp(() {
      dispatcher = _buildDispatcher();
      loader = FakeLoader<List<int>>();
    });

    tearDown(() async {
      await dispatcher.dispose();
    });

    test('reload does not rethrow loader exceptions; error is stored, '
        'isLoading reset to false', () async {
      // Arrange
      final failure = Exception('network down');
      loader.enqueueError(failure);

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.error, same(failure));
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.items, isEmpty,
          reason: 'items remain as they were before the failed reload');
    });

    test('reload error on a populated list preserves previous items',
        () async {
      // Arrange — first successful reload seeds items.
      loader.enqueueValue(<int>[1, 2, 3]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // Next call fails.
      final failure = StateError('boom');
      loader.enqueueError(failure);

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.error, same(failure));
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
      expect(dispatcher.isLoading, isFalse);
    });

    test('a subsequent successful reload clears the previous error and '
        'replaces items', () async {
      // Arrange — first fail.
      loader.enqueueError(Exception('first fail'));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      expect(dispatcher.error, isNotNull);
      // Then succeed.
      loader.enqueueValue(<int>[7, 8, 9]);

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.error, isNull);
      expect(dispatcher.items, equals(<int>[7, 8, 9]));
    });

    test('parser exception is treated like a loader error — error set, '
        'items preserved', () async {
      // Arrange — seed items through a normal reload.
      loader.enqueueValue(<int>[1, 2]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      expect(dispatcher.items, equals(<int>[1, 2]));

      // Build a new dispatcher whose parser always throws. We dispose the
      // original in tearDown; the local one also needs a dispose at the end.
      final parserError = FormatException('bad response');
      final throwingDispatcher = ACListLoadingDispatcher<int, List<int>>(
        parser: (List<int> _) => throw parserError,
      );
      final throwingLoader = FakeLoader<List<int>>();
      throwingLoader.enqueueValue(<int>[1, 2]);

      // Act
      await throwingDispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: throwingLoader.call,
      );

      // Assert
      expect(throwingDispatcher.error, same(parserError));
      expect(throwingDispatcher.items, isEmpty,
          reason: 'no successful items were ever installed on this dispatcher');
      expect(throwingDispatcher.isLoading, isFalse);

      await throwingDispatcher.dispose();
    });

    test('loadMore error keeps previous items and hasMore as they were',
        () async {
      // Arrange — seed a two-item list (hasMore=true via _listParser).
      loader.enqueueValue(<int>[1, 2]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;
      // Next loadMore fails.
      final failure = Exception('load more failed');
      loader.enqueueError(failure);

      // Act
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.error, same(failure));
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));
      expect(dispatcher.isLoading, isFalse);
    });
  });

  group('ACListLoadingDispatcher — dispose & cancel safety (US1)', () {
    test('dispose() while a reload is in flight: the pending result is '
        'ignored; no emit after dispose; notifier is closed', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final gate = Completer<List<int>>();
      Future<List<int>> gatedLoad(_TestParams _) => gate.future;
      final received = <ACListLoadingState<int>>[];
      final sub = dispatcher.notifier.listen(received.add);

      // Act
      final reloadFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: gatedLoad,
      );
      await dispatcher.dispose();
      final countAfterDispose = received.length;
      // Release the pending loader — its result must be ignored post-dispose.
      gate.complete(<int>[1, 2, 3]);
      await reloadFuture;
      // Let any residual microtasks drain.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // Assert — no new events after dispose.
      expect(received.length, equals(countAfterDispose),
          reason: 'dispatcher must not emit after dispose()');
      expect(dispatcher.items, isEmpty,
          reason: 'late loader result must not mutate items after dispose');
      expect(dispatcher.error, isNull);
    });

    test('repeated dispose() is a no-op (does not throw)', () async {
      // Arrange
      final dispatcher = _buildDispatcher();

      // Act & Assert
      await dispatcher.dispose();
      await expectLater(dispatcher.dispose(), completes);
      await expectLater(dispatcher.dispose(), completes);
    });

    test('cancel() with no active load is a no-op; state unchanged',
        () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;
      final errorBefore = dispatcher.error;

      // Act & Assert
      await expectLater(dispatcher.cancel(), completes);
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));
      expect(dispatcher.error, equals(errorBefore));

      await dispatcher.dispose();
    });

    test('cancel() with an active load: isLoading becomes false; items and '
        'hasMore are not touched; pending result is ignored', () async {
      // Arrange — seed a known list first.
      final dispatcher = _buildDispatcher();
      final seedLoader = FakeLoader<List<int>>();
      seedLoader.enqueueValue(<int>[1, 2]);
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: seedLoader.call,
      );
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;
      // Now start a loadMore that is cancelled before completion.
      final gate = Completer<List<int>>();
      Future<List<int>> gatedLoad(_TestParams _) => gate.future;

      // Act
      final loadMoreFuture = dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: gatedLoad,
      );
      expect(dispatcher.isLoading, isTrue);
      await dispatcher.cancel();
      // Complete the loader after cancel — result must be ignored.
      gate.complete(<int>[9, 9, 9]);
      await loadMoreFuture;

      // Assert
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));

      await dispatcher.dispose();
    });

    test('public methods after dispose are safe: reload, loadMore, cancel '
        'do not throw and do not mutate state', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      await dispatcher.dispose();
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;
      final errorBefore = dispatcher.error;
      final isLoadingBefore = dispatcher.isLoading;
      final postDisposeLoader = FakeLoader<List<int>>();
      postDisposeLoader.enqueueValue(<int>[1, 2, 3]);

      // Act & Assert — none of these should throw.
      await expectLater(
        dispatcher.reload<_TestParams>(
          params: const _TestParams(),
          load: postDisposeLoader.call,
        ),
        completes,
      );
      await expectLater(
        dispatcher.loadMore<_TestParams>(
          params: const _TestParams(),
          load: postDisposeLoader.call,
        ),
        completes,
      );
      await expectLater(dispatcher.cancel(), completes);

      // State must remain exactly as it was post-dispose.
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));
      expect(dispatcher.error, equals(errorBefore));
      expect(dispatcher.isLoading, equals(isLoadingBefore));
    });
  });
}
