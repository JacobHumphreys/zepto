const std = @import("std");
const File = std.fs.File;
const io = std.io;
const Reader = std.fs.File.Reader;

const std_in: File = std.io.getStdIn();
const std_in_reader: Reader = std_in.reader();

pub fn getNextInput() !u8 {
    const byte = try std_in_reader.readByte();
    std.log.debug("\n{}\n", .{byte});
    return byte;
}
