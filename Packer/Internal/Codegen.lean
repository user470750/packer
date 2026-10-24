module

import Lean
import Packer.Packable

public section

/-!
# Code generation

Generates, for a structure, its packed structure and the functions to work with it.
-/

namespace Packer.Internal

open Lean

/--
A field of a `packed_structure` declaration, as written in the source: its docstring, name, type
and width in bits.
-/
structure SourceField where
  /--
  The docstring of the field, if any.
  -/
  doc? : Option (TSyntax ``Parser.Command.docComment)
  /--
  The name of the field.
  -/
  name : Ident
  /--
  The type of the field, which must have a `Packer.Packable` instance.
  -/
  type : Term
  /--
  The width of the field in bits: its values must fit into `width` bits when packed.
  -/
  width : NumLit

/--
A `packed_structure` declaration, as written in the source: its modifiers, name and fields.
-/
structure SourceStructure where
  /--
  The modifiers of the declaration, such as its docstring and visibility.
  -/
  modifiers : TSyntax ``Parser.Command.declModifiers
  /--
  The name of the declaration.
  -/
  name : Ident
  /--
  The fields of the declaration, each written as `name : type with width`. They are packed in
  declaration order, starting from the lowest bits.
  -/
  fields : Array SourceField

variable [Monad m] [MonadQuotation m]

/--
Builds a structure with the field `bits`, into which the values of the fields of the
`packed_structure` declaration are packed. The generated structure uses the name and the modifiers
of the declaration. It is not allocated on the heap, since it has a single field of type `UInt64`.
-/
def buildStruct (name : Ident) (modifiers : TSyntax ``Parser.Command.declModifiers) :
    m Command :=
  `(
    $modifiers:declModifiers structure $name where
      bits : UInt64
  )

/--
Builds the constructor for the structure generated from the `packed_structure` declaration. The
generated constructor takes the values of the fields together with proofs that they fit into their
bits, and packs the values into the field `bits : UInt64` in the order of the arguments.
-/
def buildConstructor (name : Ident) (fields : Array SourceField) : m Command := do
  let args ← fields.mapM fun ⟨_, argName, argType, argWidth⟩ =>
    `(bracketedBinder|
      ($argName : {n : $argType // (Packer.Packable.toUInt64 n).toNat < 2 ^ $argWidth}))
  let mut offset := 0
  let mut returnValue ← `((0 : UInt64))
  for ⟨_, argName, _, argWidth⟩ in fields do
    returnValue ← `(
      $returnValue ||| (Packer.Packable.toUInt64 ($argName).val <<< $(quote offset))
    )
    offset := offset + argWidth.getNat
  `(
    /--
    Takes the values of the fields together with proofs that they fit into their bits, and packs
    the values into the field `bits : UInt64` in the order of the arguments.
    -/
    @[inline]
    def $(mkIdent (name.getId.str "pack")) $[$args]* : $name :=
      ⟨$returnValue⟩
  )

/--
Builds getters for the fields of the `packed_structure` declaration: each one extracts the packed
value of its field from `bits : UInt64` in the generated structure with a shift and a bit mask, and
returns it converted to the type of the field. Each getter takes the docstring of its field, if any.
-/
def buildGetters (name : Ident) (fields : Array SourceField) : m (Array Command) := do
  let mut offset := 0
  let mut getters := #[]
  for ⟨doc?, argName, argType, argWidth⟩ in fields do
    getters := getters.push (← `(
      $[$doc?:docComment]?
      @[inline]
      def $(mkIdent (name.getId ++ argName.getId)) (packed : $name) : $argType :=
        Packer.Packable.ofUInt64
          ((packed.bits >>> $(quote offset)) &&& $(quote ((1 <<< argWidth.getNat) - 1)))
    ))
    offset := offset + argWidth.getNat
  return getters

/--
Builds the code of a `packed_structure` declaration:

* the generated structure;
* its constructor;
* the getters for the fields of the declaration.
-/
def build (struct : SourceStructure) : m (Array Command) := do
  return #[
    ← buildStruct struct.name struct.modifiers,
    ← buildConstructor struct.name struct.fields
  ] ++ (← buildGetters struct.name struct.fields)

end Packer.Internal
