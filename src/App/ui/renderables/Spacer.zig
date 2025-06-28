//! Used to fill a blank line on the screen
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const Stringable = lib.interfaces.Stringable;
const Vec2 = lib.types.Vec2;

const Spacer = @This();

width: usize,

pub fn init(width: usize) Spacer {
    return Spacer{
        .width = width,
    };
}

pub fn stringable(self: *Spacer) Stringable {
    return Stringable.from(self);
}

pub fn toString(self: *Spacer, alloc: Allocator) Allocator.Error![]const u8 {
    const output_buffer = try alloc.alloc(u8, self.width);
    @memset(output_buffer, ' ');
    return output_buffer;
}
