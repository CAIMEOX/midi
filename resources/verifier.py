import trusted_parser
import re

def to_mido_format(mbt_parsed_text):
    """
    Convert MBT parsed text to Mido-compatible format with all regex transformations.
    
    Args:
        mbt_parsed_text (str): The parsed text from MBT format
        
    Returns:
        str: Mido-compatible formatted text
    """
    lines = mbt_parsed_text.split('\n')
    processed_lines = []
    
    for line in lines:
        if not line.strip():
            processed_lines.append(line)
            continue
            
        # Apply all transformations in sequence
        transformed_line = line
        
        # 1. Replace fixed texts to meet mido format
        transformed_line = re.sub(r'NoteOn', 'note_on', transformed_line)
        transformed_line = re.sub(r'NoteOff', 'note_off', transformed_line)
        transformed_line = re.sub(r'SysEx', 'sysex', transformed_line)
        transformed_line = re.sub(r'ProgramChange', 'program_change', transformed_line)
        transformed_line = re.sub(r'ControlChange', 'control_change', transformed_line)
        transformed_line = re.sub(r'SysEx', 'sysex', transformed_line)

        transformed_line = re.sub(r'ctrl', 'control', transformed_line)
        transformed_line = re.sub(r'vel', 'velocity', transformed_line)
        transformed_line = re.sub(r'val', 'value', transformed_line)


        
        # 2. Replace [ch X] with channel=X
        transformed_line = re.sub(r'\[ch (\d+)\]', r' channel=\1 ', transformed_line)
        
        # 3. Remove (XX) from note=XX(XX) patterns
        transformed_line = re.sub(r'note=(\d+)\([^)]+\)', r'note=\1', transformed_line)
        
        # 4. Move time=XX to the end of the line
        time_match = re.search(r'\[(\d+)\]', transformed_line)
        if time_match:
            time_value = f"time={time_match.group(1)}"
            # Remove the time bracket
            transformed_line = re.sub(r'\[\d+\]', '', transformed_line)
            # Add time to the end
            transformed_line = transformed_line.strip() + ' ' + time_value

        # 5. Remove instrument description
        transformed_line = re.sub(r'(program=\d+):.*?(?=time=|$)', r'\1 ', transformed_line)

        # 6. Convert SysEx format to Mido-compatible format
        if transformed_line.startswith('sysex'):
            # Remove 'len=XX' part
            transformed_line = re.sub(r'len=\d+', '', transformed_line)
            # Convert hex array to tuple format
            transformed_line = re.sub(r'\[([0-9A-Fa-f ]+)\]', 
                                    lambda m: f"data=({','.join(m.group(1).split())})", 
                                    transformed_line)
            # Convert to lowercase
            transformed_line = transformed_line.lower()
            # Clean up any extra spaces
            transformed_line = re.sub(r'\s+', ' ', transformed_line).strip()
        
        # 7. Clean up any extra spaces
        transformed_line = re.sub(r'\s+', ' ', transformed_line).strip()
        
        processed_lines.append(transformed_line)
    
    return '\n'.join(processed_lines)

def compare(from_py, from_mbt):
    # Split both strings into lines
    py_lines = from_py.splitlines()
    mbt_lines = from_mbt.splitlines()
    
    # Find the maximum number of lines to compare
    max_lines = max(len(py_lines), len(mbt_lines))
    
    differences_found = False
    
    for i in range(max_lines):
        # Get lines from both sources (or empty string if line doesn't exist)
        py_line = py_lines[i] if i < len(py_lines) else ""
        mbt_line = mbt_lines[i] if i < len(mbt_lines) else ""
        
        # Strip and normalize whitespace for comparison
        py_stripped = ' '.join(py_line.split())
        mbt_stripped = ' '.join(mbt_line.split())
        
        # Compare the normalized lines
        if py_stripped.startswith("Meta"):
            continue
        if py_stripped != mbt_stripped:
            differences_found = True
            print(f"Difference at line {i + 1}:")
            print(f"  Python: {py_line}")
            print(f"  MBT:    {mbt_line}")
            print(f"  Normalized Python: '{py_stripped}'")
            print(f"  Normalized MBT:    '{mbt_stripped}'")
            print("-" * 50)
    
    if not differences_found:
        print("No differences found! Files are identical (ignoring excessive spaces).")



def ref_test(mbt_parsed_text, file_name):
    from_py = ""
    from_mbt = to_mido_format(mbt_parsed_text)
    trusted_parser.read_midi_file(file_name)
    with open('from_py.txt', 'r') as f:
        from_py = f.read()

    compare(from_py, from_mbt)


# print("Trusted version: ")
# midi_file, messages = trusted_parser.read_midi_file("star_wars.mid")


with open("moon_test_expected.txt", "r") as file:
    mbt_parsed_test = file.read()

ref_test(mbt_parsed_test, "star_wars.mid")
