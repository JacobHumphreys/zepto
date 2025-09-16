const std = @import("std");
const Writer = std.Io.Writer;
const fs = std.fs;
const File = fs.File;
const Dir = fs.Dir;
const mem = std.mem;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const Buffer = lib.types.Buffer;

const Error = error{
    PathAllocError,
    InvalidPath,
};

const MEGA = 1_000_000;

/// Returns an owned slice representing user data
pub fn importFileData(alloc: Allocator, path: []const u8) !Buffer {
    var buffer = Buffer{
        .alloc = alloc,
        .target_path = path,
    };

    const absolute_path = if (path[0] != '/')
        localToAbsoultePath(alloc, path) catch |err| switch (err) {
            Allocator.Error.OutOfMemory => |e| return e,
            else => return buffer,
        }
    else
        path;

    defer {
        if (!mem.eql(u8, path, absolute_path)) alloc.free(absolute_path);
    }

    const target_file: ?File = fs.openFileAbsolute(absolute_path, .{ .mode = .read_only }) catch |err| switch (err) {
        File.OpenError.FileNotFound => null,
        else => return err,
    };

    const contents = if (target_file) |f|
        try f.readToEndAlloc(alloc, MEGA)
    else
        null;

    if (contents) |c| buffer.data = .fromOwnedSlice(c);

    return buffer;
}

fn localToAbsoultePath(
    alloc: Allocator,
    path: []const u8,
) (Allocator.Error || Dir.RealPathAllocError)![]const u8 {
    var dir_path: []const u8 = "./";
    var file_name: []const u8 = path;

    if (std.mem.lastIndexOf(u8, path, "/")) |index| {
        dir_path = path[0..index];
        file_name = path[index..];
    }

    const cwd_path = try fs.cwd().realpathAlloc(alloc, ".");
    defer alloc.free(cwd_path);

    return mem.concat(alloc, u8, &.{ cwd_path, "/", dir_path, file_name });
}

fn openOrCreateDir(dir_path: []const u8) (Dir.OpenError || Dir.MakeError)!std.fs.Dir {
    return fs.cwd().openDir(dir_path, .{}) catch {
        try fs.cwd().makeDir(dir_path);
        return try fs.cwd().openDir(dir_path, .{});
    };
}

pub fn exportFileData(buffer: *Buffer, alloc: Allocator) (Writer.Error || Allocator.Error || Error)!void {
    if (buffer.target_path == null) return Error.InvalidPath;

    var absolute_path: []const u8 = undefined;

    if (buffer.target_path.?[0] != '/') {
        absolute_path = localToAbsoultePath(alloc, buffer.target_path.?) catch |err| {
            std.log.err("{t}", .{err});
            std.log.err("path: {s}", .{absolute_path});
            return Error.InvalidPath;
        };
    } else {
        absolute_path = buffer.target_path.?;
    }

    defer {
        if (!mem.eql(u8, buffer.target_path.?, absolute_path)) {
            //because absolute_path can be either the buffer path or heap allocated, but not both
            alloc.free(absolute_path);
        }
    }

    const file = fs.createFileAbsolute(absolute_path, .{ .exclusive = false }) catch |err| {
        std.log.err("{t}", .{err});
        std.log.err("path: {s}", .{absolute_path});
        return Error.InvalidPath;
    };
    //return Error.InvalidPath;
    defer file.close();

    var write_buffer: [1024]u8 = undefined;
    var file_writer = file.writer(&write_buffer);

    try file_writer.interface.writeAll(buffer.data.items);
    try file_writer.interface.flush();
}

test "import file data" {
    const alloc = std.testing.allocator;
    var buffer = try importFileData(alloc, ".gitignore");
    defer buffer.deinit();

    try std.testing.expect(buffer.data.items.len > 0);
    try std.testing.expectEqual(0, std.mem.indexOf(u8, buffer.data.items, ".zig-cache"));
}
