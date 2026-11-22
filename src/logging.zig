const std = @import("std");
const debug = std.debug;
const Io = std.Io;
const File = Io.File;
const Dir = Io.Dir;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Environ = std.process.Environ;

const known_folders = @import("known-folders");

pub var log_file: ?Io.File = null;
pub var log_writer: ?Io.Writer = null;

pub fn init(alloc: Allocator, io: Io, env_map: *const std.process.Environ.Map) !void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const log_dir = try getLogDir(arena_alloc, io, env_map);

    const time_stamp = try getTimeStamp(arena_alloc, io);

    const log_name = try std.mem.join(arena_alloc, "", &.{ time_stamp, ".log" });

    log_file = try log_dir.createFile(io, log_name, .{});
}

fn getLogDir(
    alloc: Allocator,
    io: Io,
    env_map: *const std.process.Environ.Map,
) (known_folders.Error || Environ.CreateMapError || Dir.CreateDirError ||
    Dir.OpenError)!Io.Dir {
    const data_dir = try known_folders.getPath(
        io,
        alloc,
        env_map,
        known_folders.KnownFolder.data,
    ) orelse std.debug.panic("Terminal Error: Data folder path could not be determined.", .{});

    _ = Io.Dir.openDirAbsolute(io, data_dir, .{}) catch {
        try Io.Dir.createDirAbsolute(io, data_dir, .default_file);
    };

    const log_dir_path = try fs.path.join(alloc, &.{ data_dir, "zepto" });
    defer alloc.free(log_dir_path);

    const file_dir = Dir.openDirAbsolute(io, log_dir_path, .{}) catch {
        try Dir.createDirAbsolute(io, log_dir_path, .default_dir);
        return Dir.openDirAbsolute(io, log_dir_path, .{});
    };
    return file_dir;
}

fn getTimeStamp(alloc: Allocator, io: Io) Allocator.Error![]const u8 {
    var now = std.Io.Clock.real.now(io);
    var epoch = std.time.epoch.EpochSeconds{
        .secs = @intCast(now.toSeconds()),
    };

    const year_day = epoch.getEpochDay().calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch.getDaySeconds();

    return std.fmt.allocPrint(
        alloc,
        "{}-{}-{}-{}-{}-{}",
        .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
        },
    );
}

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.assert(log_file != null);

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
