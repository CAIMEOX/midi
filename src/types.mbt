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
      "NoteOn[\{delta}][ch \{channel.to_int()}] note=\{note.to_int()} vel=\{velocity.to_int()}"
    NoteOff(delta~, channel~, note~, velocity~) =>
      "NoteOff[\{delta}][ch \{channel.to_int()}] note=\{note.to_int()} vel=\{velocity.to_int()}"
    ControlChange(delta~, channel~, controller~, value~) =>
      "ControlChange[\{delta}][ch \{channel.to_int()}] ctrl=\{controller.to_int()} val=\{value.to_int()}"
    ProgramChange(delta~, channel~, program~) =>
      "ProgramChange[\{delta}][ch \{channel.to_int()}] program=\{program.to_int()}"
    Aftertouch(delta~, channel~, value~) =>
      "Aftertouch[\{delta}][ch \{channel.to_int()}] value=\{value.to_int()}"
    PolyTouch(delta~, channel~, note~, value~) =>
      "PolyTouch[\{delta}][ch \{channel.to_int()}] note=\{note.to_int()} value=\{value.to_int()}"
    PitchWheel(delta~, channel~, pitch~) =>
      "PitchWheel[\{delta}][ch \{channel.to_int()}] pitch=\{pitch}"
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

