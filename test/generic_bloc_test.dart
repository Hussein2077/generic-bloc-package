import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_bloc/generic_bloc.dart';

class Failure {
  const Failure(this.message);
  final String message;
}

typedef ItemsBloc = GenericBloc<List<String>, int, Failure>;
typedef ItemsState = GenericState<List<String>, Failure>;

ItemsBloc buildBloc(
  Future<Either<Failure, List<String>>> Function(int page) load, {
  bool keepDataOnFailure = true,
}) {
  return ItemsBloc(
    load: load,
    failureMessage: (failure) => failure.message,
    exceptionMessage: (error) => 'Unexpected: $error',
    isEmpty: (items) => items.isEmpty,
    keepDataOnFailure: keepDataOnFailure,
  );
}

void main() {
  group('GenericBloc', () {
    test('starts in GenericInitial', () {
      final bloc = buildBloc((_) async => const Right(['a']));
      expect(bloc.state, isA<GenericInitial<List<String>, Failure>>());
      expect(bloc.lastParameter, isNull);
      bloc.close();
    });

    blocTest<ItemsBloc, ItemsState>(
      'emits loading then success',
      build: () => buildBloc((page) async => Right(['item $page'])),
      act: (bloc) => bloc.fetch(1),
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>()
            .having((s) => s.isRefresh, 'isRefresh', false),
        isA<GenericSuccess<List<String>, Failure>>()
            .having((s) => s.data, 'data', ['item 1']),
      ],
      verify: (bloc) => expect(bloc.lastParameter, 1),
    );

    blocTest<ItemsBloc, ItemsState>(
      'emits empty when isEmpty returns true',
      build: () => buildBloc((_) async => const Right(<String>[])),
      act: (bloc) => bloc.fetch(1),
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericEmpty<List<String>, Failure>>(),
      ],
    );

    blocTest<ItemsBloc, ItemsState>(
      'emits failure with the repository failure and its message',
      build: () => buildBloc((_) async => const Left(Failure('No network'))),
      act: (bloc) => bloc.fetch(1),
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericFailure<List<String>, Failure>>()
            .having((s) => s.message, 'message', 'No network')
            .having((s) => s.failure?.message, 'failure', 'No network')
            .having((s) => s.error, 'error', isNull),
      ],
    );

    blocTest<ItemsBloc, ItemsState>(
      'turns a thrown exception into a failure instead of crashing',
      build: () => buildBloc((_) async => throw StateError('boom')),
      act: (bloc) => bloc.fetch(1),
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericFailure<List<String>, Failure>>()
            .having((s) => s.message, 'message', contains('boom'))
            .having((s) => s.error, 'error', isA<StateError>())
            .having((s) => s.stackTrace, 'stackTrace', isNotNull),
      ],
      errors: () => [isA<StateError>()],
    );

    blocTest<ItemsBloc, ItemsState>(
      'refresh keeps the old data while loading',
      build: () {
        var call = 0;
        return buildBloc((_) async => Right(['version ${++call}']));
      },
      act: (bloc) async {
        bloc.fetch(1);
        await Future<void>.delayed(Duration.zero);
        bloc.refresh();
      },
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericSuccess<List<String>, Failure>>()
            .having((s) => s.data, 'data', ['version 1']),
        isA<GenericLoading<List<String>, Failure>>()
            .having((s) => s.isRefresh, 'isRefresh', true)
            .having((s) => s.data, 'data', ['version 1']),
        isA<GenericSuccess<List<String>, Failure>>()
            .having((s) => s.data, 'data', ['version 2']),
      ],
    );

    blocTest<ItemsBloc, ItemsState>(
      'refresh does nothing before the first fetch',
      build: () => buildBloc((_) async => const Right(['a'])),
      act: (bloc) => bloc.refresh(),
      expect: () => <ItemsState>[],
    );

    blocTest<ItemsBloc, ItemsState>(
      'a failed refresh keeps the last data',
      build: () {
        var call = 0;
        return buildBloc((_) async => ++call == 1
            ? const Right(['saved'])
            : const Left(Failure('Offline')));
      },
      act: (bloc) async {
        bloc.fetch(1);
        await Future<void>.delayed(Duration.zero);
        bloc.refresh();
      },
      skip: 3,
      expect: () => [
        isA<GenericFailure<List<String>, Failure>>()
            .having((s) => s.data, 'data', ['saved']),
      ],
    );

    blocTest<ItemsBloc, ItemsState>(
      'keepDataOnFailure: false drops the old data',
      build: () {
        var call = 0;
        return buildBloc(
          (_) async => ++call == 1
              ? const Right(['saved'])
              : const Left(Failure('Offline')),
          keepDataOnFailure: false,
        );
      },
      act: (bloc) async {
        bloc.fetch(1);
        await Future<void>.delayed(Duration.zero);
        bloc.refresh();
      },
      skip: 3,
      expect: () => [
        isA<GenericFailure<List<String>, Failure>>()
            .having((s) => s.data, 'data', isNull),
      ],
    );

    blocTest<ItemsBloc, ItemsState>(
      'only the newest request is shown when an older one finishes later',
      build: () {
        final slowFirstPage = Completer<Either<Failure, List<String>>>();
        return buildBloc((page) {
          if (page == 1) return slowFirstPage.future;
          // Finish page 1 after page 2 has already returned.
          Future<void>.delayed(const Duration(milliseconds: 10), () {
            slowFirstPage.complete(const Right(['page 1']));
          });
          return Future.value(const Right(['page 2']));
        });
      },
      act: (bloc) async {
        bloc
          ..fetch(1)
          ..fetch(2);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericSuccess<List<String>, Failure>>()
            .having((s) => s.data, 'data', ['page 2']),
      ],
      verify: (bloc) => expect(bloc.lastParameter, 2),
    );

    blocTest<ItemsBloc, ItemsState>(
      'reset goes back to initial and ignores the running request',
      build: () {
        final pending = Completer<Either<Failure, List<String>>>();
        Future<void>.delayed(const Duration(milliseconds: 10), () {
          pending.complete(const Right(['late']));
        });
        return buildBloc((_) => pending.future);
      },
      act: (bloc) async {
        bloc.fetch(1);
        await Future<void>.delayed(Duration.zero);
        bloc.reset();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericInitial<List<String>, Failure>>(),
      ],
      verify: (bloc) => expect(bloc.lastParameter, isNull),
    );

    blocTest<GenericBloc<String, String, Object>,
        GenericState<String, Object>>(
      'fromFuture wraps a plain Future',
      build: () => GenericBloc.fromFuture<String, String>(
        load: (name) async => 'Hello $name',
      ),
      act: (bloc) => bloc.fetch('Hussein'),
      expect: () => [
        isA<GenericLoading<String, Object>>(),
        isA<GenericSuccess<String, Object>>()
            .having((s) => s.data, 'data', 'Hello Hussein'),
      ],
    );

    blocTest<ItemsBloc, ItemsState>(
      'the old FetchDataEvent still works',
      build: () => buildBloc((_) async => const Right(['a'])),
      // ignore: deprecated_member_use_from_same_package
      act: (bloc) => bloc.add(const FetchDataEvent<int>(parameter: 1)),
      expect: () => [
        isA<GenericLoading<List<String>, Failure>>(),
        isA<GenericSuccess<List<String>, Failure>>(),
      ],
    );
  });
}
