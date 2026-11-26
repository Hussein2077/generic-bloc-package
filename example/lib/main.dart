import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:generic_bloc/generic_bloc.dart';

void main() => runApp(const ExampleApp());

// ---------------------------------------------------------------------------
// Data layer: a fake repository that sometimes fails, like a real network.
// ---------------------------------------------------------------------------

class Failure {
  const Failure(this.message);
  final String message;
}

class Product {
  const Product(this.name, this.price);
  final String name;
  final double price;
}

class ProductRepository {
  final _random = Random();

  /// Left is a failure, Right is the data.
  Future<Either<Failure, List<Product>>> getProducts(String category) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (_random.nextInt(4) == 0) {
      return const Left(Failure('Could not reach the server.'));
    }
    if (category == 'Toys') return const Right([]);

    return Right(List.generate(
      8,
      (i) => Product('$category item ${i + 1}', 10.0 + i * 2.5),
    ));
  }
}

// ---------------------------------------------------------------------------
// One line of "BLoC code" per screen.
// ---------------------------------------------------------------------------

typedef ProductsBloc = GenericBloc<List<Product>, String, Failure>;

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();

    return MaterialApp(
      title: 'generic_bloc example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: BlocProvider(
        create: (_) => ProductsBloc(
          load: repository.getProducts,
          failureMessage: (failure) => failure.message,
          isEmpty: (products) => products.isEmpty,
        )..fetch('Books'),
        child: const ProductsPage(),
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  static const categories = ['Books', 'Phones', 'Toys'];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductsBloc>();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final category in categories)
                  ActionChip(
                    label: Text(category),
                    onPressed: () => bloc.fetch(category),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GenericBlocBuilder<List<Product>, String, Failure>(
              showDataOnFailure: true,
              onEmpty: (_) => const Center(child: Text('No products here.')),
              listener: (context, state) {
                // Old data is still on screen, so a snack bar is enough.
                if (state is GenericFailure<List<Product>, Failure> &&
                    state.hasData) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              onSuccess: (context, products) => RefreshIndicator(
                onRefresh: () async {
                  bloc.refresh();
                  await bloc.stream.firstWhere((s) => !s.isLoading);
                },
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.name),
                      trailing: Text('\$${product.price.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
