import 'package:source_span/source_span.dart';

import 'token.dart';

abstract class Stmt {
  R accept<R>(StmtVisitor<R> visitor);
}

/// Placeholder node created when a parse error occurs.
class ErrorStmt implements Stmt {
  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitErrorStmt(this);
}

class ForStmt implements Stmt {
  final Token variable;
  // TODO: Rename.
  final Expr expression;
  final Stmt body;

  // TODO: Rename.
  final Stmt? between;

  /// Variable for the before variable in a between clause or `null` if none.
  final Token? before;

  /// Variable for the after variable in a between clause or `null` if none.
  final Token? after;

  final Stmt? elseStatement;

  ForStmt(this.variable, this.expression, this.body, this.between, this.before,
      this.after, this.elseStatement);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitForStmt(this);
}

class IfStmt implements Stmt {
  final Expr condition;

  final Stmt thenStatement;
  final Stmt? elseStatement;

  IfStmt(this.condition, this.thenStatement, this.elseStatement);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitIfStmt(this);
}

class IncludeStmt implements Stmt {
  final Token name;

  /// The variables that should be bound in the included template.
  final Map<String, Expr> variables;

  /// After resolution, this will point to the code for the included template.
  late final Stmt template;

  IncludeStmt(this.name, this.variables);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitIncludeStmt(this);
}

/// Declare a local variable in the current scope.
class LetStmt implements Stmt {
  final Token name;
  final Expr value;

  LetStmt(this.name, this.value);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitLetStmt(this);
}

/// A sequence of statements.
class SequenceStmt implements Stmt {
  final List<Stmt> statements;

  SequenceStmt(this.statements);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitSequenceStmt(this);
}

/// Assign to an existing local variable.
class SetStmt implements Stmt {
  final Token name;
  final Expr value;

  SetStmt(this.name, this.value);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitSetStmt(this);
}

/// Literal text output.
class TextStmt implements Stmt {
  final String text;

  TextStmt(this.text);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitTextStmt(this);
}

/// Renders the result of some expression.
class RenderStmt implements Stmt {
  final Expr expression;

  RenderStmt(this.expression);

  @override
  R accept<R>(StmtVisitor<R> visitor) => visitor.visitRenderStmt(this);
}

/// IR object that has an effect: either control flow or rendered output.
abstract class StmtVisitor<R> {
  R visitErrorStmt(ErrorStmt stmt);
  R visitForStmt(ForStmt stmt);
  R visitIfStmt(IfStmt stmt);
  R visitIncludeStmt(IncludeStmt stmt);
  R visitLetStmt(LetStmt stmt);
  R visitSequenceStmt(SequenceStmt stmt);
  R visitSetStmt(SetStmt stmt);
  R visitTextStmt(TextStmt stmt);
  R visitRenderStmt(RenderStmt stmt);
}

/// IR object that evaluates to produce a value.
abstract class Expr {
  FileSpan get span;

  R accept<R>(ExprVisitor<R> visitor);
}

// TODO: Test.
class BinaryExpr extends Expr {
  final Expr left;
  final Token op;
  final Expr right;

  BinaryExpr(this.left, this.op, this.right);

  @override
  FileSpan get span => left.span.expand(right.span);

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitBinaryExpr(this);
}

class CallExpr extends Expr {
  final Token name;
  final List<Expr> arguments;
  final Token rightParen;

  /// After resolution, this will point to the function to call.
  late final Object? Function(List<Object?> arguments) function;

  CallExpr(this.name, this.arguments, this.rightParen);

  @override
  FileSpan get span => name.span.expand(rightParen.span);

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitCallExpr(this);
}

/// Placeholder node created when a parse error occurs.
class ErrorExpr implements Expr {
  @override
  FileSpan get span => throw UnsupportedError('');

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitErrorExpr(this);
}

class LiteralExpr extends Expr {
  final Token token;
  final Object? value;

  LiteralExpr(this.token, this.value);

  @override
  FileSpan get span => token.span;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitLiteralExpr(this);
}

class PropertyExpr extends Expr {
  final Expr receiver;
  final Token name;

  PropertyExpr(this.receiver, this.name);

  @override
  FileSpan get span => receiver.span.expand(name.span);

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitPropertyExpr(this);
}

class UnaryExpr extends Expr {
  final Token op;
  final Expr expression;

  UnaryExpr(this.op, this.expression);

  @override
  FileSpan get span => op.span.expand(expression.span);

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitUnaryExpr(this);
}

class VariableExpr extends Expr {
  final Token name;

  VariableExpr(this.name);

  @override
  FileSpan get span => name.span;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitVariableExpr(this);
}

abstract class ExprVisitor<R> {
  R visitBinaryExpr(BinaryExpr expr);
  R visitCallExpr(CallExpr expr);
  R visitErrorExpr(ErrorExpr expr);
  R visitLiteralExpr(LiteralExpr expr);
  R visitPropertyExpr(PropertyExpr expr);
  R visitUnaryExpr(UnaryExpr expr);
  R visitVariableExpr(VariableExpr expr);
}
