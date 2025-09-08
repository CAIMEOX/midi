///|
/// MIDI File structure
pub(all) struct MidiFile {
  format : UInt16
  division : UInt16
  tracks : Array[Track]
} 

pub impl Show for MidiFile with to_string(self) -> String {
  let track_strs = self.tracks.map(fn(t) { t.to_string() })
  let tracks_info = track_strs.join("\n------\n")
  "format=\{self.format}\ndivision=\{self.division}\ntracks:\{self.tracks.length()}\n\{tracks_info}"
}

pub impl Show for MidiFile with output(self, logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
/// Track containing MIDI events
pub(all) struct Track {
  events : Array[Event]
}

///|
impl Show for Track with to_string(self) -> String {
  let event_strs = self.events.map(fn(e) { e.to_string() })
  event_strs.join("\n")
}

///|
impl Show for Track with output(self, logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
/// MIDI Event types
pub(all) enum Event {
  NoteOn(delta~ : UInt, channel~ : Byte, note~ : Byte, velocity~ : Byte)
  NoteOff(delta~ : UInt, channel~ : Byte, note~ : Byte, velocity~ : Byte)
  ControlChange(
    delta~ : UInt,
    channel~ : Byte,
    controller~ : Byte,
    value~ : Byte
  )
  ProgramChange(delta~ : UInt, channel~ : Byte, program~ : Byte)
  Aftertouch(delta~ : UInt, channel~ : Byte, value~ : Byte)
  PolyTouch(delta~ : UInt, channel~ : Byte, note~ : Byte, value~ : Byte)
  PitchWheel(delta~ : UInt, channel~ : Byte, pitch~ : Int)
  Tempo(delta~ : UInt, microseconds~ : UInt)  // 0x51
  TimeSignature(delta~ : UInt, numerator~ : Byte, denominator~ : Byte, clocks_per_click~ : Byte, thirty_seconds_per_quarter~ : Byte)  // 0x58
  KeySignature(delta~ : UInt, sf~ : Byte, mi~ : Byte)  // 0x59
  Meta(delta~ : UInt, meta_type~ : Byte, data~ : Array[Byte])
  SysEx(delta~ : UInt, data~ : Array[Byte])
  Clock(delta~ : UInt)
  Start(delta~ : UInt)
  Continue(delta~ : UInt)
  Stop(delta~ : UInt)
  ActiveSensing(delta~ : UInt)
  Reset(delta~ : UInt)
}

///|
impl Show for Event with to_string(self) -> String {
  match self {
    NoteOn(delta~, channel~, note~, velocity~) =>
      "NoteOn[\{delta}][ch \{channel.to_int()}] note=\{note.to_int()}(\{note_to_pitch(note)}) vel=\{velocity.to_int()}"
    NoteOff(delta~, channel~, note~, velocity~) =>
      "NoteOff[\{delta}][ch \{channel.to_int()}] note=\{note.to_int()}(\{note_to_pitch(note)}) vel=\{velocity.to_int()}"
    ControlChange(delta~, channel~, controller~, value~) =>
      "ControlChange[\{delta}][ch \{channel.to_int()}] ctrl=\{controller.to_int()} val=\{value.to_int()}"
    ProgramChange(delta~, channel~, program~) =>
      "ProgramChange[\{delta}][ch \{channel.to_int()}] program=\{program.to_int()}: \{program_to_instrument(program)}"
    Aftertouch(delta~, channel~, value~) =>
      "Aftertouch[\{delta}][ch \{channel.to_int()}] value=\{value.to_int()}"
    PolyTouch(delta~, channel~, note~, value~) =>
      "PolyTouch[\{delta}][ch \{channel.to_int()}] note=\{note.to_int()} value=\{value.to_int()}"
    PitchWheel(delta~, channel~, pitch~) =>
      "PitchWheel[\{delta}][ch \{channel.to_int()}] pitch=\{pitch}"
    Tempo(delta~, microseconds~) =>
      "Tempo[\{delta}] microseconds=\{microseconds}"
    TimeSignature(delta~, numerator~, denominator~, clocks_per_click~, thirty_seconds_per_quarter~) =>
      "TimeSignature[\{delta}] numerator=\{numerator} denominator=\{denominator} clocks_per_tick=\{clocks_per_click} thirty_seconds_per_quarter=\{thirty_seconds_per_quarter}"
    KeySignature(delta~, sf~, mi~) =>
      "KeySignature[\{delta}] sf=\{sf} mi=\{mi}"
    Meta(delta~, meta_type~, data~) => {
      let bytes_str = data.map(fn(b) { b.to_int().to_string() }).join(" ")
      "Meta[\{delta}] type=\{meta_type.to_int()} len=\{data.length()} [\{bytes_str}]"
    }
    SysEx(delta~, data~) => {
      let bytes_str = data.map(fn(b) { b.to_int().to_string() }).join(" ")
      "SysEx[\{delta}] len=\{data.length()} [\{bytes_str}]"
    }
    Clock(delta~) => "Clock[\{delta}]"
    Start(delta~) => "Start[\{delta}]"
    Continue(delta~) => "Continue[\{delta}]"
    Stop(delta~) => "Stop[\{delta}]"
    ActiveSensing(delta~) => "ActiveSensing[\{delta}]"
    Reset(delta~) => "Reset[\{delta}]"
  }
}

///|
impl Show for Event with output(self, logger) -> Unit {
  logger.write_string(self.to_string())
}

