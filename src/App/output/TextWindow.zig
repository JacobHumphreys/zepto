const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const TextWindow = @This();

pub const Error = error{
    FailedToAppendToBuffer,
};

text_buffer: ArrayList(u8),
allocator: Allocator,

pub fn init(alloc: Allocator) TextWindow {
    return TextWindow{
        .text_buffer = .empty,
        .allocator = alloc,
    };
}

pub fn deinit(self: *TextWindow) void {
    self.text_buffer.deinit(self.allocator);
}

pub fn addCharToBuffer(self: *TextWindow, char: u8) Error!void {
    self.text_buffer.append(self.allocator, char) catch return Error.FailedToAppendToBuffer;
}

pub fn getLineSepperatedBuffer(self: TextWindow) mem.SplitIterator(u8, .sequence) {
    return mem.splitSequence(u8, self.text_buffer.items, "\n");
}
