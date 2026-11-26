import 'package:flutter/foundation.dart';

/// The state of a [GenericBloc].
///
/// * [T] is the type of the data you load (a model, a list, ...).
/// * [F] is the type of the failure your repository returns.
///
/// Every state can carry the last data that loaded successfully in [data].
/// This lets you keep showing the old list while a refresh is running, or
/// after a refresh fails.
@immutable
sealed class GenericState<T, F> {
  const GenericState({this.data});

  /// The last data that loaded successfully, if any.
  final T? data;

  /// Whether there is data to show.
  bool get hasData => data != null;

  /// Whether a request is running right now.
  bool get isLoading => this is GenericLoading<T, F>;
}

/// Nothing has been requested yet.
final class GenericInitial<T, F> extends GenericState<T, F> {
  const GenericInitial();

  @override
  String toString() => 'GenericInitial<$T, $F>()';
}

/// A request is running.
///
/// When [isRefresh] is true the request was started by
/// [GenericBloc.refresh], and [data] still holds what was shown before.
final class GenericLoading<T, F> extends GenericState<T, F> {
  const GenericLoading({super.data, this.isRefresh = false});

  /// True when this load is a refresh of data that is already on screen.
  final bool isRefresh;

  @override
  String toString() => 'GenericLoading<$T, $F>(isRefresh: $isRefresh, '
      'hasData: $hasData)';
}

/// The request finished and returned data.
final class GenericSuccess<T, F> extends GenericState<T, F> {
  const GenericSuccess(T data) : super(data: data);

  @override
  T get data => super.data as T;

  @override
  String toString() => 'GenericSuccess<$T, $F>($data)';
}

/// The request finished, but the data is empty.
///
/// Only emitted when you pass `isEmpty` to the bloc.
final class GenericEmpty<T, F> extends GenericState<T, F> {
  const GenericEmpty(T data) : super(data: data);

  @override
  T get data => super.data as T;

  @override
  String toString() => 'GenericEmpty<$T, $F>()';
}

/// The request failed.
///
/// [failure] is set when your repository returned a failure value.
/// [error] and [stackTrace] are set when the call threw an exception.
/// [data] still holds the last successful data, so you can keep it on screen.
final class GenericFailure<T, F> extends GenericState<T, F> {
  const GenericFailure({
    required this.message,
    this.failure,
    this.error,
    this.stackTrace,
    super.data,
  });

  /// A message you can show to the user.
  final String message;

  /// The failure value returned by the repository, if any.
  final F? failure;

  /// The exception thrown by the call, if any.
  final Object? error;

  /// The stack trace of [error], if any.
  final StackTrace? stackTrace;

  @override
  String toString() => 'GenericFailure<$T, $F>(message: $message, '
      'failure: $failure, error: $error)';
}
