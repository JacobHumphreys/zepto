const std = @import("std");
const log = std.log;
const File = std.fs.File;

const Terminal = @import("App/Terminal.zig");
pub const Signal = @import("App/signals.zig").Signal;
const input_reader = @import("App/input_reader.zig");
const output_reader = @import("App/output_renderer.zig");

const App = @This();

terminal: Terminal,

pub fn init() !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();
    return App{
        .terminal = terminal,
    };
}

pub fn run(self: *App) Signal!void {
    _ = self;
    const next_byte = input_reader.getNextInput() catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    if (next_byte == 'q') return Signal.Exit;

    output_reader.addCharToBuffer(next_byte) catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    output_reader.renderOutput() catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    return;
}

pub fn deinit(self: *App) !void {
    try self.terminal.disableRawMode();
}
