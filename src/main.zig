const std = @import("std");
const debug = std.debug;

const App = @import("App.zig");
const Signal = @import("lib").types.Signal;
const build_zig_zon = @import("build_zig_zon");

const logging = @import("logging.zig");
pub const std_options: std.Options = .{
    .logFn = logging.log,
};

pub fn main() !void {
    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    defer debug.assert(debug_allocator.deinit() == .ok);
    const alloc = debug_allocator.allocator();

    var args = std.process.args();

    _ = args.skip();

    const path: ?[]const u8 = args.next();

    var app = App.init(alloc, .{ .buffer_name = path, .version = getVersion() }) catch |err| {
        std.log.err("App initializiation could not complete -> {t}", .{err});
        return err;
    };
    defer app.deinit() catch |err| {
        std.log.err("{any}", .{err});
    };

    const stdin_file = std.fs.File.stdin();
    defer stdin_file.close();

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = stdin_file.reader(&stdin_buffer);

    while (true) {
        app.run(alloc, &stdin_reader.interface) catch |err| switch (err) {
            Signal.Exit => break,
            else => return err,
        };
    }
}

fn getVersion() []const u8 {
    var line_iter = std.mem.splitSequence(u8, build_zig_zon.contents, "\n");
    while (line_iter.next()) |line| {
        if (std.mem.containsAtLeast(u8, line, 1, ".version")) {
            const start_index = std.mem.indexOf(u8, line, "\"") orelse return "";
            const end_index = std.mem.lastIndexOf(u8, line, "\"") orelse return "";
            return line[start_index + 1 .. end_index];
        }
    }
    return "";
}
