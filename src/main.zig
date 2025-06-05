const std = @import("std");

const App = @import("App.zig");

const logging = @import("error_logging.zig");
pub const std_options: std.Options = .{
    .logFn = logging.log,
};

pub fn main() !void {
    try logging.init();
    var app = try App.init(std.heap.page_allocator);
    while (true) {
        app.run() catch |err| switch (err) {
            App.Signal.Exit => break,
            else => return err,
        };
    }
    defer app.deinit() catch |err|{
        std.log.err("{any}", .{err});
    };
}
