///|
/// Parser state for tracking position in byte stream
priv struct ParserState {
  mut pos : Int
  data : Bytes
  mut running_status : Int // for MIDI running status
}

///|
/// Parse errors
pub suberror ParseError {
  InvalidHeader
  InvalidTrack
  UnexpectedEOF
  UnknownEventType
  InvalidData(String)
}

///|
/// Create a new parser state
fn new_parser_state(data : Bytes) -> ParserState {
  { pos: 0, data, running_status: -1 }
}

///|
/// Read a single byte from the parser state
fn read_byte(state : ParserState) -> Byte raise ParseError {
  if state.pos >= state.data.length() {
    raise UnexpectedEOF
  }
  let byte = state.data[state.pos]
  state.pos += 1
  byte
}

///|
/// Read multiple bytes from the parser state
fn read_bytes(state : ParserState, count : Int) -> Array[Byte] raise ParseError {
  if state.pos + count > state.data.length() {
    raise UnexpectedEOF
  }
  let bytes = Array::new(capacity=count)
  for i = 0; i < count; i = i + 1 {
    bytes.push(state.data[state.pos + i])
  }
  state.pos += count
  bytes
}

///|
/// Read a 16-bit big-endian integer
fn read_uint16(state : ParserState) -> UInt16 raise ParseError {
  let bytes = read_bytes(state, 2)
  (bytes[0].to_int().to_uint16() << 8) | bytes[1].to_int().to_uint16()
}

///|
/// Read a 32-bit big-endian integer
fn read_uint32(state : ParserState) -> Int raise ParseError {
  let bytes = read_bytes(state, 4)
  (bytes[0].to_int() << 24) |
  (bytes[1].to_int() << 16) |
  (bytes[2].to_int() << 8) |
  bytes[3].to_int()
}

///|
/// Read a variable-length integer (MIDI format)
fn read_variable_int(state : ParserState) -> UInt raise ParseError {
  let mut value : UInt = 0
  while true {
    let byte = read_byte(state).to_int()
    value = (value << 7) | (byte & 0x7F).reinterpret_as_uint()
    if byte < 0x80 {
      break value
    }
  } else {
    value
  }
}

///|
/// Read a 4-byte chunk header (type + size)
fn read_chunk_header(state : ParserState) -> (String, Int) raise ParseError {
  let type_bytes = read_bytes(state, 4)
  let size = read_uint32(state)
  let type_str = String::from_array(
    type_bytes.map(fn(b) { b.to_int().to_char().unwrap() }),
  )
  (type_str, size)
}

///|
/// Parse MIDI file header
fn parse_header(
  state : ParserState,
) -> (UInt16, UInt16, UInt16) raise ParseError {
  let (chunk_type, chunk_size) = read_chunk_header(state)
  if chunk_type != "MThd" {
    raise InvalidHeader
  }
  if chunk_size != 6 {
    raise InvalidHeader
  }
  let format = read_uint16(state)
  let num_tracks = read_uint16(state)
  let division = read_uint16(state)
  (format, num_tracks, division)
}

///|
/// Parse a single MIDI event
fn parse_event(state : ParserState) -> Event raise ParseError {
  let delta = read_variable_int(state)
  let mut status_byte = read_byte(state).to_int()

  // Handle running status
  if status_byte < 0x80 {
    if state.running_status == -1 {
      raise InvalidData("Running status without previous status")
    }
    // Put the byte back and use running status
    state.pos -= 1
    status_byte = state.running_status
    // Update running status (except for system messages)
  } else if status_byte < 0xF0 {
    state.running_status = status_byte
  }
  let channel = status_byte & 0x0F
  let message_type = status_byte & 0xF0
  match message_type {
    0x80 => {
      // Note Off
      let note = read_byte(state)
      let velocity = read_byte(state)
      NoteOff(delta~, channel=channel.to_byte(), note~, velocity~)
    }
    0x90 => {
      // Note On
      let note = read_byte(state)
      let velocity = read_byte(state)
      NoteOn(delta~, channel=channel.to_byte(), note~, velocity~)
    }
    0xA0 => {
      // Polyphonic Aftertouch
      let note = read_byte(state)
      let value = read_byte(state)
      PolyTouch(delta~, channel=channel.to_byte(), note~, value~)
    }
    0xB0 => {
      // Control Change
      let controller = read_byte(state)
      let value = read_byte(state)
      ControlChange(delta~, channel=channel.to_byte(), controller~, value~)
    }
    0xC0 => {
      // Program Change
      let program = read_byte(state)
      ProgramChange(delta~, channel=channel.to_byte(), program~)
    }
    0xD0 => {
      // Channel Aftertouch
      let value = read_byte(state)
      Aftertouch(delta~, channel=channel.to_byte(), value~)
    }
    0xE0 => {
      // Pitch Wheel
      let lsb = read_byte(state).to_int()
      let msb = read_byte(state).to_int()
      let pitch = (msb << 7) | (lsb - 8192) // Convert to signed 14-bit
      PitchWheel(delta~, channel=channel.to_byte(), pitch~)
    }
    0xF0 =>
      // System messages
      match status_byte {
        0xF0 => {
          // System Exclusive
          let length = read_variable_int(state)
          let data = read_bytes(state, length.reinterpret_as_int())
          // Remove end byte if present
          let clean_data = if data.length() > 0 &&
            data[data.length() - 1] == 0xF7 {
            data[0:data.length() - 1]
          } else {
            data
          }
          SysEx(delta~, data=clean_data.to_array())
        }
        0xF8 => Clock(delta~)
        0xFA => Start(delta~)
        0xFB => Continue(delta~)
        0xFC => Stop(delta~)
        0xFE => ActiveSensing(delta~)
        0xFF => {
          // Meta Event
          let meta_type = read_byte(state)
          let length = read_variable_int(state)
          let data = read_bytes(state, length.reinterpret_as_int())
          Meta(delta~, meta_type~, data~)
        }
        _ => raise UnknownEventType
      }
    _ => raise UnknownEventType
  }
}

///|
/// Parse a single track
fn parse_track(state : ParserState) -> Track raise ParseError {
  let (chunk_type, chunk_size) = read_chunk_header(state)
  if chunk_type != "MTrk" {
    raise InvalidTrack
  }
  let track_start = state.pos
  let track_end = track_start + chunk_size
  let events = Array::new()

  // Reset running status for each track
  state.running_status = -1
  while state.pos < track_end {
    let event = parse_event(state)
    events.push(event)
  }
  if state.pos != track_end {
    raise InvalidTrack
  }
  { events, }
}

///|
/// Main MIDI file parser
pub fn parse(bytes : Bytes) -> MidiFile raise ParseError {
  let state = new_parser_state(bytes)

  // Parse header
  let (format, num_tracks, division) = parse_header(state)

  // Parse tracks
  let tracks = Array::new()
  for i = 0; i < num_tracks.to_int(); i = i + 1 {
    let track = parse_track(state)
    tracks.push(track)
  }
  { format, division, tracks }
}