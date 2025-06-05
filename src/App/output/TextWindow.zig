const std = @import("std");
const mem = std.mem;
const Tuple = std.meta.Tuple;
const ArrayList = std.ArrayListUnmanaged;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;

const Vec2 = @import("lib").Vec2;

const TextWindow = @This();

pub const Error = error{
    FailedToAppendToBuffer,
};

var arena: ArenaAllocator = undefined;

text_buffer: ArrayList(u8),
cursor_position: Vec2,
dimensions: Vec2,
allocator: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2) TextWindow {
    arena = ArenaAllocator.init(alloc);
    return TextWindow{
        .cursor_position = .{ .x = 0, .y = 0 },
        .dimensions = dimensions,
        .text_buffer = .empty,
        .allocator = arena.allocator(),
    };
}

pub fn deinit(self: *TextWindow) void {
    _ = self;
    arena.deinit();
}

pub fn addCharToBuffer(self: *TextWindow, char: u8) Error!void {
    self.text_buffer.append(self.allocator, char) catch return Error.FailedToAppendToBuffer;
}

pub fn addSequenceToBuffer(self: *TextWindow, sequence: []const u8) Error!void {
    self.text_buffer.appendSlice(self.allocator, sequence) catch return Error.FailedToAppendToBuffer;
}

pub fn getLineSepperatedBuffer(self: TextWindow) mem.SplitIterator(u8, .sequence) {
    return mem.splitSequence(u8, self.text_buffer.items, "\n");
}

pub fn moveCursor(self: *TextWindow, offset: Vec2) void {
    self.cursor_position.x += offset.x;
    self.cursor_position.y += offset.y;

    self.cursor_position.x = std.math.clamp(self.cursor_position.x, 0, self.dimensions.x - 1);
    self.cursor_position.y = std.math.clamp(self.cursor_position.y, 0, self.dimensions.y - 1);
}

test "MemTest" {
    var t = TextWindow.init(std.testing.allocator, .{ .x = 100, .y = 100 });
    defer t.deinit();
    try t.addCharToBuffer('3');
    try t.addSequenceToBuffer("\r\n");
}

test "cursor move" {
    var t = TextWindow.init(std.testing.allocator, .{ .x = 100, .y = 100 });
    defer t.deinit();
    t.moveCursor(.{ 3, 4 });
    try std.testing.expect(t.cursor_position == .{ 3, 4 });
    t.moveCursor(.{ -3, -4 });
    try std.testing.expect(t.cursor_position.x == .{ 0, 0 });
    t.moveCursor(.{ -1, 3 });
    try std.testing.expect(t.cursor_position.x == .{ 0, 3 });
}
