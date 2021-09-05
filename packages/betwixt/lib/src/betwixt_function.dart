import 'dart:async';

/// A user-defined Dart function that can be called from a template.
class BetwixtFunction {
  /// The underlying primitive function.
  final FutureOr<Object?> Function(List<Object?> arguments) function;

  /// The minimum number of arguments this function requires.
  final int minimumArguments;

  /// The maximum number of arguments this function accepts.
  ///
  /// If this is `null`, then the function is assumed to be variadic and can
  /// handle any number of arguments.
  final int? maximumArguments;

  BetwixtFunction(this.function, this.minimumArguments, this.maximumArguments);
}
