import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'generic_bloc.dart';
import 'generic_state.dart';

/// Builds the right widget for each [GenericState].
///
/// Only [onSuccess] is required. Every other state has a simple default,
/// so a full screen can be as short as:
///
/// ```dart
/// GenericBlocBuilder<List<Product>, int, Failure>(
///   onSuccess: (context, products) => ProductList(products),
/// )
/// ```
///
/// The bloc is read from the widget tree unless you pass [bloc].
class GenericBlocBuilder<T, P, F> extends StatelessWidget {
  const GenericBlocBuilder({
    super.key,
    required this.onSuccess,
    this.bloc,
    this.onLoading,
    this.onFailure,
    this.onEmpty,
    this.onInitial,
    this.listener,
    this.buildWhen,
    this.showDataWhileLoading = true,
    this.showDataOnFailure = false,
  });

  /// The bloc to listen to. When null, it is read from the context.
  final GenericBloc<T, P, F>? bloc;

  /// Builds the screen when data is ready.
  final Widget Function(BuildContext context, T data) onSuccess;

  /// Builds the loading screen. Defaults to a centered progress indicator.
  final Widget Function(BuildContext context)? onLoading;

  /// Builds the error screen. [retry] runs the last request again.
  /// Defaults to the error message and a "Try again" button.
  final Widget Function(
    BuildContext context,
    GenericFailure<T, F> failure,
    VoidCallback retry,
  )? onFailure;

  /// Builds the screen for empty data. Defaults to a short message.
  final Widget Function(BuildContext context)? onEmpty;

  /// Builds the screen before anything was requested. Defaults to nothing.
  final Widget Function(BuildContext context)? onInitial;

  /// Called once for every new state, for side effects such as snack bars
  /// or navigation.
  final void Function(BuildContext context, GenericState<T, F> state)?
      listener;

  /// Decides whether to rebuild for a new state. Rebuilds every time by
  /// default.
  final bool Function(GenericState<T, F> previous, GenericState<T, F> current)?
      buildWhen;

  /// When true, [GenericBloc.refresh] keeps showing the old data instead of
  /// the loading screen. A new [GenericBloc.fetch] always shows the loading
  /// screen.
  final bool showDataWhileLoading;

  /// When true, a failed refresh keeps showing the old data instead of
  /// the error screen. Use [listener] to tell the user, for example with
  /// a snack bar.
  final bool showDataOnFailure;

  @override
  Widget build(BuildContext context) {
    final resolvedBloc = bloc ?? context.read<GenericBloc<T, P, F>>();

    return BlocConsumer<GenericBloc<T, P, F>, GenericState<T, F>>(
      bloc: resolvedBloc,
      listener: listener ?? (_, __) {},
      buildWhen: buildWhen,
      builder: (context, state) => switch (state) {
        GenericInitial<T, F>() =>
          onInitial?.call(context) ?? const SizedBox.shrink(),
        GenericLoading<T, F>(data: final data?, isRefresh: true)
            when showDataWhileLoading =>
          onSuccess(context, data),
        GenericLoading<T, F>() =>
          onLoading?.call(context) ?? const _DefaultLoading(),
        GenericSuccess<T, F>(:final data) => onSuccess(context, data),
        GenericEmpty<T, F>() =>
          onEmpty?.call(context) ?? const _DefaultMessage('Nothing here yet.'),
        GenericFailure<T, F>(data: final data?) when showDataOnFailure =>
          onSuccess(context, data),
        final GenericFailure<T, F> failure => onFailure?.call(
              context,
              failure,
              resolvedBloc.refresh,
            ) ??
            _DefaultFailure(
              message: failure.message,
              onRetry: resolvedBloc.refresh,
            ),
      },
    );
  }
}

/// The widget name used before version 1.0.0.
@Deprecated('Use GenericBlocBuilder. GenericBlocConsumer will be removed in '
    '2.0.0.')
class GenericBlocConsumer<T, P, F> extends StatelessWidget {
  const GenericBlocConsumer({
    super.key,
    required this.bloc,
    required this.onSuccess,
    required this.onError,
    required this.onLoading,
    this.listener,
    this.noData,
  });

  final GenericBloc<T, P, F> bloc;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function(BuildContext context, String errorMessage) onError;
  final Widget Function(BuildContext context) onLoading;
  final void Function(BuildContext context, GenericState<T, F> state)?
      listener;
  final Widget? noData;

  @override
  Widget build(BuildContext context) {
    return GenericBlocBuilder<T, P, F>(
      bloc: bloc,
      onSuccess: onSuccess,
      onLoading: onLoading,
      onFailure: (context, failure, _) => onError(context, failure.message),
      onEmpty: noData == null ? null : (_) => noData!,
      onInitial: (_) => noData ?? const _DefaultMessage('No data'),
      listener: listener,
      showDataWhileLoading: false,
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

class _DefaultMessage extends StatelessWidget {
  const _DefaultMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _DefaultFailure extends StatelessWidget {
  const _DefaultFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
