
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../generic_bloc.dart';


class GenericBloc<T, P,F> extends Bloc<GenericEvent<P>, GenericState<T>> {
  final Future<Either<T, F>> Function(P) callFunction;
final String errorMessage;
  GenericBloc( {required this.callFunction, required this.errorMessage}) : super(GenericInitial<T>()) {
    on<FetchDataEvent<P>>((event, emit) async {
      emit(GenericLoading<T>());
      final result = await callFunction(event.parameter);
      result.fold(
            (response) {
          emit(GenericSuccess<T>(response));
        },
            (failure) =>
            emit(GenericError<T>( errorMessage)),
      );
    });
  }
}
