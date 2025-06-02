const std = @import("std");

const App = @import("App.zig");

const logging = @import("error_logging.zig");
pub const std_options: std.Options = .{
    .logFn = logging.myLogFn, // Use your custom log function
};

pub fn main() !void {
    try logging.init();
    var app = try App.init();
    while (true) {
        app.run() catch |err| switch (err) {
            App.Signal.Exit => break,
            else => return err,
        };
    }
    try app.deinit();
}
