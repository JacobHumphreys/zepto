const std = @import("std");

const App = @import("App.zig");
const Signal = @import("lib").types.Signal;

const logging = @import("logging.zig");
pub const std_options: std.Options = .{
    .logFn = logging.log,
};

pub fn main() !void {
    try logging.init();
    var app = try App.init(std.heap.page_allocator);
    while (true) {
        app.run() catch |err| switch (err) {
            Signal.Exit => break,
            else => return err,
        };
    }
    defer app.deinit() catch |err| {
        std.log.err("{any}", .{err});
    };
}
