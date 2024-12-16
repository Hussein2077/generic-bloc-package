# Generic BLoC Package

A flexible and reusable Flutter package for managing state using the BLoC (Business Logic Component) pattern. This updated version provides enhanced control over error handling and supports three generic types for added versatility.

## Features

- **Custom Error Messages**: Pass a custom error message to handle failures gracefully.
- **Flexible Generics**: Supports three generic types:
    - `T` - The type of data to manage (e.g., a list of items or a single model).
    - `P` - The type of the input parameter for API calls or functions.
    - `F` - The type of failure returned from API calls or other operations.
- **Simplified State Management**: Reduces boilerplate by handling common states like loading, success, and error.
- **Easy Integration**: Compatible with `flutter_bloc` and seamlessly integrates into Flutter projects.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  generic_bloc: ^1.0.0
Then run:

bash
Copy code
flutter pub get
Usage
1. Create a GenericBloc
Define a GenericBloc by specifying the types T, P, and F. Pass the required callFunction and errorMessage parameters:

dart
Copy code
import 'package:generic_bloc/generic_bloc.dart';

class ExampleBloc extends GenericBloc<List<String>, int, String> {
  ExampleBloc() : super(
    callFunction: myRepository.fetchItems,
    errorMessage: 'Failed to load data',
  );
}
2. Dispatch Events
Add a FetchDataEvent to the BLoC with the required parameter:

dart
Copy code
final exampleBloc = ExampleBloc();

// Dispatch event
exampleBloc.add(FetchDataEvent(parameter: 1));
3. Handle States
Use BlocBuilder to handle the different states of the BLoC:

dart
Copy code
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
Example Repository
Here's an example of a repository function that works with GenericBloc:

dart
Copy code
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
Unit Testing
Test your GenericBloc with ease using the following example:

dart
Copy code
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
Advantages
Reusable Logic: Write once and reuse across multiple features or screens.
Error Customization: Handle errors with meaningful messages.
Type Safety: Strongly typed states and events ensure better code quality.
Contributing
Contributions are welcome! If you find bugs or have suggestions for improvements, feel free to open an issue or submit a pull request.

License
This package is distributed under the MIT License. See LICENSE for details.

markdown
Copy code

### Key Updates in the Readme
1. Added a **Flexible Generics** section to explain the three generic types (`T`, `P`, `F`).
2. Updated the **Usage** section to reflect the new `errorMessage` parameter and enhanced flexibility.
3. Included an **Example Repository** for better context.
4. Added a **Unit Testing** section showcasing how to test the updated `GenericBloc`.

You can copy and paste this content into your `README.md`. Let me know if you'd like further adjustments!
