import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_dispatcher.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_params.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_list_loading_parser.dart';
import 'package:appcraft_utils_flutter/src/list_loading_dispatcher/src/ac_search_strategy.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'helpers/fake_loader.dart';

/// Minimal implementation of [ACListLoadingParamsMixin] used only in search
/// tests. The dispatcher reads only [query]; [limit] and [offset] are
/// carried along for compatibility with the public contract.
final class _TestParams with ACListLoadingParamsMixin {
  // `limit` is accepted for API symmetry with the public contract even
  // though none of the search tests currently pass it.
  // ignore: unused_element_parameter
  const _TestParams({this.limit, this.offset, this.query});

  @override
  final int? limit;
  @override
  final int? offset;
  @override
  final String? query;
}

/// Default parser: items are passed through verbatim and `hasMore` is
/// derived from list length (>= 2 means "more likely").
ACParseResult<int> _listParser(List<int> response) => ACParseResult<int>(
      items: response,
      hasMore: response.length >= 2,
    );

/// Builds a dispatcher with the given [searchStrategy]; default parser
/// returns items as-is with length-based hasMore.
ACListLoadingDispatcher<int, List<int>> _buildDispatcher({
  ACSearchStrategy? searchStrategy,
  ACListLoadingParser<int, List<int>>? parser,
}) =>
    ACListLoadingDispatcher<int, List<int>>(
      parser: parser ?? _listParser,
      searchStrategy: searchStrategy,
    );

