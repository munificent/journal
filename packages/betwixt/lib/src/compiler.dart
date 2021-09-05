import 'package:source_span/source_span.dart';

import '../betwixt.dart';
import 'ast.dart';
import 'error_reporter.dart';
import 'functions.dart';
import 'include_visitor.dart';
import 'parser.dart';
import 'token.dart';
import 'wrapping_error_reporter.dart';

class Compiler {
  final Map<String, Stmt> _templates = {};
  final WrappingErrorReporter _reporter;
  final IncludeLoader? _loader;
  final BetwixtFunction? Function(String name)? _functionBinder;

  Compiler(this._loader, this._functionBinder, ErrorReporter reporter)
      : _reporter = WrappingErrorReporter(reporter);

  Future<Stmt?> compile(String source, String url) async {
    // Load and parse all the templates.
    var statement = Parser.parseSource(_reporter, source, url);
    var includeVisitor = IncludeVisitor(_reporter, _loader);
    _templates.addAll(await includeVisitor.traverse(statement));

    if (_reporter.hadError) return null;

    // Resolve all of the templates.
    var resolver = _Resolver(this, _templates);
    resolver.resolve(statement);
    for (var template in _templates.values) {
      resolver.resolve(template);
    }

    if (_reporter.hadError) return null;

    return statement;
  }
}

/// Wires up all includes (recursively) and called functions.
class _Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  final Compiler _compiler;
  final Map<String, Stmt> _templates;
  final List<_Scope> _scopes = [];

  _Resolver(this._compiler, this._templates);

  void resolve(Stmt stmt) {
    _blockScope(stmt);
  }

  @override
  void visitBinaryExpr(BinaryExpr expr) {
    expr.left.accept(this);
    expr.right.accept(this);
  }

  @override
  void visitCallExpr(CallExpr expr) {
    // Resolve the function.
    var function = _compiler._functionBinder?.call(expr.name.text) ??
        findFunction(expr.name.text);

    if (function != null) {
      var maxArguments = function.maximumArguments;
      if (expr.arguments.length < function.minimumArguments) {
        _error(
            expr.name.span,
            'Not enough arguments. Expected at least '
            '${function.minimumArguments} but got ${expr.arguments.length}.');
      } else if (maxArguments != null && expr.arguments.length > maxArguments) {
        _error(
            expr.name.span,
            'Too many arguments. Expected at no more than '
            '$maxArguments but got ${expr.arguments.length}.');
      }

      expr.function = function.function;
    } else {
      _error(expr.name.span, 'Unknown function "${expr.name.text}".');
    }

    for (var argument in expr.arguments) {
      argument.accept(this);
    }
  }

  @override
  void visitErrorExpr(ErrorExpr expr) {}

  @override
  void visitLiteralExpr(LiteralExpr expr) {}

  @override
  void visitPropertyExpr(PropertyExpr expr) {
    expr.receiver.accept(this);
  }

  @override
  void visitUnaryExpr(UnaryExpr expr) {
    expr.expression.accept(this);
  }

  @override
  void visitVariableExpr(VariableExpr expr) {
    _resolve(expr.name, 'use');
  }

  @override
  void visitErrorStmt(ErrorStmt stmt) {}

  @override
  void visitIfStmt(IfStmt stmt) {
    stmt.condition.accept(this);
    _blockScope(stmt.thenStatement);
    _blockScope(stmt.elseStatement);
  }

  @override
  void visitForStmt(ForStmt stmt) {
    stmt.expression.accept(this);
    _blockScope(stmt.body, [stmt.variable]);
    _blockScope(stmt.between, [stmt.before, stmt.after]);
    _blockScope(stmt.elseStatement);
  }

  @override
  void visitIncludeStmt(IncludeStmt stmt) {
    // Resolve the template.
    stmt.template = _templates[stmt.name.text]!;
  }

  @override
  void visitLetStmt(LetStmt stmt) {
    stmt.value.accept(this);
    _define(stmt.name);
  }

  @override
  void visitRenderStmt(RenderStmt stmt) {
    stmt.expression.accept(this);
  }

  @override
  void visitSequenceStmt(SequenceStmt stmt) {
    for (var statement in stmt.statements) {
      statement.accept(this);
    }
  }

  @override
  void visitSetStmt(SetStmt stmt) {
    if (!_resolve(stmt.name, 'set')) {
      _error(
          stmt.name.span, 'Cannot set unknown variable "${stmt.name.text}".');
    }
    stmt.value.accept(this);
  }

  @override
  void visitTextStmt(TextStmt stmt) {
    // TODO: Could have a compiler that merges adjacent text statements when
    // included templates get merged together.
  }

  void _declare(Token variable) {
    var scope = _scopes.last;
    if (scope._declared.contains(variable.text)) {
      // TODO: Show line where previous variable is declared.
      _error(
          variable.span,
          'There is already a variable named "${variable.text}" '
          'declared in this scope.');
    }

    scope._declared.add(variable.text);
  }

  void _define(Token variable) {
    _scopes.last._defined.add(variable.text);
  }

  bool _resolve(Token variable, String use) {
    for (var i = _scopes.length - 1; i >= 0; i--) {
      var scope = _scopes[i];
      if (scope._declared.contains(variable.text)) {
        if (!scope._defined.contains(variable.text)) {
          // TODO: Show line where variable is declared.
          _error(variable.span, 'Cannot $use variable before it is defined.');
        }

        return true;
      }
    }

    // If we get here, the variable wasn't found.
    return false;
  }

  /// Traverses [stmt] in a new block scope.
  void _blockScope(Stmt? stmt, [List<Token?> variables = const []]) {
    if (stmt == null) return;

    _scopes.add(_Scope());

    // Any language-provided variables are already declared and initialized.
    for (var variable in variables) {
      if (variable == null) continue;
      _declare(variable);
      _define(variable);
    }

    // Eagerly declare any variables in the body. This way we can report errors
    // if they are used before being defined.
    if (stmt is SequenceStmt) {
      for (var child in stmt.statements) {
        if (child is LetStmt) {
          _declare(child.name);
        }
      }
    } else if (stmt is LetStmt) {
      _declare(stmt.name);
    }

    stmt.accept(this);
    _scopes.removeLast();
  }

  void _error(FileSpan span, String message) {
    _compiler._reporter.report(span, message);
  }
}

class _Scope {
  /// The variables declared in this scope.
  final Set<String> _declared = {};

  /// The variables defined by the current point in this scope.
  final Set<String> _defined = {};

  void declareAndDefine(Token variable) {
    _declared.add(variable.text);
    _defined.add(variable.text);
  }
}
