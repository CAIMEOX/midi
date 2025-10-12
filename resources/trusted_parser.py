import mido
from mido import MidiFile, MidiTrack, Message, MetaMessage
import os
import sys

def read_midi_file(filename):
    """
    Read and parse a MIDI file from disk.
    
    Args:
        filename (str): Path to the MIDI file
    
    Returns:
        MidiFile: Parsed MIDI file object
        list: List of all messages from all tracks
    """
    try:
        original_stdout = sys.stdout
        # Load the MIDI file using mido
        midi_file = MidiFile(filename)
        
        messages = []
        
        # print(f"MIDI File Information:")
        # print(f"  Type: {midi_file.type}")
        # print(f"  Ticks per beat: {midi_file.ticks_per_beat}")
        # print(f"  Length: {midi_file.length} seconds")
        # print(f"  Number of tracks: {len(midi_file.tracks)}")
        # print()
        
        with open('from_py.txt', 'w') as f:
            sys.stdout = f
            # Extract all messages from all tracks
            for i, track in enumerate(midi_file.tracks):
                # print(f"Track {i} ({len(track)} messages):")
                for msg in track:
                    messages.append(msg)
                    print(f"{msg}")
                if i < len(midi_file.tracks) - 1:
                    print("------")

        sys.stdout = original_stdout

        return midi_file, messages
        
    except Exception as e:
        print(f"Error reading MIDI file: {e}")
        return None, []

def parse_midi_bytes(byte_list):
    """
    Properly parse MIDI bytes considering the file structure with headers and chunks.
    
    Args:
        byte_list (list): List of bytes representing MIDI data
    
    Returns:
        list: List of parsed MIDI messages
    """
    # Convert to bytes and create a file-like object
    midi_bytes = bytes(byte_list)
    
    # Create a temporary file to use with mido's parser
    temp_filename = 'temp_midi_file.mid'
    try:
        with open(temp_filename, 'wb') as f:
            f.write(midi_bytes)
        
        # Use mido to parse the temporary file
        midi_file = MidiFile(temp_filename)
        messages = []
        
        print(f"Parsed MIDI from bytes:")
        print(f"  Type: {midi_file.type}")
        print(f"  Ticks per beat: {midi_file.ticks_per_beat}")
        print(f"  Number of tracks: {len(midi_file.tracks)}")
        print()
        
        # Extract all messages from all tracks
        for i, track in enumerate(midi_file.tracks):
            print(f"Track {i} ({len(track)} messages):")
            for msg in track:
                messages.append(msg)
                print(f"  {msg}")
            print()
        
        return messages
        
    except Exception as e:
        print(f"Error parsing MIDI bytes: {e}")
        return []
    finally:
        # Clean up temporary file
        if os.path.exists(temp_filename):
            os.remove(temp_filename)

def parse_midi_bytes_direct(byte_list):
    """
    Parse MIDI bytes directly without saving to file.
    This uses mido's parser which handles the MIDI structure correctly.
    
    Args:
        byte_list (list): List of bytes representing MIDI data
    
    Returns:
        list: List of parsed MIDI messages
    """
    midi_bytes = bytes(byte_list)
    
    # Create a parser instance
    parser = mido.Parser()
    
    # Feed all bytes to the parser
    parser.feed(midi_bytes)
    
    # Get all parsed messages
    messages = []
    while True:
        try:
            msg = parser.get_message()
            if msg is None:
                break
            messages.append(msg)
            print(f"Parsed: {msg}")
        except Exception as e:
            print(f"Error during parsing: {e}")
            break
    
    return messages

def analyze_midi_file(midi_file):
    """
    Analyze a MIDI file and extract useful information.
    
    Args:
        midi_file (MidiFile): Parsed MIDI file object
    """
    print("=== MIDI File Analysis ===")
    print(f"File type: {midi_file.type}")
    print(f"Ticks per beat: {midi_file.ticks_per_beat}")
    print(f"Duration: {midi_file.length:.2f} seconds")
    print(f"Number of tracks: {len(midi_file.tracks)}")
    print()
    
    for track_idx, track in enumerate(midi_file.tracks):
        print(f"Track {track_idx}:")
        note_count = 0
        program_changes = 0
        control_changes = 0
        
        for msg in track:
            if msg.type == 'note_on' and msg.velocity > 0:
                note_count += 1
            elif msg.type == 'program_change':
                program_changes += 1
            elif msg.type == 'control_change':
                control_changes += 1
        
        print(f"  Messages: {len(track)}")
        print(f"  Notes: {note_count}")
        print(f"  Program changes: {program_changes}")
        print(f"  Control changes: {control_changes}")
        print()

# Example usage
if __name__ == "__main__":
    # Example 1: Read MIDI file from disk
    filename = "star_wars.mid"  # Replace with your MIDI file path
    if os.path.exists(filename):
        midi_file, messages = read_midi_file(filename)
        if midi_file:
            analyze_midi_file(midi_file)
    else:
        print(f"File {filename} not found. Please provide a valid MIDI file.")
    
    print("MIDI file reading completed.")