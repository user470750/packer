module

public section

/-!
# Packable types

Defines the class of field types whose values can be packed into the bits of a `UInt64`, and its
instances.
-/

namespace Packer

/--
A type whose values can be packed into the bits of a `UInt64` and unpacked back.
-/
class Packable (α : Type) where
  /--
  Packs a value into the bits of a `UInt64`.
  -/
  toUInt64 : α → UInt64
  /--
  Unpacks a value from the bits of a `UInt64` produced by `toUInt64`.
  -/
  ofUInt64 : UInt64 → α

instance : Packable UInt64 where
  toUInt64 := id
  ofUInt64 := id

instance : Packable UInt32 where
  toUInt64 := UInt32.toUInt64
  ofUInt64 := UInt64.toUInt32

instance : Packable UInt16 where
  toUInt64 := UInt16.toUInt64
  ofUInt64 := UInt64.toUInt16

instance : Packable UInt8 where
  toUInt64 := UInt8.toUInt64
  ofUInt64 := UInt64.toUInt8

instance : Packable Nat where
  toUInt64 := Nat.toUInt64
  ofUInt64 := UInt64.toNat

instance : Packable Char where
  toUInt64 c := c.toUInt8.toUInt64
  ofUInt64 c := Char.ofUInt8 c.toUInt8

instance : Packable Bool where
  toUInt64 := Bool.toUInt64
  ofUInt64 : UInt64 → Bool
    | 0 => false
    | 1 => true
    | _ => panic! "a packed `Bool` must be 0 or 1"

end Packer
