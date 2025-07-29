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
var std_in_reader: Reader = std_in.reader();

/// Get next InputEvent struct representing user input
pub fn getInputEvent(read_buffer: []u8) Error!InputEvent {
    const input = getNextInput(read_buffer) catch {
        return Error.FetchingError;
    };

    return parseEvent(input);
}

pub fn parseEvent(input: []u8) InputEvent {
    if (input.len == 1) {
        switch (input[0]) {
            getControlCombination('t') => {
                return InputEvent{ .control = ControlSequence.ctrl_t };
            },
            getControlCombination('g') => {
                return InputEvent{ .control = ControlSequence.ctrl_g };
            },
            getControlCombination('x') => {
                return InputEvent{ .control = ControlSequence.ctrl_x };
            },
            getControlCombination('c') => {
                return InputEvent{ .control = ControlSequence.ctrl_c };
            },
            control_code.cr,
            => {
                return InputEvent{ .control = ControlSequence.new_line };
            },
            control_code.del => {
                return InputEvent{ .control = .backspace };
            },
            else => |char| {
                if (ascii.isPrint(char))
                    return InputEvent{ .input = char }
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
pub fn getNextInput(read_buffer: []u8) Reader.NoEofError![]u8 {
    const input_len = try std_in_reader.read(read_buffer);
    return read_buffer[0..input_len];
}

test "input event" {
    var tmp_in_file = value: {
        break :value std.fs.openFileAbsolute("/tmp/zepto_tmp_in", .{}) catch {
            break :value try std.fs.createFileAbsolute("/tmp/zepto_tmp_in", .{
                .read = true,
                .exclusive = false,
                .truncate = false,
            });
        };
    };

    defer {
        tmp_in_file.close();
        _ = std.fs.deleteFileAbsolute("/tmp/zepto_tmp_in") catch {
            std.debug.print("Failed to delete zepto_tmp_in", .{});
        };
    }

    std_in_reader = tmp_in_file.reader();
    var std_in_writer = tmp_in_file.writer();
    defer std_in_reader = std_in.reader();

    var read_buff: [8]u8 = undefined;

    _ = try std_in_writer.writeByte('a');
    try tmp_in_file.seekTo(0);

    const expected = InputEvent{ .input = 'a' };
    const real = try getInputEvent(&read_buff);
    try std.testing.expect(real == .input);
    try std.testing.expectEqual(expected.input, real.input);
}
