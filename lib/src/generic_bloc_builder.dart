import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:generic_bloc/generic_bloc.dart';

class GenericBlocConsumer<T, P, F> extends StatelessWidget {
  final GenericBloc<T, P, F> bloc;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function(BuildContext context, String errorMessage) onError;
  final Widget Function(BuildContext context) onLoading;
  final void Function(BuildContext context, GenericState<T> state)? listener;
  final Widget  ? noData;

  const GenericBlocConsumer({
    super.key,
    required this.bloc,
    required this.onSuccess,
    required this.onError,
    required this.onLoading,
    this.listener,
    this.noData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenericBloc<T, P, F>, GenericState<T>>(
      bloc: bloc,
      listener: listener ?? (context, state) {},
      builder: (context, state) {
        if (state is GenericLoading<T>) {
          return onLoading(context);
        } else if (state is GenericSuccess<T>) {
          return onSuccess(context, state.data);
        } else if (state is GenericError<T>) {
          return onError(context, state.errorMessage);
        } else {
          return noData ?? const Center(child: Text('No Data'));
        }
      },
    );
  }
}
