# MIDI

A lightweight Standard MIDI File (SMF) parser and writer for the MoonBit language.

## Features

- Parse `MThd` / `MTrk` chunks into strongly-typed structures (`MidiFile`, `Track`, `Event`)
- Support for channel voice messages, meta events, SysEx, and common realtime messages
- Proper handling of variable-length quantities & running status (both parse & serialize)
- Serialize in‑memory structures back to a valid `.mid` byte stream
- Human‑readable printing (all core types implement `Show`)

Status: work in progress (API surface may change). Contributions welcome.

## Installation

```bash
moon add CAIMEOX/midi
```

## Data Model

```text
MidiFile { format: UInt16, division: UInt16, tracks: Array[Track] }
Track    { events: Array[Event] }
Event =>
  NoteOn(delta, channel, note, velocity)
| NoteOff(delta, channel, note, velocity)
| ControlChange(delta, channel, controller, value)
| ProgramChange(delta, channel, program)
| Aftertouch(delta, channel, value)
| PolyTouch(delta, channel, note, value)
| PitchWheel(delta, channel, pitch)          // signed 14-bit centered at 0
| Tempo(delta~ : UInt, microseconds~ : UInt)  // 0x51, in microseconds
| TimeSignature(delta~ : UInt, numerator~ : Byte, denominator~ : Byte, clocks_per_beat~ : Byte, thirty_seconds_per_quarter~ : Byte)  // 0x58, denominator is log(2)D
| KeySignature(delta~ : UInt, sf~ : Byte, mi~ : Byte)  // 0x59, sharp/flat and major/minor
| Meta(delta, meta_type, data[])             // raw meta payload
| SysEx(delta, data[])                       // payload (without trailing F7)
| Clock | Start | Continue | Stop | ActiveSensing | Reset
```

## Parsing

```moonbit
pub fn parse(bytes: Bytes) -> MidiFile raise ParseError
```

Guarantees / checks:

- Validates header chunk tag & size (`MThd`, size 6)
- Reads declared number of tracks
- Enforces track byte length boundaries
- Handles running status (channel messages may omit repeated status byte)

### Possible Errors (`ParseError`)

- `InvalidHeader`
- `InvalidTrack`
- `UnexpectedEOF`
- `UnknownEventType`
- `InvalidData(String)`

## Serialization

```moonbit
pub fn serialize(file: MidiFile) -> Bytes
```

Behavior:

- Emits canonical header (`MThd`, size 6)
- Encodes delta times as variable-length quantities
- Reuses running status for size optimization
- Restores 14-bit pitch wheel (adds 8192 offset internally)
- Writes SysEx with starting `F0`, length, payload, terminating `F7`

## Quick Usage Examples

### Parse & Inspect

```moonbit
fn demo(bytes: Bytes) raise @midi.ParseError {
  let mf = @midi.parse(bytes)
  println(mf.to_string()) // Uses Show impl to pretty print
}
```

## Roadmap Ideas

<!-- - Helper constructors & decoders for tempo (0x51), time signature (0x58), key signature (0x59) -->
- Tick-to-time utilities
- Event builder DSL
- Track manipulation helpers (merge, filter, quantize)
- Event iteration utilities (by type, by channel, by time range)

## Contributing

PRs & issues welcome. Please include tests for parsing / serialization changes.

## License

Apache-2.0 © CAIMEOX
Apache-2.0 © Elevonic611