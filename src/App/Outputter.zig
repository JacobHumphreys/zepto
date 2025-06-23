const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const Vec2 = lib.Vec2;
const InputEvent = lib.input.InputEvent;
const Signal = lib.Signal;
const ControlSequence = lib.input.ControlSequence;

const input = @import("input.zig");
const rendering = @import("output/rendering.zig");
const renderables = @import("output/renderables.zig");
const RenderElement = @import("output/RenderElement.zig");

const Outputter = @This();

pub const Error = renderables.Error || rendering.Error;

text_window: *renderables.TextWindow,
top_bar: *renderables.Ribbon,
bottom_bar: *renderables.Ribbon,

elements: ArrayList(RenderElement),
alloc: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2) (Allocator.Error || Error)!Outputter {
    try rendering.clearScreen();
    var element_list = ArrayList(RenderElement).empty;

    const top_bar = try alloc.create(renderables.Ribbon);
    top_bar.* = try renderables.Ribbon.init(
        alloc,
        @as(usize, @intCast(dimensions.x)),
        &.{"This is a test top ribbon"},
    );

    try element_list.append(alloc, .{
        .value = top_bar.renderable(),
        .position = .{ .x = @divFloor(dimensions.x, 3), .y = 0 },
        .is_visible = true,
    });

    const window_dimensions: Vec2 = .{
        .x = dimensions.x,
        .y = dimensions.y - 2,
    };

    const text_window = try alloc.create(renderables.TextWindow);
    text_window.* = renderables.TextWindow.init(alloc, window_dimensions);

    try element_list.append(alloc, .{
        .value = text_window.renderable(),
        .position = .{ .x = 0, .y = 1 },
        .is_visible = true,
    });

    const bottom_bar = try alloc.create(renderables.Ribbon);
    bottom_bar.* = try renderables.Ribbon.init(
        alloc,
        @as(usize, @intCast(dimensions.x)),
        &.{"This is a test bottom ribbon"},
    );

    try element_list.append(
        alloc,
        .{
            .value = bottom_bar.renderable(),
            .position = .{ .x = 0, .y = dimensions.y - 1 },
            .is_visible = true,
        },
    );

    return Outputter{
        .alloc = alloc,

        .elements = element_list,

        .text_window = text_window,
        .bottom_bar = bottom_bar,
        .top_bar = top_bar,
    };
}

pub fn deinit(self: *Outputter) void {
    self.text_window.deinit();
    self.bottom_bar.deinit();
    self.top_bar.deinit();

    self.alloc.destroy(self.text_window);
    self.alloc.destroy(self.bottom_bar);
    self.alloc.destroy(self.top_bar);
}

pub fn processEvent(self: *Outputter, event: InputEvent) (Error || Signal)!void {
    switch (event) {
        .input => |char| {
            try self.text_window.addCharToBuffer(char);

            try rendering.reRenderOutput(self.elements.items, self.alloc);
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },
        .control => |sequence| {
            return self.processControlSequence(sequence);
        },
    }
}

pub fn setOutputDimensions(self: *Outputter, dimensions: Vec2) void {
    self.text_window.dimensions = dimensions;
}

pub fn processControlSequence(self: *Outputter, sequence: ControlSequence) (Error || Signal)!void {
    switch (sequence) {
        .backspace => {
            self.text_window.deleteAtCursorPosition();
            try rendering.reRenderOutput(self.elements.items, self.alloc);
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },

        .exit => return Signal.Exit,

        .new_line => {
            try self.text_window.addSequenceToBuffer(sequence);
            self.text_window.cursor_position.x = 0;
            self.text_window.moveCursor(.{ .x = 0, .y = 1 });
            try rendering.reRenderOutput(self.elements.items, self.alloc);
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },

        .left => {
            self.text_window.moveCursor(.{ .x = -1, .y = 0 });
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },
        .right => {
            self.text_window.moveCursor(.{ .x = 1, .y = 0 });
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },
        .up => {
            self.text_window.moveCursor(.{ .x = 0, .y = -1 });
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },
        .down => {
            self.text_window.moveCursor(.{ .x = 0, .y = 1 });
            return rendering.renderCursorFromGlobalSpace(
                self.text_window.cursor_position,
            );
        },

        .unknown => return,
    }
}
