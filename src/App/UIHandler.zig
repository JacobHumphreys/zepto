//! Handles ui rendering and processing of input events at a high level.
const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const zepto = @import("zepto");
const Vec2 = zepto.Vec2;
const InputEvent = zepto.input.InputEvent;
const Signal = zepto.Signal;
const Buffer = zepto.Buffer;
const AppInfo = zepto.AppInfo;

const ui = @import("ui.zig");
const rendering = ui.rendering;
const pages = ui.pages;
const Page = pages.Page;
const MainPage = pages.MainPage;

const UIHandler = @This();

current_page: Page,
alloc: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2, buffer: Buffer, app_info: AppInfo) (Allocator.Error || ui.Error)!UIHandler {
    try rendering.enterAltScreen();
    try rendering.clearScreen();

    var page = try alloc.create(MainPage);
    page.* = try MainPage.init(alloc, dimensions, buffer, app_info);

    try rendering.reRenderOutput(alloc, page.page());

    return UIHandler{
        .alloc = alloc,
        .current_page = page.page(),
    };
}

pub fn deinit(self: *UIHandler) void {
    rendering.exitAltScreen() catch |err| {
        std.log.err("{any}", .{err});
    };
    self.current_page.deinit();
    self.alloc.destroy(self.current_page.main_page);
}

pub fn processEvent(self: *UIHandler, event: InputEvent) (Allocator.Error || Signal)!void {
    self.current_page.processNewEvent(event) catch |err| switch (err) {
        Signal.RedrawBuffer => {
            rendering.reRenderOutput(self.alloc, self.current_page) catch |e| switch (e) {
                Allocator.Error.OutOfMemory => |alloc_err| return alloc_err,
                else => {
                    std.log.err("{any}", .{e});
                    return Signal.Exit;
                },
            };
        },
        else => return err,
    };
}

pub inline fn getOutputDimensions(self: *UIHandler) Vec2 {
    return self.current_page.getDimensions();
}

pub fn setOutputDimensions(self: *UIHandler, dimensions: Vec2) (Allocator.Error || ui.Error)!void {
    self.current_page.setOutputDimensions(dimensions);
    try rendering.reRenderOutput(self.alloc, self.current_page);
}

pub inline fn getCurrentBuffer(self: *UIHandler) *Buffer {
    return self.current_page.getCurrentBuffer();
}
