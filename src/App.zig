const std = @import("std");

const log = std.log;
const Allocator = std.mem.Allocator;

const Terminal = @import("App/Terminal.zig");
const Signal = @import("lib").types.Signal;
const input = @import("App/input.zig");
const UIHandler = @import("App/UIHandler.zig");

const files = @import("App/files.zig");

const Buffer = @import("lib").types.Buffer;

const App = @This();

terminal: Terminal,
ui_handler: UIHandler,
alloc: Allocator,

pub fn init(alloc: Allocator, path: ?[]const u8) !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();
    const window_dimensions = Terminal.getWindowSize();

    const buffer = if (path) |p|
        try files.importFileData(alloc, p)
    else
        Buffer.init(alloc);

    const ui_handler = try UIHandler.init(
        alloc,
        window_dimensions,
        buffer,
    );

    return App{
        .terminal = terminal,
        .ui_handler = ui_handler,
        .alloc = alloc,
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
