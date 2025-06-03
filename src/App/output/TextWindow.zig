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
allocator: Allocator,

pub fn init(alloc: Allocator) TextWindow {
    arena = ArenaAllocator.init(alloc);
    return TextWindow{
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

test "MemTest" {
    var t = TextWindow.init(std.testing.allocator);
    try t.addCharToBuffer('3');
    try t.addSequenceToBuffer("\r\n");
    t.deinit();
}
