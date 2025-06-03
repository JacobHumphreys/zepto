const std = @import("std");
const log = std.log;
const File = std.fs.File;
const Allocator = std.mem.Allocator;

const Terminal = @import("App/Terminal.zig");
pub const Signal = @import("App/signals.zig").Signal;
const input = @import("App/input.zig");
const output = @import("App/output.zig");

const App = @This();

terminal: Terminal,
text_window: output.TextWindow,

pub fn init(alloc: Allocator) !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();
    try output.rendering.clearScreen();
    const text_window = output.TextWindow.init(alloc);

    return App{
        .terminal = terminal,
        .text_window = text_window,
    };
}

pub fn run(self: *App) Signal!void {
    const event = input.getInputEvent() catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };
    switch (event) {
        .input => |char| {
            if (char == 'q') {
                return Signal.Exit;
            }

            self.text_window.addCharToBuffer(char) catch |err| {
                log.err("{any}", .{err});
                return Signal.Exit;
            };

            output.rendering.updateOutput(self.text_window) catch |err| {
                log.err("{any}", .{err});
                return Signal.Exit;
            };
        },
        else => unreachable,
    }

    return;
}

pub fn deinit(self: *App) !void {
    self.text_window.deinit();
    try self.terminal.disableRawMode();
}
