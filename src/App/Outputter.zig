const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const input = @import("input.zig");
pub const InputEvent = input.Event;
pub const ControlSequence = input.ControlSequence;
const rendering = @import("output/rendering.zig");
const TextWindow = @import("output/TextWindow.zig");
const Signal = @import("signals.zig").Signal;

const Outputter = @This();

pub const Error = TextWindow.Error || rendering.Error;

var arena: ArenaAllocator = undefined;

text_window: TextWindow,

pub fn init(allocator: Allocator) !Outputter {
    try rendering.clearScreen();
    arena = ArenaAllocator.init(allocator);
    const alloc = arena.allocator();
    const text_window = TextWindow.init(alloc);
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
            if (char == 'q') {
                return Signal.Exit;
            }

            try self.text_window.addCharToBuffer(char);

            return rendering.updateOutput(self.text_window);
        },
        .control => |sequence| return self.processControlSequence(sequence),
    }
}

pub fn processControlSequence(self: *Outputter, sequence: ControlSequence) (Error || Signal)!void {
    switch (sequence) {
        .new_line => {
            const control_code = sequence.getValue().?;
            try self.text_window.addSequenceToBuffer(control_code);
            try rendering.reRenderOutput(self.text_window);
        },
        else => return,
    }
}

test "MemTest" {
    var outputter = try Outputter.init(std.testing.allocator);
    defer outputter.deinit();
    try outputter.processEvent(.{ .input = '3' });
    try outputter.processEvent(.{ .control = .new_line });
    try std.testing.expectError(Signal.Exit, outputter.processEvent(.{ .input = 'q' }));
}
