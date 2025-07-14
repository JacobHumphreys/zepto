//! Handles ui rendering and processing of input events at a high level.
const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const Vec2 = lib.types.Vec2;
const InputEvent = lib.types.input.InputEvent;
const Signal = lib.types.Signal;
const ControlSequence = lib.types.input.ControlSequence;
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

    var page_elements = try page.getElements(alloc);

    try rendering.reRenderOutput(page_elements.items, dimensions, alloc);

    const cursor_parent = page_elements.items[page.cursor_parent];
    try rendering.renderCursor(cursor_parent);

    page_elements.deinit(alloc);

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

pub fn processEvent(self: *UIHandler, event: InputEvent) (ui.Error || Signal)!void {
    switch (event) {
        .input => |char| {
            var page_elements = self.current_page.getElements(self.alloc) catch {
                return;
            };
            defer page_elements.deinit(self.alloc);

            try self.current_page.text_window.addCharToBuffer(char);

            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(
                page_elements.items[self.current_page.cursor_parent],
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

pub fn processControlSequence(self: *UIHandler, sequence: ControlSequence) (ui.Error || Signal)!void {
    var page_elements = self.current_page.getElements(self.alloc) catch {
        return;
    };
    defer page_elements.deinit(self.alloc);

    switch (sequence) {
        .backspace => {
            try self.current_page.text_window.deleteAtCursorPosition();
            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },

        .exit => return Signal.Exit,

        .new_line => {
            try self.current_page.text_window.addSequenceToBuffer(sequence);

            const old_y_pos = self.current_page.text_window.cursor_position.y;

            self.current_page.text_window.cursor_position.x = 0;
            self.current_page.text_window.moveCursor(.{ .x = 0, .y = 1 });

            assert(old_y_pos + 1 == self.current_page.text_window.cursor_position.y);

            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },

        .left => {
            self.current_page.text_window.moveCursor(.{ .x = -1, .y = 0 });
            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },
        .right => {
            self.current_page.text_window.moveCursor(.{ .x = 1, .y = 0 });
            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },
        .up => {
            self.current_page.text_window.moveCursor(.{ .x = 0, .y = -1 });
            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },
        .down => {
            self.current_page.text_window.moveCursor(.{ .x = 0, .y = 1 });
            try rendering.reRenderOutput(
                page_elements.items,
                self.current_page.dimensions,
                self.alloc,
            );
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },

        else => return,
    }
}
