const std = @import("std");

const log = std.log;
const Allocator = std.mem.Allocator;

const Terminal = @import("App/Terminal.zig");
const Signal = @import("lib").types.Signal;
const input = @import("App/input.zig");
const UIHandler = @import("App/UIHandler.zig");

const lib = @import("lib");
const AppInfo = lib.types.AppInfo;

const files = @import("App/files.zig");

const Buffer = lib.types.Buffer;

const App = @This();

terminal: Terminal,
ui_handler: UIHandler,

pub fn init(alloc: Allocator, app_info: AppInfo) !App {
    var terminal = try Terminal.init();
    try terminal.enableRawMode();
    const window_dimensions = Terminal.getWindowSize();

    const buffer = if (app_info.buffer_name) |p|
        try files.importFileData(alloc, p)
    else
        Buffer.init(alloc);

    const ui_handler = try UIHandler.init(
        alloc,
        window_dimensions,
        buffer,
        app_info,
    );

    return App{
        .terminal = terminal,
        .ui_handler = ui_handler,
    };
}

pub fn deinit(self: *App) !void {
    self.ui_handler.deinit();
    try self.terminal.disableRawMode();
}

pub fn run(self: *App, alloc: Allocator) Signal!void {
    paceFrames();

    const window_size = Terminal.getWindowSize();
    if (!std.meta.eql(window_size, self.ui_handler.getOutputDimensions())) {
        self.ui_handler.setOutputDimensions(window_size) catch |err| {
            std.log.err("{any}", .{err});
            return Signal.Exit;
        };
    }

    var input_buffer: [8]u8 = undefined;
    const event = input.getInputEvent(&input_buffer) catch |err| {
        log.err("{any}", .{err});
        return Signal.Exit;
    };

    self.ui_handler.processEvent(event) catch |err| switch (err) {
        Signal.SaveBuffer => {
            files.exportFileData(self.ui_handler.getCurrentBuffer().*, alloc) catch |e| {
                log.err("Could Not Export File Data: {any}", .{e});
            };
            return Signal.Exit;
        },
        Signal.Exit => return Signal.Exit,
        else => {
            log.err("{any}", .{err});
            return Signal.Exit;
        },
    };
}

const max_refresh = @as(i64, @intFromFloat(1.0 / 200.0 * 1000));

var last_update: i64 = 0;
fn paceFrames() void {
    const delta_time = std.time.milliTimestamp() - last_update;
    last_update = std.time.milliTimestamp();
    if (max_refresh > delta_time) {
        const sleep_time: u64 = @intCast((max_refresh - delta_time) * 1000 * 1000);
        std.Thread.sleep(sleep_time);
    }
}
