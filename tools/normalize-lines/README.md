# Normalize Lines

This tool takes in the standard input and normalizes its breaks at 80 chars, preserving words.

Example: 

```sh
echo "Comparisons are discussed elsewhere. For other binary operators, the operand types must be identical unless the operation involves shifts or untyped constants. For operations involving constants only, see the section on constant expressions.

Except for shift operations, if one operand is an untyped constant and the other operand is not, the constant is implicitly converted to the type of the other operand.

The right operand in a shift expression must have integer type [Go 1.13] or be an untyped constant representable by a value of type uint. If the left operand of a non-constant shift expression is an untyped constant, it is first implicitly converted to the type it would assume if the shift expression were replaced by its left operand alone." \
| normalize-lines
```

Will output:

```text
Comparisons are discussed elsewhere. For other binary operators, the operand
types must be identical unless the operation involves shifts or untyped
constants. For operations involving constants only, see the section on constant
expressions.

Except for shift operations, if one operand is an untyped constant and the other
operand is not, the constant is implicitly converted to the type of the other
operand.

The right operand in a shift expression must have integer type [Go 1.13] or be
an untyped constant representable by a value of type uint. If the left operand
of a non-constant shift expression is an untyped constant, it is first
implicitly converted to the type it would assume if the shift expression were
replaced by its left operand alone.
```

The "breaklength" can be configured by passing `--breaklength <int>`. For example,
to break at 120 characters use `--breaklength 120`.

If there are existing newlines, they will be preserved.
