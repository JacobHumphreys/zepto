//! A single line ui element without a cursor that has aligned text.
const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const intCast = lib.casts.intCast;
const Stringable = lib.interfaces.Stringable;
const Vec2 = lib.types.Vec2;
const FgColor = lib.text.FgColor;
const BgColor = lib.text.BgColor;

const AlignedRibbon = @This();

elements: ArrayList(Element),
fg_color: ?FgColor,
bg_color: ?BgColor,
width: usize,
allocator: Allocator,

pub const Alignment = enum {
    left,
    right,
    center,
};

pub const Element = struct {
    text: []const u8,
    alignment: Alignment = .left,
};

pub fn init(
    alloc: Allocator,
    width: usize,
    elements: []const Element,
    background_color: ?BgColor,
    foreground_color: ?FgColor,
) Allocator.Error!AlignedRibbon {
    var element_list = try ArrayList(Element).initCapacity(alloc, elements.len);

    element_list.appendSliceAssumeCapacity(elements);
    return AlignedRibbon{
        .allocator = alloc,
        .fg_color = foreground_color,
        .bg_color = background_color,
        .width = width,
        .elements = element_list,
    };
}

pub fn deinit(self: *AlignedRibbon) void {
    self.elements.deinit(self.allocator);
}

pub fn stringable(self: *AlignedRibbon) Stringable {
    return Stringable.from(self);
}

fn filter(comptime T: type, buffer: []T, elements: []const T, func: fn (T) bool) []T {
    var len: usize = 0;
    for (elements) |value| {
        if (func(value)) {
            buffer[len] = value;
            len += 1;
        }
    }
    return buffer[0..len];
}

/// Outputs a string representing a single line no longer than the width of the ribbon with every
/// element taking the same amount of space.
pub fn toStringList(self: *AlignedRibbon, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    var line_buffer = try ArrayList(u8).initCapacity(alloc, self.width);
    line_buffer.appendNTimesAssumeCapacity(' ', self.width);

    const segment_width: usize = self.width / 3;

    try self.applyLeftElements(
        alloc,
        line_buffer.items[0..segment_width],
    );

    try self.applyCenteredElements(
        alloc,
        line_buffer.items[segment_width .. segment_width * 2],
    );

    try self.applyRightElements(
        alloc,
        line_buffer.items[segment_width * 2 ..],
    );

    var num_buf: [32]u8 = undefined;
    var fg_str: []const u8 = "";
    if (self.fg_color) |color_id| {
        fg_str = std.fmt.bufPrint(
            num_buf[0..16],
            "{c}[{}m",
            .{ std.ascii.control_code.esc, @intFromEnum(color_id) },
        ) catch |err| @panic(@errorName(err));
    }

    var bg_str: []const u8 = "";
    if (self.bg_color) |color_id| {
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

    try line_buffer.insertSlice(alloc, 0, fg_str);
    try line_buffer.insertSlice(alloc, 0, bg_str);
    try line_buffer.appendSlice(alloc, reset_str);

    var output_list = try ArrayList(ArrayList(u8)).initCapacity(alloc, 1);
    output_list.appendAssumeCapacity(line_buffer);
    return output_list;
}

pub fn applyLeftElements(self: *AlignedRibbon, alloc: Allocator, buff: []u8) !void {
    const element_list_buffer = try alloc.alloc(Element, self.elements.items.len);
    defer alloc.free(element_list_buffer);
    const elements = filter(Element, element_list_buffer, self.elements.items, struct {
        fn f(e: Element) bool {
            return e.alignment == .left;
        }
    }.f);

    if (elements.len == 0) return;

    const elements_width = buff.len / elements.len;

    const elem_output_buff = try alloc.alloc(u8, elements_width);
    defer alloc.free(elem_output_buff);

    var previous_elements_width: usize = 0;

    for (elements) |e| {
        @memset(elem_output_buff, ' ');
        const cpy_width = @min(elements_width, e.text.len);
        @memcpy(elem_output_buff[0..cpy_width], e.text[0..cpy_width]);
        const padding: usize = if (cpy_width < elements_width) 1 else 0;
        @memcpy(
            buff[previous_elements_width .. previous_elements_width + cpy_width + padding],
            elem_output_buff[0 .. cpy_width + padding],
        );
        previous_elements_width += cpy_width + padding;
    }
}

pub fn applyCenteredElements(self: *AlignedRibbon, alloc: Allocator, buff: []u8) !void {
    const element_list_buffer = try alloc.alloc(Element, self.elements.items.len);
    defer alloc.free(element_list_buffer);
    const elements = filter(Element, element_list_buffer, self.elements.items, struct {
        fn f(e: Element) bool {
            return e.alignment == .center;
        }
    }.f);

    if (elements.len == 0) return;
    const elements_width = buff.len / elements.len;

    const elem_output_buff = try alloc.alloc(u8, elements_width);
    defer alloc.free(elem_output_buff);

    for (elements, 0..) |e, i| {
        @memset(elem_output_buff, ' ');

        if (elements_width > e.text.len) {
            const start_index = (elements_width / 2) - (e.text.len / 2);
            const end_index = start_index + e.text.len;
            @memcpy(elem_output_buff[start_index..end_index], e.text);
        } else {
            @memcpy(elem_output_buff, e.text[0..elements_width]);
        }

        @memcpy(buff[i * elements_width .. (i + 1) * elements_width], elem_output_buff);
    }
}

pub fn applyRightElements(self: *AlignedRibbon, alloc: Allocator, buff: []u8) !void {
    const element_list_buffer = try alloc.alloc(Element, self.elements.items.len);
    defer alloc.free(element_list_buffer);
    const elements = filter(Element, element_list_buffer, self.elements.items, struct {
        fn f(e: Element) bool {
            return e.alignment == .right;
        }
    }.f);

    if (elements.len == 0) return;

    const elements_width = buff.len / elements.len;

    const elem_output_buff = try alloc.alloc(u8, elements_width);
    defer alloc.free(elem_output_buff);

    for (elements, 0..) |e, i| {
        @memset(elem_output_buff, ' ');
        const cpy_width = @min(elements_width, e.text.len);
        const start = elem_output_buff.len - cpy_width;
        @memcpy(elem_output_buff[start..], e.text[0..cpy_width]);

        @memcpy(buff[i * elements_width .. (i + 1) * elements_width], elem_output_buff);
    }
}
