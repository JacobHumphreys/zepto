const std = @import("std");
const ascii = std.ascii;
const control_code = ascii.control_code;
const File = std.fs.File;
const Io = std.Io;

const zepto = @import("zepto");
const input = zepto.input;
const ControlSequence = zepto.input.ControlSequence;
const InputEvent = zepto.input.InputEvent;

pub const Error = error {
    FetchingError,
};

/// Get next InputEvent struct representing user input
pub fn getInputEvent(reader: *Io.Reader) Error!InputEvent {
    var input_buffer: [8]u8 = undefined;
    const next_input = getNextInput(reader, &input_buffer) catch return Error.FetchingError;

    return parseEvent(next_input);
}

pub fn parseEvent(user_input: []u8) InputEvent {
    if (user_input.len == 1) {
        return inputEventFromChar(user_input[0]);
    }

    return InputEvent{ .control = ControlSequence.from(user_input) };
}

fn inputEventFromChar(char: u8) InputEvent {
    return switch (char) {
        input.getControlCombination('c') => InputEvent{ .control = .ctrl_c },
        input.getControlCombination('g') => InputEvent{ .control = .ctrl_g },
        input.getControlCombination('j') => InputEvent{ .control = .ctrl_j },
        input.getControlCombination('k') => InputEvent{ .control = .ctrl_k },
        input.getControlCombination('o') => InputEvent{ .control = .ctrl_o },
        input.getControlCombination('r') => InputEvent{ .control = .ctrl_r },
        input.getControlCombination('t') => InputEvent{ .control = .ctrl_t },
        input.getControlCombination('u') => InputEvent{ .control = .ctrl_u },
        input.getControlCombination('v') => InputEvent{ .control = .ctrl_v },
        input.getControlCombination('w') => InputEvent{ .control = .ctrl_w },
        input.getControlCombination('x') => InputEvent{ .control = .ctrl_x },
        input.getControlCombination('y') => InputEvent{ .control = .ctrl_y },
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

///Used to get next string of characters or characters read from stdin
pub fn getNextInput(reader: *Io.Reader, read_buffer: []u8) Io.Reader.ShortError![]u8 {
    const input_len = try reader.readSliceShort(read_buffer);
    return read_buffer[0..input_len];
}
