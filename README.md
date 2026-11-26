# generic_bloc

Most screens in an app do the same thing: load something, show a spinner, then show the data or an error. With plain BLoC you write the same events, states and `if (state is ...)` checks again for every screen.

`generic_bloc` gives you one BLoC and one widget for that job, so a screen needs a single line of BLoC code.

```dart
final bloc = GenericBloc<List<Product>, String, Failure>(
  load: repository.getProducts,
)..fetch('Books');
```

```dart
GenericBlocBuilder<List<Product>, String, Failure>(
  onSuccess: (context, products) => ProductList(products),
)
```

You get loading, success, empty and error states, pull to refresh, a retry button, and protection against old responses overwriting new ones.

## Features

- **Four states plus initial**: `GenericLoading`, `GenericSuccess`, `GenericEmpty` and `GenericFailure`, as Dart 3 sealed classes, so `switch` checks you covered every case.
- **Refresh without a blank screen**: `refresh()` keeps the current data on screen while it reloads.
- **Retry**: the default error widget has a "Try again" button, and your own `onFailure` gets a `retry` callback.
- **Newest request wins**: if the user switches tabs quickly, a slow old response is ignored instead of replacing the new one.
- **No crashes from exceptions**: an exception thrown by your call becomes a `GenericFailure` with the error and stack trace, and is reported to your `BlocObserver`.
- **Your own failure type**: works with `Either<Failure, T>` from `dartz`, the usual Clean Architecture setup. There is also `GenericBloc.fromFuture` for a plain `Future<T>`.
- **Empty state**: pass `isEmpty` and empty lists get their own state and widget.
- **Sensible defaults**: only `onSuccess` is required in the builder.

## Install

```yaml
dependencies:
  generic_bloc:
    git:
      url: https://github.com/Hussein2077/generic-bloc-package.git
      ref: v1.0.0
```

Then run `flutter pub get`.

## The three type parameters

`GenericBloc<T, P, F>`

| Type | Meaning | Example |
|------|---------|---------|
| `T` | The data you load | `List<Product>` |
| `P` | The parameter you pass to `load` | `String` (a category), `int` (a page), or `void` |
| `F` | The failure type your repository returns | `Failure` |

## Usage

### 1. Write the repository call

Return `Left` for a failure and `Right` for the data.

```dart
class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts(String category) async {
    try {
      final response = await api.get('/products', query: {'category': category});
      return Right(response.map(Product.fromJson).toList());
    } on DioException catch (e) {
      return Left(Failure(e.message ?? 'Network error'));
    }
  }
}
```

### 2. Create the bloc

```dart
typedef ProductsBloc = GenericBloc<List<Product>, String, Failure>;

BlocProvider(
  create: (_) => ProductsBloc(
    load: repository.getProducts,
    failureMessage: (failure) => failure.message,
    isEmpty: (products) => products.isEmpty,
  )..fetch('Books'),
  child: const ProductsPage(),
);
```

A `typedef` keeps the long generic name short everywhere else.

### 3. Build the screen

```dart
GenericBlocBuilder<List<Product>, String, Failure>(
  onSuccess: (context, products) => ListView(
    children: [for (final p in products) ListTile(title: Text(p.name))],
  ),
  onEmpty: (context) => const Text('No products yet'),
  onFailure: (context, failure, retry) => ErrorView(
    message: failure.message,
    onRetry: retry,
  ),
)
```

Leave out `onLoading`, `onEmpty` or `onFailure` and you get a simple default for each.

### 4. Load, refresh, reset

```dart
final bloc = context.read<ProductsBloc>();

bloc.fetch('Phones'); // load with a new parameter
bloc.refresh();       // load again with the last parameter
bloc.reset();         // back to the initial state
```

### Pull to refresh

`refresh()` keeps the old data on screen while it loads, so it works well with `RefreshIndicator`:

```dart
RefreshIndicator(
  onRefresh: () async {
    bloc.refresh();
    await bloc.stream.firstWhere((state) => !state.isLoading);
  },
  child: productList,
)
```

If a refresh fails, the failure still holds the old data in `state.data`. Set `showDataOnFailure: true` on the builder to keep the list on screen, and show the message in a snack bar from `listener`.

### No Either? Use a plain Future

```dart
final bloc = GenericBloc.fromFuture<User, int>(
  load: (id) => api.getUser(id), // throws on error
  errorMessage: (error) => 'Could not load the user',
);
```

### Using the states directly

The states are sealed, so a `switch` must handle every case:

```dart
BlocBuilder<ProductsBloc, GenericState<List<Product>, Failure>>(
  builder: (context, state) => switch (state) {
    GenericInitial() => const SizedBox.shrink(),
    GenericLoading() => const CircularProgressIndicator(),
    GenericSuccess(:final data) => ProductList(data),
    GenericEmpty() => const Text('Nothing here'),
    GenericFailure(:final message) => Text(message),
  },
);
```

## Options

| Option | Where | Default | What it does |
|--------|-------|---------|--------------|
| `failureMessage` | bloc | generic text | Turns your failure into a message for the user |
| `exceptionMessage` | bloc | generic text | Turns a thrown exception into a message |
| `isEmpty` | bloc | none | Emits `GenericEmpty` when it returns true |
| `keepDataOnFailure` | bloc | `true` | Keeps the last data inside `GenericFailure` |
| `showDataWhileLoading` | builder | `true` | Keeps the old data on screen during `refresh()` |
| `showDataOnFailure` | builder | `false` | Keeps the old data on screen when a refresh fails |
| `listener` | builder | none | Runs once per state, for snack bars or navigation |
| `buildWhen` | builder | always | Controls when the widget rebuilds |

## Testing

The package is tested with `bloc_test`. Testing your own bloc looks like this:

```dart
blocTest<ProductsBloc, GenericState<List<Product>, Failure>>(
  'shows the products',
  build: () => ProductsBloc(load: (_) async => const Right([book])),
  act: (bloc) => bloc.fetch('Books'),
  expect: () => [
    isA<GenericLoading<List<Product>, Failure>>(),
    isA<GenericSuccess<List<Product>, Failure>>(),
  ],
);
```

Run the package tests with `flutter test`.

## Example

The `example` folder has a small shop app with categories, an empty category, random network errors, pull to refresh and a snack bar when a refresh fails.

```bash
cd example
flutter run
```

## Upgrading from 0.0.x

Version 1.0.0 fixes a few early design mistakes, so some code needs small changes:

| Before | Now |
|--------|-----|
| `Either<T, F>` (data on the left) | `Either<F, T>` (failure on the left, the usual convention) |
| `GenericBloc(callFunction: ..., errorMessage: 'text')` | `GenericBloc(load: ..., failureMessage: (f) => 'text')` |
| `GenericState<T>` | `GenericState<T, F>` |
| `GenericError` | `GenericFailure`, which also holds the failure, the error and the last data |
| `GenericBlocHelper.fetchData(context: c, parameter: p)` | `context.read<MyBloc>().fetch(p)` |
| `GenericBlocConsumer` | `GenericBlocBuilder` (the old widget still works but is deprecated) |
| `FetchDataEvent(parameter: p)` | `bloc.fetch(p)` (the old event still works but is deprecated) |

## License

MIT. See [LICENSE](LICENSE).
