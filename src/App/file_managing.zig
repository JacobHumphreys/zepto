const std = @import("std");
const fs = std.fs;
pub fn getConfigDir() !void {

}
pub fn getDataDir(alloc: std.mem.Allocator) !void {
    const data_dir = fs.getAppDataDir(alloc, "zepto");

}
