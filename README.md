# packer

A Lean 4 library for structures whose fields are packed into a single `UInt64`, so that their
values are not allocated on the heap.

## Usage

The `packed_structure` command declares a structure whose fields are packed into a `UInt64`. Each
field is declared as `name : type with width`, where `width` is the number of bits it takes in the
`UInt64`, and can have a docstring. The type of a field must have a `Packer.Packable` instance. The
declaration supports modifiers, such as a docstring or `private`:

```lean
import Packer

/-- A time of day. -/
packed_structure Time where
  /-- The hours. -/
  hours   : UInt8 with 5
  /-- The minutes. -/
  minutes : UInt8 with 6
  /-- The seconds. -/
  seconds : UInt8 with 6

def time := Time.pack 13 45 30

#eval (time.hours, time.minutes, time.seconds)
-- (13, 45, 30)
```

The constructor `Time.pack` takes the values of the fields together with proofs that they fit into
their bits; for literals, `decide` finds the proofs. Each field gets a getter, such as `Time.hours`.
