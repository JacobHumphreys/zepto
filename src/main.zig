const std = @import("std");
const App = @import("App.zig");

pub fn main() !void {
    var app = try App.init();
    while (true) {
        app.run() catch |err| switch (err) {
            App.Signal.Exit => break,
            else => return err,
        };
    }
    try app.deinit();
}
