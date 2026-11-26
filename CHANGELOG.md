## 1.0.0

A rewrite of the package. See "Upgrading from 0.0.x" in the README.

### Added
- `GenericEmpty` state, enabled with the `isEmpty` option.
- `refresh()` reloads with the last parameter and keeps the current data on screen.
- `reset()` goes back to the initial state.
- The newest request always wins: slow old responses are ignored.
- Exceptions thrown by `load` become a `GenericFailure` instead of crashing, and are reported to `BlocObserver`.
- `GenericFailure` now holds the failure value, the exception, the stack trace and the last successful data.
- `GenericBloc.fromFuture` for calls that return a plain `Future<T>`.
- `GenericBlocBuilder` with default loading, empty and error widgets, a retry callback, `listener`, `buildWhen`, `showDataWhileLoading` and `showDataOnFailure`.
- `BuildContext` helpers: `genericBloc`, `fetchGeneric`, `refreshGeneric`.
- Example app, bloc tests, widget tests and a CI workflow.

### Changed
- `load` returns `Either<F, T>` (failure on the left), following the usual convention. Before it was `Either<T, F>`.
- States and events are Dart 3 sealed classes, so `switch` checks every case.
- `GenericState<T>` is now `GenericState<T, F>`.
- `GenericError` is renamed to `GenericFailure`.
- Minimum SDK is Dart 3.0 and Flutter 3.10.

### Deprecated
- `FetchDataEvent`: use `bloc.fetch(parameter)`.
- `GenericBlocConsumer`: use `GenericBlocBuilder`.

### Removed
- `GenericBlocHelper`: use `bloc.fetch` or the `BuildContext` helpers.

## 0.0.3

- `GenericBlocConsumer` widget.

## 0.0.1

- First version.
