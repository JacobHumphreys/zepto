const std = @import("std");
const ascii = std.ascii;
const File = std.fs.File;
const io = std.io;
const Reader = std.fs.File.Reader;

const std_in: File = std.io.getStdIn();
const std_in_reader: Reader = std_in.reader();

pub const InputType = union(enum) {
    character: u8,
    sequence: []u8,
};

pub fn getNextInput() Reader.NoEofError!InputType {
    const input = try std_in_reader.readByte();

    if (isRegularInput(input)) {
        return InputType{ .character = input };
    }

    if (std.ascii.isControl(input)) {
        std.log.debug("control input recieved: {c}", .{input});
    }

    return InputType{ .sequence = "" };
}

fn isRegularInput(input: u8) bool {
    if (std.ascii.isPrint(input)) return true;
    if (std.ascii.isWhitespace(input)) return true;
    return false;
}

const ControlKey = enum([]u8) {
    up = "^[[A",
    down = "^[[B",
    left = "^[[D",
    right = "^[[C",
};
