const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const File = std.fs.File;
const io = std.io;
const Reader = std.fs.File.Reader;

const std_in: File = std.io.getStdIn();
const std_in_reader: Reader = std_in.reader();

pub fn getNextInput(buffer: []u8) Reader.NoEofError![]u8 {
    const input_len = try std_in_reader.read(buffer);
    return buffer[0..input_len];
}

fn isRegularInput(input: u8) bool {
    if (std.ascii.isPrint(input)) return true;
    if (input == '\n' or input == '\r') return true;
    return false;
}
