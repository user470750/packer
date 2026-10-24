module

import Packer

/-!
# A test that packs a `Time`

Tests packing and unpacking a time of day, whose fields have different widths.
-/

/-- A time of day. -/
packed_structure Time where
  /-- The hours. -/
  hours   : UInt8 with 5
  /-- The minutes. -/
  minutes : UInt8 with 6
  /-- The seconds. -/
  seconds : UInt8 with 6

#guard
  let time := Time.pack 13 45 30
  (time.hours, time.minutes, time.seconds) = (13, 45, 30)

-- The largest values set all the bits of their fields: if the fields overlapped, reading them back
-- would give other values.
#guard
  let time := Time.pack 31 63 63
  (time.hours, time.minutes, time.seconds) = (31, 63, 63)
