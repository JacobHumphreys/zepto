const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const Buffer = lib.types.Buffer;

const Error = error{
    FileNotFound,
    PathAllocError,
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
    ) catch return Error.FileNotFound;
    f.close();

    var target_dir_path: []const u8 = "./";
    var target_file_name: []const u8 = path;
    if (std.mem.lastIndexOf(u8, path, "/")) |index| {
        target_dir_path = path[0..index];
        target_file_name = path[index..];
    } 

    var target_dir = fs.cwd().openDir(target_dir_path, .{}) catch return Error.FileNotFound;
    defer target_dir.close();

    const target_dir_abs_path = target_dir.realpathAlloc(alloc, ".") catch
        return Error.PathAllocError;
    defer alloc.free(target_dir_abs_path);

    return std.mem.concat(alloc, u8, &.{ target_dir_abs_path, "/", target_file_name });
}

pub fn exportFileData(buffer: Buffer, alloc: Allocator) !void {
    std.debug.assert(buffer.target_path != null);

    const absolute_path = if (buffer.target_path.?[0] != '/')
        try localToAbsoultePath(alloc, buffer.target_path.?)
    else
        buffer.target_path.?;

    defer {
        if (!mem.eql(u8, buffer.target_path.?, absolute_path)) alloc.free(absolute_path);
    }

    const file = try fs.createFileAbsolute(buffer.target_path.?, .{});
    defer file.close();
    const file_writer = file.writer();
    return file_writer.writeAll(buffer.data.items);
}
