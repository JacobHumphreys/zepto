const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("time.h");
});

var log_file: ?fs.File = null;

pub fn init() !void {
    var path_buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&path_buffer);
    const alloc = fba.allocator();

    const log_dir = try getLogDir(alloc);
    const timeStamp = try getTimeStamp(alloc);
    const log_name = try std.mem.join(alloc, "", &.{ timeStamp, ".log" });

    log_file = try log_dir.createFile(log_name, fs.File.CreateFlags{});
}

fn getLogDir(alloc: Allocator) !fs.Dir {
    const data_dir = try fs.getAppDataDir(alloc, "zepto");
    _ = fs.openDirAbsolute(data_dir, .{}) catch {
        try fs.makeDirAbsolute(data_dir);
    };

    const log_dir_path = try fs.path.join(alloc, &.{ data_dir, "logs" });

    const fileDir = fs.openDirAbsolute(log_dir_path, .{}) catch {
        try fs.makeDirAbsolute(log_dir_path);
        return fs.openDirAbsolute(log_dir_path, .{});
    };
    return fileDir;
}

fn getTimeStamp(alloc: Allocator) ![]const u8 {
    var now: c.time_t = undefined;
    _ = c.time(&now);
    const timeInfo = c.localtime(&now);
    const date = c.asctime(timeInfo);
    const timeStamp = try std.fmt.allocPrintZ(alloc, "{s}", .{date});
    return timeStamp[0 .. timeStamp.len - 1]; //remove trailing newLine
}

pub fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const lf = log_file orelse return;
    const writer = lf.writer();

    // Format and write the log message
    _ = writer.print("[{s}] {s}: ", .{ @tagName(level), @tagName(scope) }) catch return;
    _ = writer.print(format, args) catch return;
    _ = writer.writeAll("\n") catch return;
}
