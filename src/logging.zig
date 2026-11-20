const std = @import("std");
const debug = std.debug;
const Io = std.Io;
const File = Io.File;
const Dir = Io.Dir;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Environ = std.process.Environ;

const c = @import("c");
const known_folders = @import("known-folders");

pub var log_file: ?Io.File = null;
pub var log_writer: ?Io.Writer = null;

fn init() !Io.File {
    var path_buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&path_buffer);
    const alloc = fba.allocator();
    var threaded_io = std.Io.Threaded.init(alloc, .{});
    const io = threaded_io.io();

    const env = std.process.Environ{
        .block = .empty,
    };

    const log_dir = try getLogDir(alloc, io, env);
    const time_stamp = try getTimeStamp(alloc);
    const log_name = try std.mem.join(alloc, "", &.{ time_stamp, ".log" });

    return log_dir.createFile(io, log_name, .{});
}

fn getLogDir(
    alloc: Allocator,
    io: Io,
    env: std.process.Environ,
) (known_folders.Error || Environ.CreateMapError || Dir.CreateDirError ||
    Dir.OpenError)!Io.Dir {
    var map = try env.createMap(alloc);
    defer map.deinit();

    const data_dir = try known_folders.getPath(
        io,
        alloc,
        &map,
        known_folders.KnownFolder.data,
    ) orelse std.debug.panic("Terminal Error: Data folder path could not be determined.", .{});

    _ = Io.Dir.openDirAbsolute(io, data_dir, .{}) catch {
        try Io.Dir.createDirAbsolute(io, data_dir, .default_file);
    };

    const log_dir_path = try fs.path.join(alloc, &.{ data_dir, "logs" });

    const file_dir = Dir.openDirAbsolute(io, log_dir_path, .{}) catch {
        try Dir.createDirAbsolute(io, log_dir_path, .default_dir);
        return Dir.openDirAbsolute(io, log_dir_path, .{});
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
    log_file = log_file orelse init() catch |err| debug.panic("{t}", .{err});

    var alloc_buf: [1028]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&alloc_buf);
    const alloc = fba.allocator();

    var threaded_io = std.Io.Threaded.init(alloc, .{});
    defer threaded_io.deinit();
    const io = threaded_io.io();

    var buff: [1024]u8 = undefined;
    var writer = log_file.?.writer(io, &buff);

    writer.interface.print("[{t}] {s}: ", .{ level, @tagName(scope) }) catch |err|
        debug.panic("{t}", .{err});

    writer.interface.print(format, args) catch |err| debug.panic("{t}", .{err});

    writer.interface.writeAll("\n") catch |err| debug.panic("{t}", .{err});
    writer.interface.flush() catch |err| debug.panic("{t}", .{err});
}
