module

public meta import Lean
public meta import Packer.Internal.Codegen

public section

/-!
# Syntax

Declares the syntax that marks a structure as packed, and its elaborator.
-/

namespace Packer

open Lean Lean.Parser Lean.Elab Lean.Elab.Command Internal

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

/--
Checks the names of the fields: they must be atomic, distinct, and must not clash with `bits` and
`pack`, which are generated next to the getters.
-/
private meta def checkNames (typeName : Ident) (names : Array Ident) : CommandElabM Unit := do
  let mut seen : NameSet := {}
  for name in names do
    let id := name.getId
    unless id.isAtomic do
      throwErrorAt name "field name `{id}` must be atomic"
    if seen.contains id then
      throwErrorAt name "duplicate field name `{id}`"
    if id == `bits || id == `pack then
      throwErrorAt name "field name `{id}` clashes with the generated `{typeName.getId ++ id}`"
    seen := seen.insert id

/--
Checks that the fields fit into a `UInt64`: their widths must add up to at most `64`.
-/
private meta def checkWidth (widths : Array NumLit) : CommandElabM Unit := do
  let total := widths.foldl (· + ·.getNat) 0
  if total > 64 then
    throwError "the widths of the fields add up to {total}, more than the 64 bits of a `UInt64`"

/--
Collects the parts of the fields, matched as separate arrays, into `SourceField`s.
-/
private meta def getFields (docs : Array (Option (TSyntax ``Parser.Command.docComment)))
    (names : Array Ident) (types : Array Term) (widths : Array NumLit) :
    Array SourceField :=
  let rawFields := docs.zip (names.zip (types.zip widths))
  rawFields.map fun (doc?, name, type, width) => ⟨doc?, name, type, width⟩

elab_rules : command
  | `(
      $modifiers:declModifiers
      packed_structure $typeName where
        $[$[$docs]? $names : $types with $widths]*
    ) => do
    checkNames typeName names
    checkWidth widths
    let fields := getFields docs names types widths
    for cmd in ← build ⟨modifiers, typeName, fields⟩ do
      elabCommand cmd
      -- The later declarations refer to the earlier ones, so once one of them fails the rest only
      -- add noise.
      if ← MonadLog.hasErrors then
        throwAbortCommand

end Packer
