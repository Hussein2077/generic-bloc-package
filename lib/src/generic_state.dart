abstract class GenericState<T> {}

class GenericInitial<T> extends GenericState<T> {}

class GenericLoading<T> extends GenericState<T> {}

class GenericSuccess<T> extends GenericState<T> {
  final   T data;

  GenericSuccess(this.data);
}

class GenericError<T> extends GenericState<T> {
  final String errorMessage;

  GenericError(this.errorMessage);
}