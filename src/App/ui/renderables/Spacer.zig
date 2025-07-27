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

pub fn toStringList(self: *Spacer, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    var output_line = try ArrayList(u8).initCapacity(alloc, self.width);
    output_line.appendNTimesAssumeCapacity(' ', self.width);

    var output_list = try ArrayList(ArrayList(u8)).initCapacity(alloc, 1);
    output_list.appendAssumeCapacity(output_line);

    return output_list;
}
