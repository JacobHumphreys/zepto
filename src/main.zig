const std = @import("std");
const assert = std.debug.assert;

const App = @import("App.zig");
const Signal = @import("lib").types.Signal;

const logging = @import("logging.zig");
pub const std_options: std.Options = .{
    .logFn = logging.log,
};

pub fn main() !void {
    try logging.init();

    var debug_allocator = std.heap.DebugAllocator(.{}).init;
    defer std.debug.assert(debug_allocator.deinit() == .ok);
    const alloc = debug_allocator.allocator();

    var app = try App.init(alloc);
    defer app.deinit() catch |err| {
        std.log.err("{any}", .{err});
    };

    while (true) {
        app.run() catch |err| switch (err) {
            Signal.Exit => break,
            else => return err,
        };
    }
}
