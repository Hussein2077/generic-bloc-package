import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'generic_event.dart';
import 'generic_state.dart';

/// A function that loads data for a parameter.
///
/// It follows the usual Clean Architecture convention:
/// `Left` is a failure and `Right` is the data.
typedef GenericLoader<T, P, F> = Future<Either<F, T>> Function(P parameter);

/// The message shown when no message builder is given.
const String kGenericDefaultErrorMessage =
    'Something went wrong. Please try again.';

/// A ready-made BLoC for the most common screen in an app:
/// load something, show a spinner, then show the data or an error.
///
/// * [T] is the data type, for example `List<Product>`.
/// * [P] is the parameter type passed to [load], for example a category id.
///   Use `void` or `Null` if your call takes no parameter.
/// * [F] is the failure type your repository returns.
///
/// ```dart
/// final bloc = GenericBloc<List<Product>, int, Failure>(
///   load: repository.getProducts,
///   failureMessage: (failure) => failure.message,
///   isEmpty: (products) => products.isEmpty,
/// )..fetch(categoryId);
/// ```
class GenericBloc<T, P, F> extends Bloc<GenericEvent<P>, GenericState<T, F>> {
  GenericBloc({
    required this.load,
    this.failureMessage,
    this.exceptionMessage,
    this.isEmpty,
    this.keepDataOnFailure = true,
  }) : super(GenericInitial<T, F>()) {
    on<GenericFetch<P>>(_onFetch);
    on<GenericRefresh<P>>(_onRefresh);
    on<GenericReset<P>>(_onReset);
  }

  /// Creates a bloc from a function that returns the data directly and throws
  /// when something goes wrong.
  ///
  /// The failure type is [Object]: any exception becomes a [GenericFailure].
  static GenericBloc<T, P, Object> fromFuture<T, P>({
    required Future<T> Function(P parameter) load,
    String Function(Object error)? errorMessage,
    bool Function(T data)? isEmpty,
    bool keepDataOnFailure = true,
  }) {
    return GenericBloc<T, P, Object>(
      load: (parameter) async => Right<Object, T>(await load(parameter)),
      exceptionMessage: errorMessage,
      isEmpty: isEmpty,
      keepDataOnFailure: keepDataOnFailure,
    );
  }

  /// Loads the data. `Left` is a failure, `Right` is the data.
  final GenericLoader<T, P, F> load;

  /// Turns a failure from [load] into a message for the user.
  /// Defaults to [kGenericDefaultErrorMessage].
  final String Function(F failure)? failureMessage;

  /// Turns an exception thrown by [load] into a message for the user.
  /// Defaults to [kGenericDefaultErrorMessage].
  final String Function(Object error)? exceptionMessage;

  /// When given and it returns true, the bloc emits [GenericEmpty]
  /// instead of [GenericSuccess].
  final bool Function(T data)? isEmpty;

  /// Whether [GenericFailure.data] keeps the last successful data.
  final bool keepDataOnFailure;

  P? _lastParameter;
  bool _hasParameter = false;
  int _requestId = 0;

  /// The parameter of the last [fetch], or null if nothing was fetched yet.
  P? get lastParameter => _lastParameter;

  /// Loads data for [parameter].
  ///
  /// If an older request is still running, its result is ignored:
  /// the newest request always wins.
  void fetch(P parameter) => add(GenericFetch<P>(parameter));

  /// Loads again with the last parameter. Does nothing before the first
  /// [fetch].
  void refresh() => add(GenericRefresh<P>());

  /// Goes back to [GenericInitial] and ignores any request still running.
  void reset() => add(GenericReset<P>());

  Future<void> _onFetch(
    GenericFetch<P> event,
    Emitter<GenericState<T, F>> emit,
  ) {
    _lastParameter = event.parameter;
    _hasParameter = true;
    return _run(event.parameter, emit, isRefresh: false);
  }

  Future<void> _onRefresh(
    GenericRefresh<P> event,
    Emitter<GenericState<T, F>> emit,
  ) async {
    if (!_hasParameter) return;
    await _run(_lastParameter as P, emit, isRefresh: true);
  }

  void _onReset(GenericReset<P> event, Emitter<GenericState<T, F>> emit) {
    _requestId++;
    _lastParameter = null;
    _hasParameter = false;
    emit(GenericInitial<T, F>());
  }

  Future<void> _run(
    P parameter,
    Emitter<GenericState<T, F>> emit, {
    required bool isRefresh,
  }) async {
    final requestId = ++_requestId;
    final previousData = state.data;

    emit(GenericLoading<T, F>(data: previousData, isRefresh: isRefresh));

    final Either<F, T> result;
    try {
      result = await load(parameter);
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      addError(error, stackTrace);
      emit(GenericFailure<T, F>(
        message: exceptionMessage?.call(error) ?? kGenericDefaultErrorMessage,
        error: error,
        stackTrace: stackTrace,
        data: keepDataOnFailure ? previousData : null,
      ));
      return;
    }

    // A newer fetch, refresh or reset happened while we were waiting.
    if (requestId != _requestId) return;

    result.fold(
      (failure) => emit(GenericFailure<T, F>(
        message: failureMessage?.call(failure) ?? kGenericDefaultErrorMessage,
        failure: failure,
        data: keepDataOnFailure ? previousData : null,
      )),
      (data) => emit(
        (isEmpty?.call(data) ?? false)
            ? GenericEmpty<T, F>(data)
            : GenericSuccess<T, F>(data),
      ),
    );
  }
}
