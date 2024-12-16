abstract class GenericEvent<P> {}

class FetchDataEvent<P> extends GenericEvent<P> {
  final P parameter;

  FetchDataEvent({  required this.parameter}) ;
}