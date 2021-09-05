import 'package:chromatophore/chromatophore.dart';

void main() {
  const source = 'int main() { if (c) return 123; }';
  var result = highlight(Language.c, source, Formatter.html);
  print(result);
}
