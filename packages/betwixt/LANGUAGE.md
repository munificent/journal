# Betwixt Language Reference

**TODO: Intro**

## Basic syntax

**TODO**

### Literal text

**TODO**

### Tags

**TODO**

### Whitespace

**TODO**

## Statements

**TODO: Intro**

### For statement

```
{{ for item in sequence }}
  {{ item }}
{{ end }}
```

```
{{ for item in sequence }}
  {{ item }}
{{ else }}
  empty list
{{ end }}
```

```
{{ for item in sequence }}
  {{ item }}
{{ else }}
  empty list
{{ end }}
```

```
{{ for item in sequence }}
  {{ item }}
{{ between }}
  ---
{{ end }}
```

```
{{ for item in sequence }}
  {{ item }}
{{ between before and after }}
  ---
{{ end }}
```

### If statement

```
{{ if condition }}
  was true
{{ end }}
```

```
{{ if condition }}
  was true
{{ else }}
  was false
{{ end }}
```

### Include statement

```
{{ include "other_template" }}
```

```
{{ include "other_template" with a = 1, b = 2 }}
```

```
{{ let a = 1 }}
{{ let b = 2 }}
{{ include "other_template" with a, b }}
```

**TODO: Explain includes do not inherit variables in scope where included.**

**TODO: Describe whether includes have access to global data.**

### Let statement

```
{{ let color = "violet" }}
```

**TODO: Talk about scope.**

### Set statement

```
{{ set color = "violet" }}
```

## Expressions

### Equality expressions

```
a == b
a != b
```

### Call expressions

```
foo(a, b, c)
```

### Literal expressions

```
null
false
true
12.34
"a string"
```

**TODO: String escapes, number formats.**

### Property expressions

```
foo.bar
```

**TODO: What kind of properties can be accessed on what objects.**

### Arithmetic expressions

```
-foo
12 + 34
"str" + "ing"
43 - 21
```

**TODO: Need to add other arithmetic operators.**

### Variable expressions

```
foo
```
