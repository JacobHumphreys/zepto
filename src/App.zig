const std = @import("std");
const log = std.log;
const File = std.fs.File;

const Terminal = @import("App/Terminal.zig");
pub const Signal = @import("App/signals.zig").Signal;
const app_input = @import("App/input.zig");
const app_output = @import("App/output.zig");

const App = @This();

terminal: Terminal,
output_renderer: app_output.Renderer,

pub fn init() !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();

    return App{
        .terminal = terminal,
        .output_renderer = app_output.Renderer.init(),
    };
}

pub fn run(self: *App) Signal!void {
    const next_byte = app_input.fetching.getNextInput() catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    if (next_byte == 'q') {
        return Signal.Exit;
    }

    self.output_renderer.addCharToBuffer(next_byte) catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    self.output_renderer.updateOutput() catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    return;
}

pub fn deinit(self: *App) !void {
    self.output_renderer.deinit();
    try self.terminal.disableRawMode();
}
