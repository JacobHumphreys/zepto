const std = @import("std");
const fs = std.fs;
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
    const absolute_path = if (path[0] != '/') try localToAbsoultePath(alloc, path) else path;

    defer {
        if (!mem.eql(u8, path, absolute_path)) alloc.free(absolute_path);
    }

    const target = try fs.openFileAbsolute(absolute_path, .{ .mode = .read_only });

    const contents = try target.readToEndAlloc(alloc, MEGA);

    return Buffer{
        .alloc = alloc,
        .target_path = path,
        .data = .fromOwnedSlice(contents),
    };
}

pub fn localToAbsoultePath(
    alloc: Allocator,
    path: []const u8,
) (Allocator.Error || Error)![]const u8 {
    const f = fs.cwd().openFile(
        path,
        fs.File.OpenFlags{ .mode = .read_only },
    ) catch return Error.InvalidPath;
    f.close();

    var target_dir_path: []const u8 = "./";
    var target_file_name: []const u8 = path;
    if (std.mem.lastIndexOf(u8, path, "/")) |index| {
        target_dir_path = path[0..index];
        target_file_name = path[index..];
    }

    var target_dir = fs.cwd().openDir(target_dir_path, .{}) catch return Error.InvalidPath;
    defer target_dir.close();

    const target_dir_abs_path = target_dir.realpathAlloc(alloc, ".") catch
        return Error.PathAllocError;
    defer alloc.free(target_dir_abs_path);

    return std.mem.concat(alloc, u8, &.{ target_dir_abs_path, "/", target_file_name });
}

pub fn exportFileData(buffer: *Buffer, alloc: Allocator) !void {
    if (buffer.target_path == null) return Error.InvalidPath;

    const absolute_path = if (buffer.target_path.?[0] != '/') value: {
        break :value localToAbsoultePath(alloc, buffer.target_path.?) catch {
            const cwd_path = try fs.cwd().realpathAlloc(alloc, ".");
            defer alloc.free(cwd_path);
            break :value try fs.path.join(alloc, &.{ cwd_path, buffer.target_path.? });
        };
    } else buffer.target_path.?;

    defer {
        if (!mem.eql(u8, buffer.target_path.?, absolute_path)) {
            //because absolute_path can be either the buffer path or heap allocated, but not both
            alloc.free(absolute_path);
        }
    }

    const file = fs.createFileAbsolute(absolute_path, .{}) catch |err| {
        std.log.err("Invalid Path: {s}", .{absolute_path});
        return err;
    };
    defer file.close();

    var write_buffer: [1024]u8 = undefined;
    var file_writer = file.writer(&write_buffer);

    try file_writer.interface.writeAll(buffer.data.items);
    try file_writer.interface.flush();
}
