const std = @import("std");
const ascii = std.ascii;
const control_code = ascii.control_code;
const File = std.fs.File;
const io = std.io;
const Reader = std.fs.File.Reader;

const lib = @import("lib");
const ControlSequence = lib.types.input.ControlSequence;
const InputEvent = lib.types.input.InputEvent;

pub const Error = error{
    FetchingError,
};

const std_in: File = std.io.getStdIn();
const std_in_reader: Reader = std_in.reader();

/// Get next InputEvent struct representing user input
pub fn getInputEvent(buffer: []u8) Error!InputEvent {
    const input = getNextInput(buffer) catch {
        return Error.FetchingError;
    };

    return parseEvent(input);
}

pub fn parseEvent(input: []u8) InputEvent {
    if (input.len == 1) {
        switch (input[0]) {
            getControlCombination('x') => {
                return InputEvent{ .control = ControlSequence.exit };
            },
            control_code.cr, control_code.lf => {
                return InputEvent{ .control = ControlSequence.new_line };
            },
            control_code.del => {
                return InputEvent{ .control = .backspace };
            },
            else => {
                if (ascii.isPrint(input[0]))
                    return InputEvent{ .input = input[0] }
                else
                    return InputEvent{ .control = .unknown };
            },
        }
    }

    return InputEvent{ .control = ControlSequence.from(input) };
}

///Returns character equivilent to user input of ctrl+char
fn getControlCombination(char: u8) u8 {
    return char & control_code.us;
}

///Used to get next string of characters or characters read from stdin
pub fn getNextInput(buffer: []u8) Reader.NoEofError![]u8 {
    const input_len = try std_in_reader.read(buffer);
    return buffer[0..input_len];
}
