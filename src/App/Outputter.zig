const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const lib = @import("lib");
const Vec2 = lib.Vec2;
const InputEvent = lib.input.InputEvent;
const Signal = lib.Signal;
const ControlSequence = lib.input.ControlSequence;

const input = @import("input.zig");
const rendering = @import("output/rendering.zig");
const TextWindow = @import("output/TextWindow.zig");

const Outputter = @This();

pub const Error = TextWindow.Error || rendering.Error;

var arena: ArenaAllocator = undefined;

text_window: TextWindow,

pub fn init(allocator: Allocator, dimensions: anytype) !Outputter {
    try rendering.clearScreen();
    arena = ArenaAllocator.init(allocator);
    const alloc = arena.allocator();
    const text_window = TextWindow.init(alloc, dimensions);
    return Outputter{
        .text_window = text_window,
    };
}

pub fn deinit(self: *Outputter) void {
    self.text_window.deinit();
    arena.deinit();
}

pub fn processEvent(self: *Outputter, event: InputEvent) (Error || Signal)!void {
    switch (event) {
        .input => |char| {
            try self.text_window.addCharToBuffer(char);

            return rendering.reRenderOutput(self.text_window);
        },
        .control => |sequence| {
            return self.processControlSequence(sequence);
        },
    }
}

pub fn setOutputDimensions(self: *Outputter, dimensions: Vec2) void {
    var new_dimensions = dimensions;
    new_dimensions.y -= @as(i32, @intCast(rendering.top_bar_height));
    new_dimensions.y -= @as(i32, @intCast(rendering.bottom_bar_height));
    self.text_window.dimensions = new_dimensions;
}

pub fn processControlSequence(self: *Outputter, sequence: ControlSequence) (Error || Signal)!void {
    switch (sequence) {
        .backspace => {
            self.text_window.deleteAtCursorPosition();
            try rendering.reRenderOutput(self.text_window);
        },

        .exit => return Signal.Exit,

        .new_line => {
            try self.text_window.addSequenceToBuffer(sequence);
            self.text_window.cursor_position.x = 0;
            self.text_window.moveCursor(.{ .x = 0, .y = 1 });
            try rendering.reRenderOutput(self.text_window);
        },

        .left => {
            self.text_window.moveCursor(.{ .x = -1, .y = 0 });
            try rendering.renderCursor(self.text_window);
        },
        .right => {
            self.text_window.moveCursor(.{ .x = 1, .y = 0 });
            try rendering.renderCursor(self.text_window);
        },
        .up => {
            self.text_window.moveCursor(.{ .x = 0, .y = -1 });
            try rendering.renderCursor(self.text_window);
        },
        .down => {
            self.text_window.moveCursor(.{ .x = 0, .y = 1 });
            try rendering.renderCursor(self.text_window);
        },

        .unknown => return,
    }
}
