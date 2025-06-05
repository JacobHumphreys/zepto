const std = @import("std");

const log = std.log;
const File = std.fs.File;
const Allocator = std.mem.Allocator;

const Terminal = @import("App/Terminal.zig");
pub const Signal = @import("App/signals.zig").Signal;
const input = @import("App/input.zig");
const Outputter = @import("App/Outputter.zig");

const App = @This();

terminal: Terminal,
outputter: Outputter,

pub fn init(alloc: Allocator) !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();
    const outputter = try Outputter.init(alloc);

    return App{
        .terminal = terminal,
        .outputter = outputter,
    };
}

pub fn run(self: *App) Signal!void {
    var input_buffer: [8]u8 = undefined;
    const event = input.getInputEvent(&input_buffer) catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    self.outputter.processEvent(event) catch |err| switch (err) {
        Signal.Exit => return Signal.Exit,
        else => {
            log.err("{any}", .{err});
            return Signal.Exit;
        },
    };
}

pub fn deinit(self: *App) !void {
    self.outputter.deinit();
    try self.terminal.disableRawMode();
}
