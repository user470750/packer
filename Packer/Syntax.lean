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

Reuses the syntax of Lean's `structure` command, with the keyword `packed` before `structure`:

```lean
/-- A time of day. -/
private packed structure Time where
  hours   : UInt8
  minutes : UInt8
  seconds : UInt8
```
-/
syntax
declModifiers "packed" Command.structure : command

end Packer
