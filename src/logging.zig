const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("time.h");
});

pub var log_file: ?fs.File = null;
var log_file_buff: [1024]u8 = undefined;
var writer: ?std.Io.Writer = null;

fn init() !void {
    var path_buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&path_buffer);
    const alloc = fba.allocator();

    const log_dir = try getLogDir(alloc);
    const time_stamp = try getTimeStamp(alloc);
    const log_name = try std.mem.join(alloc, "", &.{ time_stamp, ".log" });

    log_file = try log_dir.createFile(log_name, .{});
    writer = log_file.?.writer(&log_file_buff).interface;
}

fn getLogDir(alloc: Allocator) !fs.Dir {
    const data_dir = try fs.getAppDataDir(alloc, "zepto");
    _ = fs.openDirAbsolute(data_dir, .{}) catch {
        try fs.makeDirAbsolute(data_dir);
    };

    const log_dir_path = try fs.path.join(alloc, &.{ data_dir, "logs" });

    const file_dir = fs.openDirAbsolute(log_dir_path, .{}) catch {
        try fs.makeDirAbsolute(log_dir_path);
        return fs.openDirAbsolute(log_dir_path, .{});
    };
    return file_dir;
}

fn getTimeStamp(alloc: Allocator) ![]const u8 {
    var now: c.time_t = undefined;
    _ = c.time(&now);
    const time_info = c.localtime(&now);
    const date = c.asctime(time_info);
    const time_stamp = try std.fmt.allocPrint(alloc, "{s}", .{date});
    return time_stamp[0 .. time_stamp.len - 1]; //remove trailing newLine
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = log_file orelse value: {
        init() catch |err| @panic(@errorName(err));
        break :value log_file.?;
    };
    // Format and write the log message
    _ = writer.?.print("[{s}] {s}: ", .{ @tagName(level), @tagName(scope) }) catch |err| @panic(@errorName(err));
    _ = writer.?.print(format, args) catch |err| @panic(@errorName(err));
    writer.?.flush() catch |err| @panic(@errorName(err));
    _ = writer.?.writeAll("\n") catch |err| @panic(@errorName(err));
}
