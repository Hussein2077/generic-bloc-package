import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'generic_bloc.dart';

class GenericBlocHelper {
  /// Creates a new instance of `GenericBloc` with the provided function.
  static GenericBloc<T, P, F> createBloc<T, P, F>(
      Future<Either<T, F>> Function(P parameter) callFunction) {
    return GenericBloc<T, P, F>(callFunction: callFunction, errorMessage: '');
  }

  /// Adds a `FetchDataEvent` to the given `GenericBloc`.
  static void fetchData<T, P, F>(
      {required BuildContext context, required P parameter}) {
    BlocProvider.of<GenericBloc<T, P, F>>(context)
        .add(FetchDataEvent<P>(parameter: parameter));
  }
}
