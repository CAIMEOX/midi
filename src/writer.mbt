///|
/// Writer state for building byte sequences
priv struct WriterState {
  data : Array[Byte]
}

///|
/// Create a new writer state
fn new_writer_state() -> WriterState {
  { data: Array::new() }
}

///|
/// Write a single byte
fn write_byte(state : WriterState, byte : Byte) -> Unit {
  state.data.push(byte)
}

///|
/// Write multiple bytes
fn write_bytes(state : WriterState, bytes : Array[Byte]) -> Unit {
  for byte in bytes {
    state.data.push(byte)
  }
}

///|
/// Write a 16-bit big-endian integer
fn write_uint16(state : WriterState, value : UInt16) -> Unit {
  write_byte(state, (value >> 8).to_byte())
  write_byte(state, value.to_byte())
}

///|
/// Write a 32-bit big-endian integer
fn write_uint32(state : WriterState, value : Int) -> Unit {
  write_byte(state, (value >> 24).to_byte())
  write_byte(state, (value >> 16).to_byte())
  write_byte(state, (value >> 8).to_byte())
  write_byte(state, value.to_byte())
}

///|
/// Write a variable-length integer (MIDI format)
fn write_variable_int(state : WriterState, value : UInt) -> Unit {
  let mut val = value
  let bytes = Array::new()

  // Extract 7-bit groups from right to left
  bytes.push((val & 0x7F).to_byte())
  val = val >> 7
  while val > 0 {
    bytes.push(((val & 0x7F) | 0x80).to_byte())
    val = val >> 7
  }

  // Write bytes in reverse order (big-endian)
  for i = bytes.length() - 1; i >= 0; i = i - 1 {
    write_byte(state, bytes[i])
  }
}

///|
/// Write a 4-byte chunk header (type + size)
fn write_chunk_header(
  state : WriterState,
  chunk_type : String,
  size : Int,
) -> Unit {
  // Write chunk type (4 ASCII characters)
  for char in chunk_type {
    write_byte(state, char.to_int().to_byte())
  }
  // Write size
  write_uint32(state, size)
}

///|
/// Serialize a MIDI event to bytes
fn  serialize_event(
  state : WriterState,
  event : Event,
  use_running_status : Bool,
  last_status : Byte,
) -> Byte {
  write_variable_int(state, event.delta())
  match event {
    NoteOff(channel~, note~, velocity~, ..) => {
      let status = 0x80 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      write_byte(state, note)
      write_byte(state, velocity)
      status.to_byte()
    }
    NoteOn(channel~, note~, velocity~, ..) => {
      let status = 0x90 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      write_byte(state, note)
      write_byte(state, velocity)
      status.to_byte()
    }
    PolyTouch(channel~, note~, value~, ..) => {
      let status = 0xA0 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      write_byte(state, note)
      write_byte(state, value)
      status.to_byte()
    }
    ControlChange(channel~, controller~, value~, ..) => {
      let status = 0xB0 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      write_byte(state, controller)
      write_byte(state, value)
      status.to_byte()
    }
    ProgramChange(channel~, program~, ..) => {
      let status = 0xC0 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      write_byte(state, program)
      status.to_byte()
    }
    Aftertouch(channel~, value~, ..) => {
      let status = 0xD0 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      write_byte(state, value)
      status.to_byte()
    }
    PitchWheel(channel~, pitch~, ..) => {
      let status = 0xE0 | channel.to_int()
      if not(use_running_status) || status.to_byte() != last_status {
        write_byte(state, status.to_byte())
      }
      let adjusted_pitch = pitch + 8192
      write_byte(state, (adjusted_pitch & 0x7F).to_byte()) // LSB
      write_byte(state, ((adjusted_pitch >> 7) & 0x7F).to_byte()) // MSB
      status.to_byte()
    }
    Tempo(delta~, microseconds~) => {
      write_byte(state, b'\xFF')
      write_byte(state, b'\x51')
      write_byte(state, b'\x03')
      
      write_byte(state, ((microseconds >> 16) & 0xFF).to_byte())
      write_byte(state, ((microseconds >> 8) & 0xFF).to_byte())
      write_byte(state, (microseconds & 0xFF).to_byte())

      b'\xFF'
    }
    TimeSignature(delta~, numerator~, denominator~, clocks_per_beat~, thirty_seconds_per_quarter~) => {
      // TODO
      b'\xFF'
    }
    KeySignature(delta~, sf~, mi~) => {
      // TODO
      b'\xFF'
    }
    SysEx(data~, ..) => {
      write_byte(state, b'\xF0')
      write_variable_int(state, (data.length() + 1).reinterpret_as_uint()) // +1 for end byte
      write_bytes(state, data)
      write_byte(state, b'\xF7') // End of SysEx
      b'\xF0'
    }
    Clock(_) => {
      write_byte(state, b'\xF8')
      b'\xF8'
    }
    Start(_) => {
      write_byte(state, b'\xFA')
      b'\xFA'
    }
    Continue(_) => {
      write_byte(state, b'\xFB')
      b'\xFB'
    }
    Stop(_) => {
      write_byte(state, b'\xFC')
      b'\xFC'
    }
    ActiveSensing(_) => {
      write_byte(state, b'\xFE')
      b'\xFE'
    }
    Reset(_) => {
      write_byte(state, b'\xFF')
      b'\xFF'
    }
    Meta(meta_type~, data~, ..) => {
      write_byte(state, b'\xFF')
      write_byte(state, meta_type)
      write_variable_int(state, data.length().reinterpret_as_uint())
      write_bytes(state, data)
      b'\xFF'
    }
  }
}

///|
/// Helper function to get delta time from event
fn Event::delta(self : Event) -> UInt {
  match self {
    NoteOff(delta~, ..)
    | NoteOn(delta~, ..)
    | PolyTouch(delta~, ..)
    | ControlChange(delta~, ..)
    | ProgramChange(delta~, ..)
    | Aftertouch(delta~, ..)
    | PitchWheel(delta~, ..)
    | Tempo(delta~, ..)
    | TimeSignature(delta~, ..)
    | KeySignature(delta~, ..)
    | SysEx(delta~, ..)
    | Clock(delta~)
    | Start(delta~)
    | Continue(delta~)
    | Stop(delta~)
    | ActiveSensing(delta~)
    | Reset(delta~)
    | Meta(delta~, ..) => delta
  }
}

///|
/// Serialize a track to bytes
fn serialize_track(state : WriterState, track : Track) -> Unit {
  let track_state = new_writer_state()
  let mut last_status : Byte = 0x00

  // Serialize all events in the track
  for event in track.events {
    last_status = serialize_event(track_state, event, true, last_status)
  }

  // Write track header
  write_chunk_header(state, "MTrk", track_state.data.length())

  // Write track data
  write_bytes(state, track_state.data)
}

///|
/// Main MIDI file serializer
pub fn serialize(midi_file : MidiFile) -> Bytes {
  let state = new_writer_state()

  // Write header chunk
  write_chunk_header(state, "MThd", 6)
  write_uint16(state, midi_file.format)
  write_uint16(state, midi_file.tracks.length().to_uint16())
  write_uint16(state, midi_file.division)

  // Write all tracks
  for track in midi_file.tracks {
    serialize_track(state, track)
  }
  Bytes::from_array(state.data)
}
