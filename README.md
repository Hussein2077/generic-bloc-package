# Generic BLoC Package

A flexible and reusable Flutter package for managing state using the BLoC (Business Logic Component) pattern. This package simplifies state management, provides enhanced error handling, and supports versatile use cases with flexible generic types.

---

## Features

- **Custom Error Handling**: Easily pass custom error messages for graceful failure handling.
- **Flexible Generics**: Supports three generic types:
  - **T**: The type of data to manage (e.g., a list of items or a single model).
  - **P**: The type of the input parameter for API calls or functions.
  - **F**: The type of failure returned from API calls or other operations.
- **Simplified State Management**: Reduces boilerplate code by managing common states like loading, success, and error.
- **Seamless Integration**: Fully compatible with `flutter_bloc` and integrates smoothly into Flutter projects.

---

## Installation

Add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  generic_bloc: ^1.0.0
```

Then, fetch the package using:

```bash
flutter pub get
```

---

## Usage

### 1. Create a GenericBloc

Define a `GenericBloc` by specifying the types **T**, **P**, and **F**. Pass the required `callFunction` and `errorMessage` parameters:

```dart
import 'package:generic_bloc/generic_bloc.dart';

class ExampleBloc extends GenericBloc<List<String>, int, String> {
  ExampleBloc()
      : super(
          callFunction: myRepository.fetchItems,
          errorMessage: 'Failed to load data',
        );
}
```

### 2. Dispatch Events

Use the `FetchDataEvent` to trigger data fetching in the BLoC:

```dart
final exampleBloc = ExampleBloc();

// Dispatch event
exampleBloc.add(FetchDataEvent(parameter: 1));
```

### 3. Handle States

Use `BlocBuilder` to manage the different states of the BLoC:

```dart
BlocBuilder<ExampleBloc, GenericState<List<String>>>(
  builder: (context, state) {
    if (state is GenericLoading) {
      return CircularProgressIndicator();
    } else if (state is GenericSuccess<List<String>>) {
      return ListView.builder(
        itemCount: state.data.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(state.data[index]));
        },
      );
    } else if (state is GenericError) {
      return Text('Error: ${state.errorMessage}');
    } else {
      return Container();
    }
  },
);
```

### Example Repository

Here’s an example of a repository function that works with `GenericBloc`:

```dart
import 'package:dartz/dartz.dart';

class MyRepository {
  Future<Either<List<String>, String>> fetchItems(int id) async {
    try {
      // Simulate API response
      final data = ['Item 1', 'Item 2', 'Item 3'];
      return Left(data);
    } catch (e) {
      return Right('An error occurred');
    }
  }
}

final myRepository = MyRepository();
```

### Unit Testing

Test your `GenericBloc` with ease using the following example:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:generic_bloc/generic_bloc.dart';
import 'package:dartz/dartz.dart';

void main() {
  test('GenericBloc initial state should be GenericInitial', () {
    final bloc = GenericBloc<int, String, String>(
      callFunction: (_) async => const Left(42),
      errorMessage: 'An error occurred',
    );

    expect(bloc.state, isA<GenericInitial<int>>());
  });
}
```

---

## Advantages

- **Reusable Logic**: Write once and reuse across multiple features or screens.
- **Customizable Error Handling**: Handle errors with meaningful messages.
- **Type Safety**: Strongly typed states and events ensure better code quality and fewer runtime errors.

---

## Contributing

Contributions are welcome! If you find any bugs or have suggestions for improvements, feel free to open an issue or submit a pull request.

---

## License

This package is distributed under the MIT License. See the LICENSE file for details.

