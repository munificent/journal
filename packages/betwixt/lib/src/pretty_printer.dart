import 'ast.dart';
import 'string_extension.dart';
import 'token.dart';

/// Pretty-prints code to a Lisp-like form for test validation.
class PrettyPrinter implements ExprVisitor<void>, StmtVisitor<void> {
  static String print(Stmt statement) {
    var visitor = PrettyPrinter();
    statement.accept(visitor);
    return visitor._buffer.toString();
  }

  final StringBuffer _buffer = StringBuffer();

  int _indent = 0;

  @override
  void visitBinaryExpr(BinaryExpr expr) {
    _inline(expr.op.text, expr.left, expr.right);
  }

  @override
  void visitCallExpr(CallExpr expr) {
    _inline('call', expr.name, expr.arguments);
  }

  @override
  void visitErrorExpr(ErrorExpr expr) {
    _inline('error');
  }

  @override
  void visitLiteralExpr(LiteralExpr expr) {
    var value = expr.value;
    if (value is String) {
      _write("'${value.toStringLiteral()}'");
    } else {
      _write(value);
    }
  }

  @override
  void visitPropertyExpr(PropertyExpr expr) {
    _inline('prop', expr.receiver, expr.name);
  }

  @override
  void visitUnaryExpr(UnaryExpr expr) {
    _inline(expr.op.text, expr.expression);
  }

  @override
  void visitVariableExpr(VariableExpr expr) {
    _inline('var', expr.name);
  }

  @override
  void visitErrorStmt(ErrorStmt expr) {
    _inline('error');
  }

  @override
  void visitIfStmt(IfStmt stmt) {
    _beginBlock('if', inline: [stmt.condition], body: stmt.thenStatement);
    _blockClause('else', body: stmt.elseStatement);
    _endBlock();
  }

  @override
  void visitForStmt(ForStmt stmt) {
    _beginBlock('for',
        inline: [stmt.variable, 'in', stmt.expression], body: stmt.body);

    if (stmt.before != null) {
      _blockClause('between',
          inline: [stmt.before, 'and', stmt.after], body: stmt.between);
    } else {
      _blockClause('between', body: stmt.between);
    }

    _blockClause('else', body: stmt.elseStatement);
    _endBlock();
  }

  @override
  void visitIncludeStmt(IncludeStmt stmt) {
    _write('(include ');
    _write(stmt.name);

    if (stmt.variables.isNotEmpty) {
      _write(' with');
      stmt.variables.forEach((variable, expression) {
        _write(' ');
        _inline(variable, expression);
      });
    }

    _write(')');
  }

  @override
  void visitLetStmt(LetStmt stmt) {
    _inline('let', stmt.name, '=', stmt.value);
  }

  @override
  void visitRenderStmt(RenderStmt stmt) {
    _inline('render', stmt.expression);
  }

  @override
  void visitSequenceStmt(SequenceStmt stmt) {
    _beginBlock('seq', body: stmt.statements);
    _endBlock();
  }

  @override
  void visitSetStmt(SetStmt stmt) {
    _inline('set', stmt.name, '=', stmt.value);
  }

  @override
  void visitTextStmt(TextStmt stmt) {
    _write('<');
    _write(stmt.text.toStringLiteral());
    _write('>');
  }

  void _inline(String name, [Object? arg1, Object? arg2, Object? arg3]) {
    _buffer.write('($name');
    _write([arg1, arg2, arg3], _space);
    _buffer.write(')');
  }

  void _beginBlock(String name, {List<Object?>? inline, Object? body}) {
    _buffer.write('($name');
    if (inline != null) _write(inline, _space);
    _indent++;
    if (body != null) _write(body, _newline);
  }

  void _blockClause(String name, {List<Object?>? inline, required Stmt? body}) {
    if (body == null) return;

    _indent--;
    _write(name, _newline);
    if (inline != null) _write(inline, _space);
    _indent++;
    _write(body, _newline);
  }

  void _endBlock() {
    _indent--;
    _newline();
    _buffer.write(')');
  }

  void _write(Object? object, [void Function()? before]) {
    if (object == null) return;

    if (object is Iterable<Object?>) {
      for (var element in object) {
        _write(element, before);
      }
      return;
    }

    if (before != null) before();

    if (object is Token) {
      _buffer.write(object.text);
    } else if (object is Stmt) {
      object.accept(this);
    } else if (object is Expr) {
      object.accept(this);
    } else {
      _buffer.write(object);
    }
  }

  void _space() {
    _buffer.write(' ');
  }

  void _newline() {
    _buffer.writeln();
    _buffer.write('  ' * _indent);
  }
}
