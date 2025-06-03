const std = @import("std");
const ascii = std.ascii;
const File = std.fs.File;
const io = std.io;
const Reader = std.fs.File.Reader;

const std_in: File = std.io.getStdIn();
const std_in_reader: Reader = std_in.reader();

pub fn getNextInput() Reader.NoEofError!u8 {
    const input = try std_in_reader.readByte();
    if (std.ascii.isAlphabetic(input) or input == '\n') {
        return input;
    }

    if (std.ascii.isControl(input)) {
        std.log.debug("control input recieved: {c}", .{input});
    } 
    return 0;
}

const ControlKeys = enum([]u8) {
    up = "^[[A",
    down = "^[[B",
    left = "^[[D",
    right = "^[[C",
};
