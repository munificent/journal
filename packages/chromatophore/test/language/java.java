static final SOME_CONSTANT = 123;

@metadata
Expression parseExpression() {
  if (match(TokenType.NAME))       // return NameExpression...
  else if (match(TokenType.PLUS))  // return prefix + operator...
}

// Strings.
"" // Empty.
"abd false"
"\t \b \n \r \" escapes"
