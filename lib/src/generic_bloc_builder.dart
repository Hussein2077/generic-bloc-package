import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:generic_bloc/generic_bloc.dart';
class GenericBlocBuilder<T, P, F> extends StatelessWidget {
  final GenericBloc<T, P, F> bloc;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function(BuildContext context, String errorMessage) onError;
  final Widget Function(BuildContext context) onLoading;
  final Widget  ? noData;

  const GenericBlocBuilder({
    super.key,
    required this.bloc,
    required this.onSuccess,
    required this.onError,
    required this.onLoading,
      this.noData,

  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GenericBloc<T, P, F>, GenericState<T>>(
      bloc: bloc,
      builder: (context, state) {
        if (state is GenericLoading<T>) {
          return onLoading(context);
        } else if (state is GenericSuccess<T>) {
          return onSuccess(context, state.data);
        } else if (state is GenericError<T>) {
          return onError(context, state.errorMessage);
        }
          return noData ?? const Center(child: Text('No Data'));

      },
    );
  }
}
