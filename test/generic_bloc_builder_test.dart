import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_bloc/generic_bloc.dart';

typedef NameBloc = GenericBloc<String, int, String>;

Widget wrap(NameBloc bloc, Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<NameBloc>.value(value: bloc, child: child),
    ),
  );
}

void main() {
  testWidgets('shows loading, then the data', (tester) async {
    final response = Completer<Either<String, String>>();
    final bloc = NameBloc(load: (_) => response.future)..fetch(1);

    await tester.pumpWidget(wrap(
      bloc,
      GenericBlocBuilder<String, int, String>(
        onSuccess: (context, name) => Text('Hello $name'),
      ),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(const Right('Hussein'));
    await tester.pumpAndSettle();
    expect(find.text('Hello Hussein'), findsOneWidget);

    await bloc.close();
  });

  testWidgets('shows the failure message and retries', (tester) async {
    var calls = 0;
    final bloc = NameBloc(
      load: (_) async => ++calls == 1 ? const Left('Offline') : const Right('Ok'),
      failureMessage: (failure) => failure,
    )..fetch(1);

    await tester.pumpWidget(wrap(
      bloc,
      GenericBlocBuilder<String, int, String>(
        onSuccess: (context, value) => Text(value),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Ok'), findsOneWidget);
    expect(calls, 2);

    await bloc.close();
  });

  testWidgets('shows the empty widget', (tester) async {
    final bloc = NameBloc(
      load: (_) async => const Right(''),
      isEmpty: (value) => value.isEmpty,
    )..fetch(1);

    await tester.pumpWidget(wrap(
      bloc,
      GenericBlocBuilder<String, int, String>(
        onSuccess: (context, value) => Text(value),
        onEmpty: (context) => const Text('No names'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No names'), findsOneWidget);

    await bloc.close();
  });

  testWidgets('keeps the old data on screen during a refresh', (tester) async {
    var calls = 0;
    final second = Completer<Either<String, String>>();
    final bloc = NameBloc(
      load: (_) => ++calls == 1 ? Future.value(const Right('first')) : second.future,
    )..fetch(1);

    await tester.pumpWidget(wrap(
      bloc,
      GenericBlocBuilder<String, int, String>(
        onSuccess: (context, value) => Text(value),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);

    bloc.refresh();
    await tester.pump();
    expect(find.text('first'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    second.complete(const Right('second'));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);

    await bloc.close();
  });
}
