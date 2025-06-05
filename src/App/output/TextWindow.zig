const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;

const TextWindow = @This();

pub const Error = error{
    FailedToAppendToBuffer,
};

var arena: ArenaAllocator = undefined;

text_buffer: ArrayList(u8),
cursor_position: struct { x: i32, y: i32 },
dimensions: struct { x: u32, y: u32 },
allocator: Allocator,

pub fn init(alloc: Allocator) TextWindow {
    arena = ArenaAllocator.init(alloc);
    return TextWindow{
        .cursor_position = .{ .x = 0, .y = 0 },
        .dimensions = .{ .x = 100, .y = 100 },
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

pub fn moveCursor(self: *TextWindow, offset: struct { x: i32, y: i32 }) void {
    if (!(self.cursor_position.x == 0 and offset.x < 0) or
        !(self.cursor_position.x == self.dimensions.x - 1 and offset.x > 0)) //check x bounds
    {
        self.cursor_position.x += offset.x;
    }
    if (!(self.cursor_position.y == 0 and offset.y < 0) or
        !(self.cursor_position.y == self.dimensions.y - 1 and offset.y > 0))
    {
        self.cursor_position.y += offset.y;
    }
}

test "MemTest" {
    var t = TextWindow.init(std.testing.allocator);
    defer t.deinit();
    try t.addCharToBuffer('3');
    try t.addSequenceToBuffer("\r\n");
}

test "cursor move" {
    var t = TextWindow.init(std.testing.allocator);
    defer t.deinit();
    t.moveCursor(.{ 3, 4 });
    try std.testing.expect(t.cursor_position == .{ 3, 4 });
    t.moveCursor(.{ -3, -4 });
    try std.testing.expect(t.cursor_position.x == .{ 0, 0 });
    t.moveCursor(.{ -1, 3 });
    try std.testing.expect(t.cursor_position.x == .{ 0, 3 });
}
