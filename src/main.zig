const std = @import("std");
const debug = std.debug;

const App = @import("App.zig");
const Signal = @import("zepto").Signal;
const build_zig_zon = @import("build_zig_zon");

const logging = @import("logging.zig");
pub const std_options: std.Options = .{
    .logFn = logging.log,
};

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    const io = init.io;
    try logging.init(alloc, io, init.environ_map);

    var args = init.minimal.args.iterate();

    _ = args.skip();

    const path: ?[]const u8 = args.next();

    var app = App.init(init.gpa, init.io, .{ .buffer_name = path, .version = getVersion() }) catch |err| {
        std.log.err("App initializiation could not complete -> {t}", .{err});
        return err;
    };
    defer app.deinit() catch |err| {
        std.log.err("{any}", .{err});
    };

    const stdin_file = std.Io.File.stdin();
    defer stdin_file.close(init.io);

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = stdin_file.reader(init.io, &stdin_buffer);

    while (true) {
        app.run(alloc, io, &stdin_reader.interface) catch |err| switch (err) {
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
