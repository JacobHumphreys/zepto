const std = @import("std");
const fs = std.fs;

pub const Error = error{
    GetConfigDirError,
    GetAppDataDirError,
};

pub fn getConfigDir(alloc: std.mem.Allocator) Error![]const u8 {
    const data_dir = try getDataDir(alloc);
    const home_index = std.mem.indexOf(u8, data_dir, "/.local");
    if (home_index == null) return Error.GetConfigDirError;

    return std.fs.path.join(alloc, &.{ data_dir[0..home_index], ".config", "zepto" }) catch {
        return Error.GetConfigDirError;
    };
}

pub fn getDataDir(alloc: std.mem.Allocator) Error!void {
    return fs.getAppDataDir(alloc, "zepto");
}

pub fn openFile(path: []const u8) !void {
    _ = path;
    std.debug.print("TODO", .{});
    unreachable;
}

pub fn outputBufferDataToFile(path: []const u8, data: [][]u8) !void {
    _ = path;
    _ = data;
    std.debug.print("TODO", .{});
    unreachable;
}
