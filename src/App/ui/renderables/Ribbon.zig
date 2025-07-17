//! A single line ui element without a cursor that has aligned text.
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const intCast = lib.casts.intCast;
const Stringable = lib.interfaces.Stringable;
const Vec2 = lib.types.Vec2;

const Ribbon = @This();

elements: ArrayList(Element),
width: usize,
allocator: Allocator,

pub const FgColor = enum(u8) {
    black = 30,
    red = 91,
    green = 92,
    yellow = 93,
    blue = 94,
    magenta = 95,
    cyan = 96,
    white = 97,
};

pub const BgColor = enum(u8) {
    black = 40,
    red = 101,
    green = 102,
    yellow = 103,
    blue = 104,
    magenta = 105,
    cyan = 106,
    white = 107,
};

pub const Element = struct {
    text: []const u8,
    ///Start index stored in x, non-inclusive end index stored in y.
    color_range: ?Vec2 = null,
    background_color: ?BgColor = null,
    foreground_color: ?FgColor = null,
};

pub fn init(
    alloc: Allocator,
    width: usize,
    elements: []const Element,
) Allocator.Error!Ribbon {
    var element_list = try ArrayList(Element).initCapacity(alloc, elements.len);

    element_list.appendSliceAssumeCapacity(elements);
    return Ribbon{
        .allocator = alloc,
        .width = width,
        .elements = element_list,
    };
}

pub fn stringable(self: *Ribbon) Stringable {
    return Stringable.from(self);
}

/// Outputs a string representing a single line no longer than the width of the ribbon with every
/// element taking the same amount of space.
pub fn toStringList(self: *Ribbon, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    var output_list = ArrayList(ArrayList(u8)).empty;

    const element_width = self.width / self.elements.items.len;

    var output_buffer = ArrayList(u8).empty;

    var text_len: usize = 0;

    for (self.elements.items) |element| {
        text_len += element.text.len;
        var num_buf: [32]u8 = undefined;

        var fg_str: []const u8 = "";
        if (element.foreground_color) |color_id| {
            fg_str = std.fmt.bufPrint(
                num_buf[0..16],
                "{c}[{}m",
                .{ std.ascii.control_code.esc, @intFromEnum(color_id) },
            ) catch |err| @panic(@errorName(err));
        }

        var bg_str: []const u8 = "";
        if (element.background_color) |color_id| {
            bg_str = std.fmt.bufPrint(
                num_buf[16..],
                "{c}[{}m",
                .{ std.ascii.control_code.esc, @intFromEnum(color_id) },
            ) catch |err| @panic(@errorName(err));
        }

        const reset_str: []const u8 = if (bg_str.len > 0 or fg_str.len > 0)
            .{std.ascii.control_code.esc} ++ "[0m"
        else
            "";

        var range_start: usize = 0;
        var range_end: usize = element.text.len;

        if (element.color_range) |range| {
            range_start = intCast(usize, range.x);
            range_end = intCast(usize, range.y);
        }

        const element_output = try std.mem.concat(
            alloc,
            u8,
            &.{
                fg_str,
                bg_str,
                element.text[range_start..range_end],
                reset_str,
                element.text[range_end..],
            },
        );

        defer alloc.free(element_output);

        if (element_width > element.text.len) {
            try output_buffer.appendSlice(alloc, element_output);
            try output_buffer.appendNTimes(alloc, ' ', element_width - element.text.len);
        } else {
            const fmt_len = fg_str.len + bg_str.len;
            try output_buffer.appendSlice(
                alloc,
                element_output[0 .. fmt_len + element_width + reset_str.len],
            );
        }
    }

    try output_list.append(alloc, output_buffer);
    return output_list;
}

pub fn deinit(self: *Ribbon) void {
    self.elements.deinit(self.allocator);
}

test "toStringList" {
    var test_ribbon = try Ribbon.init(
        std.testing.allocator,
        60,
        &.{
            .{ .text = "C-X Exit" },
            .{ .text = "C-C Copy" },
            .{ .text = "C-V paste" },
            .{ .text = "C-Q Quit" },
        },
    );
    defer test_ribbon.deinit();

    const expected_output = "C-X Exit       C-C Copy       C-V paste      C-Q Quit       ";

    var real_output = try test_ribbon.toStringList(std.testing.allocator);
    defer real_output.deinit(std.testing.allocator);

    defer real_output.items[0].deinit(std.testing.allocator);

    try std.testing.expectEqualStrings(expected_output, real_output.items[0].items);
}
