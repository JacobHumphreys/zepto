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

const std_in: File = std.fs.File.stdin();
var std_in_buff: [1024]u8 = undefined;
var std_in_reader = std_in.reader(&std_in_buff);

/// Get next InputEvent struct representing user input
pub fn getInputEvent(read_buffer: []u8) Error!InputEvent {
    const input = getNextInput(read_buffer) catch {
        return Error.FetchingError;
    };

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
pub fn getNextInput(read_buffer: []u8) Io.Reader.Error![]u8 {
    const input_len = std_in_reader.read(read_buffer) catch |err| switch (err) {
        Io.Reader.Error.EndOfStream => return read_buffer[0..1],
        else => return err,
    };
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

    var writer_buff: [1024]u8 = undefined;
    var std_in_writer = tmp_in_file.writer(&writer_buff);

    var read_buff: [8]u8 = undefined;

    _ = try std_in_writer.interface.writeByte('a');
    try tmp_in_file.seekTo(0);

    const expected = InputEvent{ .input = 'a' };
    const real = try getInputEvent(&read_buff);
    try std.testing.expect(real == .input);
    try std.testing.expectEqual(expected.input, real.input);
}
