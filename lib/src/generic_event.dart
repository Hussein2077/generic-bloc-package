import 'package:flutter/foundation.dart';

/// Events understood by a [GenericBloc].
///
/// You rarely need to create these yourself: use `bloc.fetch(...)`,
/// `bloc.refresh()` and `bloc.reset()` instead.
@immutable
sealed class GenericEvent<P> {
  const GenericEvent();
}

/// Loads data for [parameter].
class GenericFetch<P> extends GenericEvent<P> {
  const GenericFetch(this.parameter);

  /// The value passed to your `load` function.
  final P parameter;

  @override
  String toString() => 'GenericFetch<$P>($parameter)';
}

/// Loads data again with the last parameter, keeping the current data on
/// screen while it runs.
final class GenericRefresh<P> extends GenericEvent<P> {
  const GenericRefresh();

  @override
  String toString() => 'GenericRefresh<$P>()';
}

/// Goes back to [GenericInitial] and ignores any request still running.
final class GenericReset<P> extends GenericEvent<P> {
  const GenericReset();

  @override
  String toString() => 'GenericReset<$P>()';
}

/// The event name used before version 1.0.0.
@Deprecated('Use GenericFetch(parameter) or bloc.fetch(parameter). '
    'FetchDataEvent will be removed in 2.0.0.')
final class FetchDataEvent<P> extends GenericFetch<P> {
  const FetchDataEvent({required P parameter}) : super(parameter);
}
