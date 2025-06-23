const std = @import("std");

const log = std.log;
const File = std.fs.File;
const Allocator = std.mem.Allocator;

const Terminal = @import("App/Terminal.zig");
const Signal = @import("lib").types.Signal;
const input = @import("App/input.zig");
const UIHandler = @import("App/UIHandler.zig");

const App = @This();

terminal: Terminal,
ui_handler: UIHandler,

pub fn init(alloc: Allocator) !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();
    const window_dimensions = Terminal.getWindowSize();
    const ui_handler = try UIHandler.init(alloc, window_dimensions);

    return App{
        .terminal = terminal,
        .ui_handler = ui_handler,
    };
}

pub fn run(self: *App) Signal!void {
    self.ui_handler.setOutputDimensions(Terminal.getWindowSize());

    var input_buffer: [8]u8 = undefined;
    const event = input.getInputEvent(&input_buffer) catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    self.ui_handler.processEvent(event) catch |err| switch (err) {
        Signal.Exit => return Signal.Exit,
        else => {
            log.err("{any}", .{err});
            return Signal.Exit;
        },
    };
}

pub fn deinit(self: *App) !void {
    self.ui_handler.deinit();
    try self.terminal.disableRawMode();
}
