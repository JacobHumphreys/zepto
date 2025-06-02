const std = @import("std");
const fs = std.fs;
const mem = std.mem;

pub const Error = error{
    GetConfigDirError,
    GetAppDataDirError,
};

pub fn getConfigDir(alloc: mem.Allocator) Error![]const u8 {
    const data_dir = try getDataDir(alloc);
    const home_index = mem.indexOf(u8, data_dir, "/.local");
    if (home_index == null) return Error.GetConfigDirError;

    return fs.path.join(alloc, &.{ data_dir[0..home_index], ".config", "zepto" }) catch {
        return Error.GetConfigDirError;
    };
}

pub fn getDataDir(alloc: mem.Allocator) Error![]u8 {
    return fs.getAppDataDir(alloc, "zepto");
}
