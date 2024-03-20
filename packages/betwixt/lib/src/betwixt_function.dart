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

/// Exception class used to report a runtime error from calling a function.
class FunctionCallException {
  /// The error message.
  final String message;

  /// The index of the argument that led to this error or -1 if the error isn't
  /// associated with a particular argument.
  final int argumentIndex;

  FunctionCallException(this.message, [this.argumentIndex = -1]);
}
