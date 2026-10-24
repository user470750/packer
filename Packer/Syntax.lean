module

public meta import Lean
public meta import Packer.Internal.Codegen

public section

/-!
# Syntax

Declares the syntax that marks a structure as packed, and its elaborator.
-/

namespace Packer

open Lean Lean.Parser

/--
Declares a structure whose fields are packed into a `UInt64`, and therefore is not allocated on the
heap.

Each field is declared as `name : type with width`, where `width` is the number of bits it takes in
the `UInt64`, and can have a docstring. The declaration supports modifiers, such as a docstring or
`private`:

```lean
/-- A time of day. -/
private packed_structure Time where
  hours   : UInt8 with 8
  minutes : UInt8 with 8
  seconds : UInt8 with 8
```
-/
syntax
declModifiers
"packed_structure" ident "where"
  manyIndent((docComment)? ident ":" term "with" num) : command

end Packer