void main() {
  group('ACListLoadingDispatcher — search in reload (US2)', () {
    test('query == null: load starts immediately, no debounce delay', () {
      FakeAsync().run((async) {
        // Arrange
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[1, 2, 3]);

        // Act — fire-and-forget; FakeAsync runs the future synchronously.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert — loader was invoked without any fake-time elapsing.
        expect(loader.callCount, 1,
            reason: 'null query must trigger an immediate load');
        expect(dispatcher.items, equals(<int>[1, 2, 3]));
        expect(dispatcher.isLoading, isFalse);

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('query == "" (empty string) behaves like null: immediate load', () {
      FakeAsync().run((async) {
        // Arrange
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[10, 20]);

        // Act
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: ''),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert
        expect(loader.callCount, 1);
        expect(dispatcher.items, equals(<int>[10, 20]));

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('query.length < minLength: items cleared, hasMore=false, '
        'loader NOT called, error not set', () {
      FakeAsync().run((async) {
        // Arrange — seed items first so we can observe the clearing effect.
        final dispatcher = _buildDispatcher();
        final seedLoader = FakeLoader<List<int>>();
        seedLoader.enqueueValue(<int>[1, 2, 3]);
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(),
              load: seedLoader.call,
            )
            .ignore();
        async.flushMicrotasks();
        expect(dispatcher.items, equals(<int>[1, 2, 3]));

        // Act — reload with a too-short query.
        final searchLoader = FakeLoader<List<int>>();
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'ab'),
              load: searchLoader.call,
            )
            .ignore();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        // Assert
        expect(searchLoader.callCount, 0,
            reason: 'loader must not run when query is shorter than minLength');
        expect(dispatcher.items, isEmpty,
            reason: 'short-query reload must clear accumulated items');
        expect(dispatcher.hasMore, isFalse);
        expect(dispatcher.error, isNull);
        expect(dispatcher.isLoading, isFalse);

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('changed query with length >= minLength: debounce delays the load', () {
      FakeAsync().run((async) {
        // Arrange
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[100, 200, 300]);

        // Act — first search: starts debounce timer, nothing happens yet.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();

        // Assert — debounce has not expired yet; loader must not have run.
        expect(loader.callCount, 0,
            reason: 'loader must not fire before debounce elapses');
        expect(dispatcher.items, isEmpty);

        // Act — advance time past the debounce (300ms total).
        async.elapse(const Duration(milliseconds: 200));
        async.flushMicrotasks();

        // Assert — loader fired once, items updated.
        expect(loader.callCount, 1);
        expect(dispatcher.items, equals(<int>[100, 200, 300]));
        expect(dispatcher.isLoading, isFalse);

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('two successive reloads within debounce window: first timer is '
        'cancelled, second query wins', () {
      FakeAsync().run((async) {
        // Arrange
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[7, 8]);

        // Act — first reload starts the debounce timer.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'joh'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 100));

        // Second reload with a different query, still within debounce window.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();

        // Assert — neither query has fired yet (second timer still pending).
        expect(loader.callCount, 0);

        // Act — now elapse the full debounce from the second reload.
        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();

        // Assert — only the second query triggered the loader; loader was
        // called exactly once.
        expect(loader.callCount, 1);
        expect(loader.calls.length, 1);
        final lastParams = loader.calls.single as _TestParams;
        expect(lastParams.query, equals('john'),
            reason: 'loader must receive the last-requested query');
        expect(dispatcher.items, equals(<int>[7, 8]));

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('repeated reload(query: "john") after it was applied: load starts '
        'immediately (no debounce) because query matches _lastAppliedQuery',
        () {
      FakeAsync().run((async) {
        // Arrange — first, apply the query normally through debounce.
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[1, 2]);
        loader.enqueueValue(<int>[3, 4]);
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
        expect(loader.callCount, 1, reason: 'first search debounced then ran');

        // Act — repeat the same query. It must NOT wait for debounce.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert — loader has already been called a second time synchronously
        // (no elapse needed).
        expect(loader.callCount, 2,
            reason: 'repeated query must bypass debounce');
        expect(dispatcher.items, equals(<int>[3, 4]));

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('reload(query: null) after a search resets _lastAppliedQuery; the '
        'next search of the previous query is debounced again', () {
      FakeAsync().run((async) {
        // Arrange — apply 'john' first.
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[1, 2]); // first 'john' load
        loader.enqueueValue(<int>[5, 6]); // null-query reset load
        loader.enqueueValue(<int>[7, 8]); // second 'john' load
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
        expect(loader.callCount, 1);

        // Act 1 — reload with null query resets immediately, no debounce.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert — loader ran without any elapse (null-query = immediate).
        expect(loader.callCount, 2);
        expect(dispatcher.items, equals(<int>[5, 6]));

        // Act 2 — searching for 'john' again must be debounced (lastApplied
        // was reset by the null-query reload).
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        // Before debounce — loader must NOT fire immediately.
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();
        expect(loader.callCount, 2,
            reason: 'null reset must have cleared _lastAppliedQuery; '
                'search must re-debounce');

        // Advance past the debounce — loader fires now.
        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
        expect(loader.callCount, 3);
        expect(dispatcher.items, equals(<int>[7, 8]));

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('dispose during a pending debounce timer cancels the timer; loader '
        'does not fire after elapse', () {
      FakeAsync().run((async) {
        // Arrange
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>();
        loader.enqueueValue(<int>[1, 2]);

        // Act — start a search; before debounce fires, dispose.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'alex'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 100));
        dispatcher.dispose().ignore();
        async.flushMicrotasks();

        // Elapse past the debounce boundary — the timer must be cancelled.
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        // Assert — loader never fired because dispose killed the timer.
        expect(loader.callCount, 0,
            reason: 'dispose must cancel pending debounce timer');
      });
    });
  });

  group('ACListLoadingDispatcher — loadMore search semantics (US2)', () {
    test('loadMore with any query does NOT apply debounce: loader runs '
        'immediately (no fake time elapsed)', () {
      FakeAsync().run((async) {
        // Arrange — seed items with a normal reload first (hasMore=true).
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>()
          ..enqueueValue(<int>[1, 2])
          ..enqueueValue(<int>[3, 4]);
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();
        expect(loader.callCount, 1);
        expect(dispatcher.hasMore, isTrue);

        // Act — loadMore with a query, without advancing fake time.
        dispatcher
            .loadMore<_TestParams>(
              params: const _TestParams(offset: 2, query: 'abc'),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert — loader was called a second time immediately, no debounce.
        expect(loader.callCount, 2,
            reason: 'loadMore must not apply debounce');
        expect(dispatcher.items, equals(<int>[1, 2, 3, 4]));

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('loadMore with query shorter than minLength: minLength check does '
        'NOT apply; loader fires normally', () {
      FakeAsync().run((async) {
        // Arrange — seed items so loadMore is actually eligible.
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>()
          ..enqueueValue(<int>[1, 2])
          ..enqueueValue(<int>[3, 4]);
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();
        expect(dispatcher.hasMore, isTrue);

        // Act — loadMore with a 2-char query (minLength default = 3).
        dispatcher
            .loadMore<_TestParams>(
              params: const _TestParams(offset: 2, query: 'ab'),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert — loadMore ignores minLength entirely.
        expect(loader.callCount, 2);
        expect(dispatcher.items, equals(<int>[1, 2, 3, 4]));
        expect(dispatcher.hasMore, isTrue);

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });

    test('loadMore does NOT mutate _lastAppliedQuery: subsequent reload with '
        'the original query still skips debounce', () {
      FakeAsync().run((async) {
        // Arrange — apply 'john' through debounce.
        final dispatcher = _buildDispatcher();
        final loader = FakeLoader<List<int>>()
          ..enqueueValue(<int>[1, 2]) // first 'john' reload
          ..enqueueValue(<int>[3, 4]) // loadMore with 'different'
          ..enqueueValue(<int>[5, 6]); // second 'john' reload — MUST be instant
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
        expect(loader.callCount, 1);

        // Act 1 — loadMore with a DIFFERENT query; it must not change
        // _lastAppliedQuery (the dispatcher's search memory).
        dispatcher
            .loadMore<_TestParams>(
              params: const _TestParams(offset: 2, query: 'different'),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();
        expect(loader.callCount, 2);

        // Act 2 — reload with original 'john'. If loadMore had overwritten
        // _lastAppliedQuery to 'different', this reload would be debounced.
        // It must NOT be.
        dispatcher
            .reload<_TestParams>(
              params: const _TestParams(query: 'john'),
              load: loader.call,
            )
            .ignore();
        async.flushMicrotasks();

        // Assert — loader fired immediately, no debounce. That proves
        // _lastAppliedQuery is still 'john'.
        expect(loader.callCount, 3,
            reason: 'loadMore must not mutate _lastAppliedQuery');
        expect(dispatcher.items, equals(<int>[5, 6]));

        dispatcher.dispose().ignore();
        async.flushMicrotasks();
      });
    });
  });
}
