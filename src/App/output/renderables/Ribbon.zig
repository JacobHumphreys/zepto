const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const Renderable = lib.Renderable;
const Vec2 = lib.Vec2;

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
        .elements = try ArrayList([]const u8).initCapacity(alloc, elements.len),
    };

    for (elements) |element| {
        self.elements.appendAssumeCapacity(element);
    }

    return self;
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

pub fn renderable(self: *Ribbon) Renderable {
    return Renderable.from(self);
}

pub fn deinit(self: *Ribbon) void {
    self.elements.deinit(self.allocator);
}

test "toString" {
    var test_ribbon = try Ribbon.Init(
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
