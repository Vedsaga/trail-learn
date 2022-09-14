import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

@immutable
class AppState {
  final int counter;
  final String description;

  const AppState({
    required this.counter,
    required this.description,
  });

  AppState copy({int? counter, String? description}) => AppState(
        counter: counter ?? this.counter,
        description: description ?? this.description,
      );

  static AppState initialState() => const AppState(counter: 0, description: "");

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          counter == other.counter &&
          description == other.description;

  @override
  int get hashCode => counter.hashCode ^ description.hashCode;
}

late Store<AppState> store;

/// This action increments the counter by [amount]].
class IncrementAction extends ReduxAction<AppState> {
  final int amount;

  IncrementAction({required this.amount});

  // Synchronous reducer.
  @override
  AppState reduce() => state.copy(counter: state.counter + amount);
}

/// This action decrements the counter by [amount]].
class DecrementAction extends ReduxAction<AppState> {
  final int amount;
  DecrementAction({required this.amount});
  @override
  AppState reduce() => state.copy(counter: state.counter - amount);
}

/// This action increments the counter by 1,
/// and then gets some description text relating to the new counter number.
class IncrementAndGetDescriptionAction extends ReduxAction<AppState> {
  //
  // Async reducer.
  // To make it async we simply return Future<AppState> instead of AppState.
  @override
  Future<AppState> reduce() async {
    // First, we increment the counter, synchronously.
    dispatch(IncrementAction(amount: 1));

    // Then, we start and wait for some asynchronous process.
    String description =
        await read(Uri.http("numbersapi.com", "${state.counter}"));

    // After we get the response, we can modify the state with it,
    // without having to dispatch another action.
    return state.copy(description: description);
  }
}

class DecrementAndGetDescriptionAction extends ReduxAction<AppState> {
  //
  // Async reducer.
  // To make it async we simply return Future<AppState> instead of AppState.
  @override
  Future<AppState> reduce() async {
    // First, we decrement the counter, synchronously.
    dispatch(DecrementAction(amount: 1));

    // Then, we start and wait for some asynchronous process.
    String description =
        await read(Uri.http("numbersapi.com", "${state.counter}"));

    // After we get the response, we can modify the state with it,
    // without having to dispatch another action.
    return state.copy(description: description);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
          home: StoreProvider<AppState>(
        store: store,
        child: const MyHomePage(),
      ));
}

/// This example shows a counter, a text description, and a button.
/// When the button is tapped, the counter will increment synchronously,
/// while an async process downloads some text description that relates
/// to the counter number (using the NumberAPI: http://numbersapi.com).
///
/// Note: This example uses http. It was configured to work in Android, debug mode only.
/// If you use iOS, please see:
/// https://flutter.dev/docs/release/breaking-changes/network-policy-ios-android
///
void main() {
  var state = AppState.initialState();
  store = Store<AppState>(initialState: state);
  runApp(const MyApp());
}

enum FontVariationAxis {
  ital,
  opsz,
  slnt,
  wdth,
  wght,
}

/// This widget is a connector. It connects the store to "dumb-widget".
/// It is a StatelessWidget, which means that it can be used in any place
/// where a StatelessWidget can be used.

/// This is a Count Increment ui.
class IncrementUi extends StatelessWidget {
  const IncrementUi({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ViewModel>(
        converter: ViewModel.fromStore,
        builder: (context, snapshot) {
          /// use ReduxSelector to get the int count from the store
          /// and use it to build the ui.
          ///  /// randomly generate hex color when ever this widget is built.
          final color = Color.fromARGB(255, Random.secure().nextInt(255),
              Random.secure().nextInt(255), Random.secure().nextInt(255));
          return Text(
            "${snapshot.counter}",
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontVariations: <FontVariation>[
                FontVariation(
                  FontVariationAxis.wght.name,
                  900,
                ),
              ],
            ),
          );
        });
  }
}

/// This is a Description ui.
class DescriptionUi extends StatelessWidget {
  final String? description;
  const DescriptionUi({
    Key? key,
    this.description,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    /// use ReduxSelector to get the String description from the store
    /// and use it to build the ui.
    return StoreConnector<AppState, ViewModel>(
        converter: ViewModel.fromStore,
        builder: (context, snapshot) {
          /// randomly generate hex color when ever this widget is built.
          final color = Color.fromARGB(255, Random.secure().nextInt(255),
              Random.secure().nextInt(255), Random.secure().nextInt(255));
          return Text(
            snapshot.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontVariations: <FontVariation>[
                FontVariation(
                  FontVariationAxis.wght.name,
                  900,
                ),
              ],
            ),
          );
        });
  }
}

// /// Factory that creates a view-model for the StoreConnector.
class Factory extends VmFactory<AppState, MyHomePage> {
  Factory(widget) : super(widget);

  @override
  ViewModel fromStore() => ViewModel(
        counter: state.counter,
        description: state.description,
        onIncrement: () => dispatch(IncrementAndGetDescriptionAction()),
        onDecrement: () => dispatch(DecrementAndGetDescriptionAction()),
      );
}

/// The view-model holds the part of the Store state the dumb-widget needs.
class ViewModel extends Vm {
  final int counter;
  final String description;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  ViewModel({
    required this.counter,
    required this.description,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(equals: [counter, description]);

  /// Static factory called by the StoreConnector's converter parameter.
  static ViewModel fromStore(Store<AppState> store) {
    return ViewModel(
      counter: store.state.counter,
      description: store.state.description,
      onIncrement: () => store.dispatch(IncrementAndGetDescriptionAction()),
      onDecrement: () => store.dispatch(DecrementAndGetDescriptionAction()),
    );
  }
}

/// The screen has a counter, a text description, and a button.
/// When the button is tapped, the counter will increment synchronously,
/// while an async process downloads some text description.
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ViewModel>(
        vm: () => Factory(this),
        builder: (context, snapshot) {
          return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    IncrementUi(),
                    SizedBox(height: 24),
                    DescriptionUi(),
                    // Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 16),
                    //   child: Center(child: DescriptionUi()),
                    // ),
                  ],
                ),
              ),
              floatingActionButton: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: () => snapshot.onIncrement(),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 24),
                    FloatingActionButton(
                      backgroundColor: Colors.red,
                      onPressed: () => snapshot.onDecrement(),
                      child: const Icon(Icons.remove),
                    ),
                  ]));
        });
  }
}


