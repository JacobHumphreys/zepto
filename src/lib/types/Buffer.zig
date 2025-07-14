const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const intCast = @import("../casts.zig").intCast;
const ControlSequence = @import("input.zig").ControlSequence;
const Vec2 = @import("Vec2.zig");

const Buffer = @This();

data: ArrayList(u8),
alloc: Allocator,

pub const Error = error{
    FailedToAppendToBuffer,
    FailedToRemoveFromBuffer,
};

pub fn init(alloc: Allocator) Buffer {
    return Buffer{
        .data = ArrayList(u8).empty,
        .alloc = alloc,
    };
}

pub fn deinit(self: *Buffer) void {
    self.data.deinit(self.alloc);
}

pub fn appendCharAtPosition(self: *Buffer, position: usize, char: u8) Error!void {
    self.data.insert(self.alloc, position, char) catch {
        return Error.FailedToAppendToBuffer;
    };
}

pub fn appendSliceAtPosition(self: *Buffer, position: usize, slice: []const u8) Error!void {
    self.data.insertSlice(self.alloc, position, slice) catch {
        return Error.FailedToAppendToBuffer;
    };
}

const new_line_sequence = ControlSequence.new_line.getValue().?;

/// Allocates new arraylist using the structs internal allocator of the text buffer's lines,
/// not including line breaks; Adds an empty line to the end if newline is final
pub fn getLineSepperatedList(self: Buffer, alloc: Allocator) Allocator.Error!ArrayList([]u8) {
    var line_sep_list: ArrayList([]u8) = .empty;
    var buffer_window = self.data.items;

    while (mem.indexOf(u8, buffer_window, new_line_sequence)) |new_line_index| {
        try line_sep_list.append(alloc, buffer_window[0..new_line_index]);
        buffer_window = buffer_window[new_line_index + new_line_sequence.len ..];
    }

    // If buffer_window is empty allows cursor to be moved to empty new line.
    // else adds rest of buffer to new line
    try line_sep_list.append(alloc, buffer_window);

    return line_sep_list;
}
