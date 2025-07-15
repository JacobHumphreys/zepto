//! Handles ui rendering and processing of input events at a high level.
const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const types = lib.types;
const Vec2 = types.Vec2;
const InputEvent = types.input.InputEvent;
const Signal = types.Signal;
const ControlSequence = types.input.ControlSequence;
const Buffer = types.Buffer;
const Page = lib.interfaces.Page;
const intCast = lib.casts.intCast;

const ui = @import("ui.zig");
const rendering = ui.rendering;
const MainPage = ui.MainPage;

const UIHandler = @This();

current_page: MainPage,
alloc: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2, buffer: lib.types.Buffer) (Allocator.Error || ui.Error)!UIHandler {
    //#TODO Enter alt screen.
    try rendering.enterAltScreen();
    try rendering.clearScreen();

    var page = try MainPage.init(alloc, dimensions, buffer);

    try rendering.reRenderOutput(page.page(), alloc);

    const cursor_parent = try page.getCursorParent();
    try rendering.renderCursor(cursor_parent);

    return UIHandler{
        .alloc = alloc,
        .current_page = page,
    };
}

pub fn deinit(self: *UIHandler) void {
    rendering.exitAltScreen() catch |err| {
        std.log.err("{any}", .{err});
    };
    self.current_page.deinit();
    //#Todo exit alt screen
}

pub fn processEvent(self: *UIHandler, event: InputEvent) (Allocator.Error || ui.Error || Signal)!void {
    switch (event) {
        .input => |char| {
            try self.current_page.text_window.addCharToBuffer(char);

            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(
                try self.current_page.getCursorParent(),
            );
        },
        .control => |sequence| {
            return self.processControlSequence(sequence);
        },
    }
}

pub fn setOutputDimensions(self: *UIHandler, dimensions: Vec2) void {
    self.current_page.dimensions = dimensions;
}

pub fn processControlSequence(self: *UIHandler, sequence: ControlSequence) (Allocator.Error || ui.Error || Signal)!void {
    switch (sequence) {
        .backspace => {
            try self.current_page.text_window.deleteAtCursorPosition();
            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(try self.current_page.getCursorParent());
        },

        .exit => return Signal.Exit,

        .new_line => {
            try self.current_page.text_window.addSequenceToBuffer(sequence);

            const cursor_parent = try self.current_page.getCursorParent();
            const cursor_container = cursor_parent.cursor_container.?;

            const cursor_pos = cursor_container.getCursorPosition();

            cursor_container.moveCursor(.{ .x = -cursor_pos.x, .y = 1 });

            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(cursor_parent);
        },

        .left => {
            const cursor_parent = try self.current_page.getCursorParent();
            const cursor_container = cursor_parent.cursor_container.?;
            cursor_container.moveCursor(.{ .x = -1 });
            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(cursor_parent);
        },
        .right => {
            const cursor_parent = try self.current_page.getCursorParent();
            const cursor_container = cursor_parent.cursor_container.?;
            cursor_container.moveCursor(.{ .x = 1 });
            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(cursor_parent);
        },
        .up => {
            const cursor_parent = try self.current_page.getCursorParent();
            const cursor_container = cursor_parent.cursor_container.?;
            cursor_container.moveCursor(.{ .y = -1 });
            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(cursor_parent);
        },
        .down => {
            const cursor_parent = try self.current_page.getCursorParent();
            const cursor_container = cursor_parent.cursor_container.?;
            cursor_container.moveCursor(.{ .y = 1 });
            try rendering.reRenderOutput(
                self.current_page.page(),
                self.alloc,
            );
            return rendering.renderCursor(cursor_parent);
        },

        else => return,
    }
}

pub fn getCurrentBuffer(self: *UIHandler) Buffer {
    return self.current_page.getCurrentBuffer();
}
