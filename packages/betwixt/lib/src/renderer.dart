import 'dart:async';

import 'package:betwixt/betwixt.dart';
import 'package:source_span/source_span.dart';

import 'ast.dart';
import 'data.dart';
import 'error_reporter.dart';
import 'token.dart';

/// Renders a template.
class Renderer
    implements StmtVisitor<Future<void>>, ExprVisitor<Future<Object?>> {
  /// The root object that top level variable accesses are resolved on.
  final Object? _root;

  final ErrorReporter _reporter;

  /// The stack of local variable environments.
  List<Map<String, Object?>> _locals = [{}];

  final StringBuffer _buffer = StringBuffer();

  Renderer(this._root, this._reporter);

  String get output => _buffer.toString();

  @override
  Future<void> visitErrorStmt(ErrorStmt stmt) async {
    assert(false, 'Should not have errors.');
  }

  @override
  Future<void> visitForStmt(ForStmt stmt) async {
    var sequence = await stmt.expression.accept(this);
    if (sequence is! Iterable<Object?>) {
      _reporter.report(stmt.expression.span,
          'Object of type ${sequence.runtimeType} is not iterable.');
      return;
    }

    var isEmpty = true;
    Object? previous;
    for (var element in sequence) {
      // TODO: Can the element be a future?

      if (!isEmpty && stmt.between != null) {
        if (stmt.before != null) {
          await _runInScope(stmt.between!,
              {stmt.before!.text: previous, stmt.after!.text: element});
        } else {
          await _runInScope(stmt.between!);
        }
      }

      await _runInScope(stmt.body, {stmt.variable.text: element});

      isEmpty = false;
      previous = element;
    }

    if (isEmpty && stmt.elseStatement != null) {
      await _runInScope(stmt.elseStatement!);
    }
  }

  @override
  Future<void> visitIfStmt(IfStmt stmt) async {
    var condition = await stmt.condition.accept(this);
    if (_isTruthy(condition, stmt.condition.span)) {
      await _runInScope(stmt.thenStatement);
    } else if (stmt.elseStatement != null) {
      await _runInScope(stmt.elseStatement!);
    }
  }

  @override
  Future<void> visitIncludeStmt(IncludeStmt stmt) async {
    var variables = <String, Object?>{};
    for (var variable in stmt.variables.keys) {
      var value = await stmt.variables[variable]!.accept(this);
      variables[variable] = value;
    }

    // TODO: Don't allow global data access in includes?
    var oldLocals = _locals;
    try {
      // Swap out the locals. An included template only gets the global data
      // and the variables it is explicitly passed.
      _locals = [variables];
      await stmt.template.accept(this);
    } finally {
      _locals = oldLocals;
    }
  }

  @override
  Future<void> visitLetStmt(LetStmt stmt) async {
    // TODO: Weird idea: Don't await the value? We could make the template
    // language fully lazy and only evaluate values when needed?
    var value = await stmt.value.accept(this);

    _locals.last[stmt.name.text] = value;
  }

  @override
  Future<void> visitRenderStmt(RenderStmt stmt) async {
    var value = await stmt.expression.accept(this);
    _buffer.write(value.toString());
  }

  @override
  Future<void> visitSequenceStmt(SequenceStmt stmt) async {
    for (var statement in stmt.statements) {
      await statement.accept(this);
    }
  }

  @override
  Future<void> visitSetStmt(SetStmt stmt) async {
    var value = await stmt.value.accept(this);

    // TODO: Resolve this statically.
    // Find the variable.
    for (var i = _locals.length - 1; i >= 0; i--) {
      var environment = _locals[i];
      if (environment.containsKey(stmt.name.text)) {
        environment[stmt.name.text] = value;
        return;
      }
    }

    assert(false, 'Should have gotten compile error for unknown variable.');
  }

  @override
  Future<void> visitTextStmt(TextStmt stmt) async {
    _buffer.write(stmt.text);
  }

  @override
  Future<Object?> visitBinaryExpr(BinaryExpr expr) async {
    var left = await expr.left.accept(this);
    var right = await expr.right.accept(this);
    switch (expr.op.type) {
      case TokenType.minus:
        if (left is! num) {
          _reporter.report(expr.left.span,
              'Cannot subtract from a value of type ${left.runtimeType}.');
          return null;
        }

        if (right is! num) {
          _reporter.report(expr.right.span,
              'Cannot subtract a value of type ${right.runtimeType}.');
          return null;
        }

        return left - right;

      case TokenType.plus:
        if (left is num && right is num) {
          return left + right;
        } else if (left is String) {
          return left + right.toString();
        } else if (right is String) {
          return left.toString() + right;
        } else {
          if (left is! num && left is! String) {
            _reporter.report(expr.left.span,
                'Operands to "+" must be numbers or strings, not ${left.runtimeType}.');
          }

          if (right is! num && right is! String) {
            _reporter.report(expr.right.span,
                'Operands to "+" must be numbers or strings, not ${right.runtimeType}.');
          }

          return null;
        }

      case TokenType.bangEqual:
        // TODO: Are there any implicit conversions?
        return left != right;

      case TokenType.equalEqual:
        // TODO: Are there any implicit conversions?
        return left == right;

      default:
        throw ArgumentError('Invalid binary operator ${expr.op.text}.');
    }
  }

  @override
  Future<Object?> visitCallExpr(CallExpr expr) async {
    var arguments = <Object?>[];
    for (var argument in expr.arguments) {
      arguments.add(await argument.accept(this));
    }

    return expr.function(arguments);
  }

  @override
  Future<Object?> visitErrorExpr(ErrorExpr expr) async {
    assert(false, 'Should not have errors.');
  }

  @override
  Future<Object?> visitLiteralExpr(LiteralExpr expr) async {
    return expr.value;
  }

  @override
  Future<Object?> visitPropertyExpr(PropertyExpr expr) async {
    return _findProperty(await expr.receiver.accept(this), expr.name);
  }

  @override
  Future<Object?> visitUnaryExpr(UnaryExpr expr) async {
    var value = await expr.expression.accept(this);
    switch (expr.op.type) {
      case TokenType.minus:
        if (value is num) return -value;

        _reporter.report(expr.op.span,
            'Cannot negate a value of type ${value.runtimeType}.');
        return null;

      default:
        throw ArgumentError('Invalid unary operator ${expr.op.text}.');
    }
  }

  @override
  Future<Object?> visitVariableExpr(VariableExpr expr) async {
    // TODO: Statically resolve these.
    // Look for a local variable first.
    for (var i = _locals.length - 1; i >= 0; i--) {
      var environment = _locals[i];
      if (environment.containsKey(expr.name.text)) {
        return environment[expr.name.text];
      }
    }

    // Not a local, so look on the top level object.
    return _findProperty(_root, expr.name);
  }

  Future<void> _runInScope(Stmt stmt, [Map<String, Object?>? locals]) async {
    _locals.add(locals ?? {});
    try {
      await stmt.accept(this);
    } finally {
      _locals.removeLast();
    }
  }

  bool _isTruthy(Object? value, SourceSpan span) {
    if (value == null) {
      return false;
    } else if (value is bool) {
      return value == true;
    } else if (value is String) {
      if (value.trim().isEmpty) return false;
      // TODO: What about 'true' and 'false' strings?
      return true;
    } else {
      // Everything else is truthy.
      // TODO: Empty lists?
      // TODO: User-defined boolean conversion?
      return true;
    }
  }

  Future<Object?> _findProperty(Object? data, Token property) async {
    Object? value;
    String? source;

    try {
      if (data is TemplateData) {
        value = await data.lookup(property.text);
      } else if (data is Map<String, Object?>) {
        if (!data.containsKey(property.text)) {
          _reporter.report(
              property.span, 'Map does not have key "${property.text}".');
          return null;
        }

        source = 'in map';
        value = await data[property.text];
      } else if (data is FutureOr<Object?> Function(String key)) {
        source = 'from accessor function';
        value = await data(property.text);
      } else if (data is DateTime) {
        switch (property.text) {
          case 'year':
            value = data.year;
            break;
          case 'month':
            value = data.month;
            break;
          case 'day':
            value = data.day;
            break;
          case 'hour':
            value = data.hour;
            break;
          case 'minute':
            value = data.minute;
            break;
          case 'second':
            value = data.second;
            break;
          case 'millisecond':
            value = data.millisecond;
            break;
          case 'microsecond':
            value = data.microsecond;
            break;
          case 'weekday':
            value = data.weekday;
            break;
          case 'utc':
            // TODO: Test.
            value = data.toUtc();
            break;
          case 'iso8601':
            // TODO: Test.
            value = data.toIso8601String();
            break;
          default:
            value = TemplateData.unknownProperty;
        }
      } else if (data is String) {
        switch (property.text) {
          case 'length':
            value = data.length;
            break;
          default:
            value = TemplateData.unknownProperty;
        }
      }
    } catch (error, stack) {
      source ??= 'on ${data.runtimeType}';
      // TODO: Trim stack trace to stop at this call.
      _reporter.report(property.span,
          'Exception accessing "${property.text}" $source:\n$error\n$stack');
      return null;
    }

    if (value == TemplateData.unknownProperty) {
      source ??= 'on ${data.runtimeType}';
      _reporter.report(
          property.span, 'Unknown property "${property.text}" $source.');
      return null;
    }

    return value;
  }
}
