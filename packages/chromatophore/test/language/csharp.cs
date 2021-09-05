// === Type names ===

// Leading keyword.
class Foo {}
struct Foo {}
enum Foo {}
new Foo();
new Dictionary<List<int>, Monster>();
foo as Foo;
foo is Foo;

// Built in types.
int x;
string s;

// Type names in type annotations.
Foo f;
Foo Function(Foo foo, Bar bar) {}
Array[][] f;

// In where clauses.
T GetAt<T>() where T : IPosition, Generic<T, int> {}

// Generic types.
Dictionary<List<Foo>, Bar[]> dict;

// Supertypes.
public class Monster: /* c */ Actor, IPosition<int> {}

// Nullable variables.
int? i;
Monster? mon;

// Casts.
(Foo)foo;
(Dict<Foo, Bar>)dict;

// Not generic method calls.
Array.Sort<int, Data>(indirect, data);

// === Preprocessor ===

#define SOME_CONSTANT

#undef SOME_CONSTANT

class Foo {
  #region Some region
  void Method() {}
  #endregion
}

#if /* comment */ DEBUG != !RELEASE && PROFILE

Some(code);

#elif

more.Code();

#else // Comment.

#endif

// === Attributes.

[TestFixture]
[Another(SetLastError=false, ExactSpelling=false)]
[Conditional("DEBUG")]
public class NotNullFixture
{
    [System.Runtime.InteropServices.DllImport("user32.dll")]
    public void Foo([In][Out] ref double x, [Out] ref int y)
    {
    }
}
