// ignore_for_file: cascade_invocations, unused_element_parameter, prefer_const_constructors
import 'dart:async';

import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_dispatcher.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_params.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_loader.dart';

/// Minimal implementation of [ACListLoadingParamsMixin] used only in tests.
///
/// The dispatcher reads only [query]; [limit] and [offset] are carried along
/// for symmetry with the public contract.
final class _TestParams with ACListLoadingParamsMixin {
  const _TestParams({this.limit, this.offset, this.query});

  @override
  final int? limit;
  @override
  final int? offset;
  @override
  final String? query;
}

/// Minimal [ACListLoadingResult] implementation — mirrors what consumers will
/// mix into their own response DTOs.
final class _TestPage<T> with ACListLoadingResult<T> {
  const _TestPage(this.items, {this.hasMore = true});

  @override
  final List<T> items;
  @override
  final bool hasMore;
}

ACListLoadingDispatcher<int> _buildDispatcher() =>
    ACListLoadingDispatcher<int>();

void main() {
  group('ACListLoadingDispatcher — basic pagination (US1)', () {
    late ACListLoadingDispatcher<int> dispatcher;
    late FakeLoader<ACListLoadingResult<int>> loader;

    setUp(() {
      dispatcher = _buildDispatcher();
      loader = FakeLoader<ACListLoadingResult<int>>();
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('initial getters: items empty, isLoading=false, hasMore=true', () {
      // Arrange & Act — dispatcher built in setUp.

      // Assert
      expect(dispatcher.items, isEmpty);
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.hasMore, isTrue);
    });

    test('is a ChangeNotifier / Listenable', () {
      // Arrange & Act & Assert
      expect(dispatcher, isA<ChangeNotifier>());
      expect(dispatcher, isA<Listenable>());
    });

    test('items getter returns an unmodifiable view', () {
      // Arrange
      final items = dispatcher.items;

      // Act & Assert
      expect(() => items.add(42), throwsUnsupportedError);
    });

    test('reload success replaces items and updates hasMore', () async {
      // Arrange
      loader.enqueueValue(_TestPage<int>(<int>[1, 2, 3], hasMore: true));

      // Act
      final future = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // Between start and completion the dispatcher must be loading.
      expect(dispatcher.isLoading, isTrue);
      await future;

      // Assert
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
      expect(dispatcher.hasMore, isTrue);
      expect(dispatcher.isLoading, isFalse);
      expect(loader.callCount, 1);
    });

    test('reload with hasMore=false in response propagates into getter',
        () async {
      // Arrange
      loader.enqueueValue(_TestPage<int>(<int>[42], hasMore: false));

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
      // Arrange — first reload seeds the list, then loadMore extends it.
      loader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      loader.enqueueValue(_TestPage<int>(<int>[3, 4], hasMore: true));
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

    test('loadMore with hasMore=false from loader appends and flips hasMore',
        () async {
      // Arrange
      loader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      loader.enqueueValue(_TestPage<int>(<int>[3], hasMore: false));
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
      // Arrange — seed hasMore=false.
      loader.enqueueValue(_TestPage<int>(<int>[1], hasMore: false));
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

    test('loadMore while another load is already in flight is a no-op',
        () async {
      // Arrange — seed items + hasMore=true.
      loader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // The first loadMore will block on a gate.
      final gate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> slowLoad(_TestParams _) => gate.future;
      final secondLoader = FakeLoader<ACListLoadingResult<int>>();
      secondLoader.enqueueValue(_TestPage<int>(<int>[9, 9], hasMore: true));

      // Act — start one loadMore, then try a second concurrently.
      final firstFuture = dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: slowLoad,
      );
      expect(dispatcher.isLoading, isTrue);
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: secondLoader.call,
      );

      // Release the first loadMore.
      gate.complete(_TestPage<int>(<int>[3, 4], hasMore: true));
      await firstFuture;

      // Assert
      expect(secondLoader.callCount, 0,
          reason: 'concurrent loadMore must not invoke the second loader');
      expect(dispatcher.items, equals(<int>[1, 2, 3, 4]));
    });

    test('reload cancels a prior in-flight reload: only the second result '
        'lands in items', () async {
      // Arrange — the first loader blocks on a completer; its result must be
      // discarded in favour of the second reload.
      final firstGate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> firstLoad(_TestParams _) =>
          firstGate.future;
      final secondLoader = FakeLoader<ACListLoadingResult<int>>();
      secondLoader.enqueueValue(_TestPage<int>(<int>[9, 8, 7], hasMore: true));

      // Act
      final firstFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: firstLoad,
      );
      final secondFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: secondLoader.call,
      );
      // Let the first loader finally resolve — result must be ignored.
      firstGate.complete(_TestPage<int>(<int>[1, 1, 1], hasMore: true));
      await Future.wait(<Future<void>>[firstFuture, secondFuture]);

      // Assert
      expect(dispatcher.items, equals(<int>[9, 8, 7]));
      expect(dispatcher.isLoading, isFalse);
    });

    test('reload cancels an in-flight loadMore: only reload result stands',
        () async {
      // Arrange — seed non-empty items.
      loader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // Start a slow loadMore.
      final loadMoreGate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> slowLoadMore(_TestParams _) =>
          loadMoreGate.future;
      // The reload that should win.
      final reloadLoader = FakeLoader<ACListLoadingResult<int>>();
      reloadLoader.enqueueValue(
        _TestPage<int>(<int>[100, 200], hasMore: true),
      );

      // Act
      final loadMoreFuture = dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: slowLoadMore,
      );
      final reloadFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: reloadLoader.call,
      );
      loadMoreGate.complete(_TestPage<int>(<int>[3, 4], hasMore: true));
      await Future.wait(<Future<void>>[loadMoreFuture, reloadFuture]);

      // Assert — reload replaces items; loadMore result is discarded.
      expect(dispatcher.items, equals(<int>[100, 200]));
      expect(dispatcher.isLoading, isFalse);
    });
  });

  group('ACListLoadingDispatcher — errors (US1)', () {
    late ACListLoadingDispatcher<int> dispatcher;
    late FakeLoader<ACListLoadingResult<int>> loader;

    setUp(() {
      dispatcher = _buildDispatcher();
      loader = FakeLoader<ACListLoadingResult<int>>();
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('reload rethrows loader exceptions; items preserved, isLoading reset',
        () async {
      // Arrange
      final failure = Exception('network down');
      loader.enqueueError(failure);

      // Act & Assert — reload must propagate the error to the caller.
      await expectLater(
        dispatcher.reload<_TestParams>(
          params: const _TestParams(),
          load: loader.call,
        ),
        throwsA(same(failure)),
      );

      // Assert — state after the failure.
      expect(dispatcher.items, isEmpty,
          reason: 'items remain as they were before the failed reload');
      expect(dispatcher.isLoading, isFalse,
          reason: 'isLoading must be reset via try/finally');
    });

    test('reload error on a populated list preserves previous items',
        () async {
      // Arrange — first successful reload seeds items.
      loader.enqueueValue(_TestPage<int>(<int>[1, 2, 3], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      // Next call fails.
      final failure = StateError('boom');
      loader.enqueueError(failure);

      // Act & Assert — reload throws.
      await expectLater(
        dispatcher.reload<_TestParams>(
          params: const _TestParams(),
          load: loader.call,
        ),
        throwsA(same(failure)),
      );

      // Assert — previous items stay.
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
      expect(dispatcher.isLoading, isFalse);
    });

    test('a subsequent successful reload replaces items after an error',
        () async {
      // Arrange — first fail.
      final failure = Exception('first fail');
      loader.enqueueError(failure);
      await expectLater(
        dispatcher.reload<_TestParams>(
          params: const _TestParams(),
          load: loader.call,
        ),
        throwsA(same(failure)),
      );

      // Then succeed.
      loader.enqueueValue(_TestPage<int>(<int>[7, 8, 9], hasMore: true));

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.items, equals(<int>[7, 8, 9]));
      expect(dispatcher.isLoading, isFalse);
    });

    test('loadMore rethrows; previous items and hasMore are preserved',
        () async {
      // Arrange — seed a two-item list (hasMore=true).
      loader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;
      // Next loadMore fails.
      final failure = Exception('load more failed');
      loader.enqueueError(failure);

      // Act & Assert
      await expectLater(
        dispatcher.loadMore<_TestParams>(
          params: const _TestParams(offset: 2),
          load: loader.call,
        ),
        throwsA(same(failure)),
      );

      // Assert
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));
      expect(dispatcher.isLoading, isFalse);
    });
  });

  group('ACListLoadingDispatcher — notify semantics (US1 + T049)', () {
    late ACListLoadingDispatcher<int> dispatcher;
    late FakeLoader<ACListLoadingResult<int>> loader;
    late int notifyCount;
    late VoidCallback listener;

    setUp(() {
      dispatcher = _buildDispatcher();
      loader = FakeLoader<ACListLoadingResult<int>>();
      notifyCount = 0;
      listener = () => notifyCount++;
      dispatcher.addListener(listener);
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('successful reload triggers exactly one notifyListeners', () async {
      // Arrange
      loader.enqueueValue(_TestPage<int>(<int>[1, 2, 3], hasMore: true));

      // Act
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );

      // Assert — one notification after items actually change.
      expect(notifyCount, equals(1),
          reason: 'notifyListeners must fire exactly once after items change');
      expect(dispatcher.items, equals(<int>[1, 2, 3]));
    });

    test('successful loadMore triggers exactly one notifyListeners', () async {
      // Arrange — seed first with a reload.
      loader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      loader.enqueueValue(_TestPage<int>(<int>[3, 4], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      final countAfterReload = notifyCount;

      // Act
      await dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: loader.call,
      );

      // Assert
      expect(notifyCount - countAfterReload, equals(1),
          reason: 'loadMore must fire exactly one notification on success');
    });

    test('loader error does NOT trigger notifyListeners (items unchanged)',
        () async {
      // Arrange
      final failure = Exception('boom');
      loader.enqueueError(failure);

      // Act & Assert — the thrown error is expected.
      await expectLater(
        dispatcher.reload<_TestParams>(
          params: const _TestParams(),
          load: loader.call,
        ),
        throwsA(same(failure)),
      );

      // Assert — no notification because items never changed.
      expect(notifyCount, equals(0),
          reason: 'notifyListeners only fires when items actually change');
    });

    test('minLength rejection from NON-empty items triggers one '
        'notification (clearing is an items change)', () async {
      // Arrange — seed non-empty items so the subsequent clear is observable.
      loader.enqueueValue(_TestPage<int>(<int>[1, 2, 3], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: loader.call,
      );
      final countAfterReload = notifyCount;
      expect(dispatcher.items, isNotEmpty);

      // Act — short query triggers minLength-clear branch.
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(query: 'ab'),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.items, isEmpty,
          reason: 'short-query reload must clear items');
      expect(notifyCount - countAfterReload, equals(1),
          reason: 'clearing items from non-empty to empty is a change');
    });

    test('minLength rejection when items are already empty fires no '
        'notification', () async {
      // Arrange — items already empty right after construction.
      expect(dispatcher.items, isEmpty);
      final countBefore = notifyCount;

      // Act — short query, items stay empty (no change).
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(query: 'ab'),
        load: loader.call,
      );

      // Assert
      expect(dispatcher.items, isEmpty);
      expect(notifyCount, equals(countBefore),
          reason: 'no items change means no notification');
    });

    test('isLoading transition alone does not fire a notification (start '
        'phase of a pending load)', () async {
      // Arrange — a gated loader keeps isLoading=true for a while.
      final gate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> slow(_TestParams _) => gate.future;

      // Act — kick off the reload but DO NOT await.
      final future = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: slow,
      );
      // Let any synchronous/microtask work settle.
      await Future<void>.delayed(Duration.zero);

      // Assert — no notification yet, because items haven't changed.
      expect(dispatcher.isLoading, isTrue);
      expect(notifyCount, equals(0),
          reason: 'isLoading transition alone must not notify');

      // Cleanup — let the loader finish so tearDown can dispose cleanly.
      gate.complete(_TestPage<int>(<int>[1, 2], hasMore: true));
      await future;
      expect(notifyCount, equals(1),
          reason: 'the terminal items change fires exactly one notification');
    });
  });

  group('ACListLoadingDispatcher — dispose & cancel safety (US1)', () {
    test('dispose() while a reload is in flight: pending result discarded '
        'and no notifications fire after dispose', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      var notifyCount = 0;
      dispatcher.addListener(() => notifyCount++);
      final gate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> gatedLoad(_TestParams _) => gate.future;

      // Act
      final reloadFuture = dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: gatedLoad,
      );
      dispatcher.dispose();
      final countAfterDispose = notifyCount;
      gate.complete(_TestPage<int>(<int>[1, 2, 3], hasMore: true));
      // Let any residual microtasks drain. We deliberately swallow the future
      // because cancellation-after-dispose is silent (no throws expected).
      try {
        await reloadFuture;
      } on Object catch (_) {
        // Dispatcher may or may not propagate the late result as an error;
        // either way, items must stay empty.
      }

      // Assert
      expect(notifyCount, equals(countAfterDispose),
          reason: 'dispatcher must not notify after dispose');
      expect(dispatcher.items, isEmpty,
          reason: 'late loader result must not mutate items after dispose');
    });

    test('repeated dispose() is safe (does not throw)', () {
      // Arrange
      final dispatcher = _buildDispatcher();

      // Act & Assert
      dispatcher.dispose();
      expect(dispatcher.dispose, returnsNormally);
    });

    test('addListener after dispose throws FlutterError (ChangeNotifier '
        'contract)', () {
      // Arrange
      final dispatcher = _buildDispatcher();
      dispatcher.dispose();

      // Act & Assert
      expect(
        () => dispatcher.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });

    test('cancel() with no active load is a safe no-op', () async {
      // Arrange
      final dispatcher = _buildDispatcher();
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;

      // Act & Assert
      await expectLater(dispatcher.cancel(), completes);
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));

      dispatcher.dispose();
    });

    test('cancel() with an active load: isLoading reset, items and hasMore '
        'preserved, pending result ignored', () async {
      // Arrange — seed a known list first.
      final dispatcher = _buildDispatcher();
      final seedLoader = FakeLoader<ACListLoadingResult<int>>();
      seedLoader.enqueueValue(_TestPage<int>(<int>[1, 2], hasMore: true));
      await dispatcher.reload<_TestParams>(
        params: const _TestParams(),
        load: seedLoader.call,
      );
      final itemsBefore = List<int>.from(dispatcher.items);
      final hasMoreBefore = dispatcher.hasMore;
      // Start a loadMore that will be cancelled before completion.
      final gate = Completer<ACListLoadingResult<int>>();
      Future<ACListLoadingResult<int>> gatedLoad(_TestParams _) => gate.future;

      // Act
      final loadMoreFuture = dispatcher.loadMore<_TestParams>(
        params: const _TestParams(offset: 2),
        load: gatedLoad,
      );
      expect(dispatcher.isLoading, isTrue);
      await dispatcher.cancel();
      // Complete the loader after cancel — result must be ignored.
      gate.complete(_TestPage<int>(<int>[9, 9, 9], hasMore: true));
      try {
        await loadMoreFuture;
      } on Object catch (_) {
        // Completing after cancel may or may not propagate; either is fine.
      }

      // Assert
      expect(dispatcher.isLoading, isFalse);
      expect(dispatcher.items, equals(itemsBefore));
      expect(dispatcher.hasMore, equals(hasMoreBefore));

      dispatcher.dispose();
    });
  });
}
