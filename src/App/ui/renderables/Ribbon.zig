//! A single line ui element without a cursor that has aligned text.
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const Stringable = lib.interfaces.Stringable;
const Vec2 = lib.types.Vec2;

const Ribbon = @This();

elements: ArrayList([]const u8),
width: usize,
allocator: Allocator,

pub fn init(
    alloc: Allocator,
    width: usize,
    elements: []const []const u8,
) Allocator.Error!Ribbon {
    var self = Ribbon{
        .allocator = alloc,
        .width = width,
        .elements = ArrayList([]const u8).empty,
    };

    try self.elements.insertSlice(alloc, 0, elements);

    return self;
}

pub fn stringable(self: *Ribbon) Stringable {
    return Stringable.from(self);
}

/// Outputs a string representing a single line no longer than the width of the ribbon with every
/// element taking the same amount of space.
pub fn toString(self: *Ribbon, alloc: Allocator) Allocator.Error![]const u8 {
    const element_width = self.width / self.elements.items.len;

    const output_buffer = try alloc.alloc(u8, element_width * self.elements.items.len);

    for (self.elements.items, 0..) |element, i| {
        const start_index = i * element_width;
        const end_index = start_index + element_width;

        if (element_width < element.len) {
            mem.copyForwards(u8, output_buffer[start_index..end_index], element[0..element_width]);
        } else {
            const fill_end_index = start_index + element.len;
            mem.copyForwards(u8, output_buffer[start_index..fill_end_index], element);
            @memset(output_buffer[fill_end_index..end_index], ' ');
        }
    }

    return output_buffer;
}

pub fn deinit(self: *Ribbon) void {
    self.elements.deinit(self.allocator);
}

test "toString" {
    var test_ribbon = try Ribbon.init(
        std.testing.allocator,
        60,
        &.{ "C-X Exit", "C-C Copy", "C-V paste", "C-Q Quit" },
    );
    defer test_ribbon.deinit();

    const expected_output = "C-X Exit       C-C Copy       C-V paste      C-Q Quit       ";

    const real_output = try test_ribbon.toString(std.testing.allocator);
    defer std.testing.allocator.free(real_output);

    try std.testing.expectEqualStrings(expected_output, real_output);
}
