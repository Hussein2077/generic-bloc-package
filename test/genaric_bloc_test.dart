import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_bloc/generic_bloc.dart';

void main() {
  test('GenericBloc initial state should be GenericInitial', () {
    final bloc = GenericBloc<int, String,String>(
      callFunction: (_) async => const Left(42), errorMessage: '',
    );
    expect(bloc.state, isA<GenericInitial<int>>());
  });
}
