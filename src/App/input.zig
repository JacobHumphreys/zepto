const std = @import("std");
const ascii = std.ascii;
const control_code = ascii.control_code;
const File = std.fs.File;
const Io = std.Io;

const lib = @import("lib");
const ControlSequence = lib.types.input.ControlSequence;
const InputEvent = lib.types.input.InputEvent;

pub const Error = error{
    FetchingError,
};

/// Get next InputEvent struct representing user input
pub fn getInputEvent(reader: *Io.Reader) Error!InputEvent {
    var input_buffer: [8]u8 = undefined;
    const input = getNextInput(reader, &input_buffer) catch return Error.FetchingError;

    return parseEvent(input);
}

pub fn parseEvent(input: []u8) InputEvent {
    if (input.len == 1) {
        return inputEventFromChar(input[0]);
    }

    return InputEvent{ .control = ControlSequence.from(input) };
}

fn inputEventFromChar(char: u8) InputEvent {
    return switch (char) {
        getControlCombination('c') => InputEvent{ .control = .ctrl_c },
        getControlCombination('g') => InputEvent{ .control = .ctrl_g },
        getControlCombination('j') => InputEvent{ .control = .ctrl_j },
        getControlCombination('k') => InputEvent{ .control = .ctrl_k },
        getControlCombination('o') => InputEvent{ .control = .ctrl_o },
        getControlCombination('r') => InputEvent{ .control = .ctrl_r },
        getControlCombination('t') => InputEvent{ .control = .ctrl_t },
        getControlCombination('u') => InputEvent{ .control = .ctrl_u },
        getControlCombination('v') => InputEvent{ .control = .ctrl_v },
        getControlCombination('w') => InputEvent{ .control = .ctrl_w },
        getControlCombination('x') => InputEvent{ .control = .ctrl_x },
        getControlCombination('y') => InputEvent{ .control = .ctrl_y },
        control_code.cr => InputEvent{ .control = ControlSequence.new_line },
        control_code.del => InputEvent{ .control = .backspace },
        control_code.ht => InputEvent{ .control = .tab },
        else => {
            if (ascii.isPrint(char))
                return InputEvent{ .input = char }
            else
                return InputEvent{ .control = .unknown };
        },
    };
}

///Returns character equivilent to user input of ctrl+char
fn getControlCombination(char: u8) u8 {
    return char & control_code.us;
}

///Used to get next string of characters or characters read from stdin
pub fn getNextInput(reader: *Io.Reader, read_buffer: []u8) Io.Reader.ShortError![]u8 {
    const input_len = try reader.readSliceShort(read_buffer);
    return read_buffer[0..input_len];
}
