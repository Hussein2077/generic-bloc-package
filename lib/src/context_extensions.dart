import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'generic_bloc.dart';

/// Short helpers to reach a [GenericBloc] from the widget tree.
extension GenericBlocContext on BuildContext {
  /// Reads the [GenericBloc] above this context.
  GenericBloc<T, P, F> genericBloc<T, P, F>() =>
      read<GenericBloc<T, P, F>>();

  /// Calls [GenericBloc.fetch] on the bloc above this context.
  void fetchGeneric<T, P, F>(P parameter) =>
      read<GenericBloc<T, P, F>>().fetch(parameter);

  /// Calls [GenericBloc.refresh] on the bloc above this context.
  void refreshGeneric<T, P, F>() => read<GenericBloc<T, P, F>>().refresh();
}
