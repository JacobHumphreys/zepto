const std = @import("std");
const File = std.fs.File;

const std_err = std.fs.createFileAbsolute("", );

pub fn log(err: anyerror) !void {
    _ = err;
//    std.log.err(comptime format: []const u8, args: anytype);
}
