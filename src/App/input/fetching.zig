const std = @import("std");
const File = std.fs.File;
const io = std.io;
const Reader = std.fs.File.Reader;

const std_in: File = std.io.getStdIn();
const std_in_reader: Reader = std_in.reader();

pub fn getNextInput() Reader.NoEofError!u8 {
    return std_in_reader.readByte();
}
