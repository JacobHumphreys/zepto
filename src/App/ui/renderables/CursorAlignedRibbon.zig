const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const intCast = lib.casts.intCast;
const Vec2 = lib.types.Vec2;
const Stringable = lib.interfaces.Stringable;
const FgColor = lib.text.FgColor;
const BgColor = lib.text.BgColor;
const CursorContainer = lib.interfaces.CursorContainer;
const Signal = lib.types.Signal;
const InputEvent = lib.types.input.InputEvent;

const AlignedRibbon = @import("AlignedRibbon.zig");
const Element = AlignedRibbon.Element;

const CursorAlignedRibbon = @This();
text: []const u8,
input: ArrayList(u8),
width: usize,
cursor_position: usize,
alloc: Allocator,

pub fn init(alloc: Allocator, text: []const u8, width: usize) CursorAlignedRibbon {
    return CursorAlignedRibbon{
        .text = text,
        .alloc = alloc,
        .input = .empty,
        .width = width,
        .cursor_position = 0,
    };
}

pub fn deinit(self: *CursorAlignedRibbon) void {
    self.input.deinit(self.alloc);
}

pub fn stringable(self: *CursorAlignedRibbon) Stringable {
    return Stringable.from(self);
}

pub fn cursorContainer(self: *CursorAlignedRibbon) CursorContainer {
    return CursorContainer.from(self);
}

/// Outputs a string representing a single line no longer than the width of the ribbon with every
/// element taking the same amount of space.
pub fn toStringList(self: *CursorAlignedRibbon, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    var base_ribbon = try AlignedRibbon.init(
        alloc,
        self.text.len + self.input.items.len,
        &.{
            AlignedRibbon.Element{
                .alignment = .left,
                .text = self.text,
            },
            AlignedRibbon.Element{
                .alignment = .left,
                .text = self.input.items,
            },
        },
        null,
        null,
    );
    defer base_ribbon.deinit();
    return base_ribbon.toStringList(alloc);
}

pub fn getCursorPosition(self: CursorAlignedRibbon) Vec2 {
    return .{
        .x = intCast(i32, self.cursor_position),
        .y = 0,
    };
}

pub fn moveCursor(self: *CursorAlignedRibbon, offset: Vec2) void {
    const new_pos: i32 = intCast(i32, self.cursor_position) + offset.x;
    self.cursor_position = intCast(
        usize,
        clamp(
            i32,
            .{
                .value = new_pos,
                .max = intCast(i32, self.input.items.len),
                .min = 0,
            },
        ),
    );
}

inline fn clamp(comptime T: type, opts: struct { value: T, min: T, max: T }) T {
    std.debug.assert(opts.max >= opts.value);
    std.debug.assert(opts.min <= opts.value);
    return @max(
        opts.min,
        @min(
            opts.max,
            opts.value,
        ),
    );
}

pub fn processEvent(self: *CursorAlignedRibbon, event: InputEvent) (Signal || CursorContainer.Error)!void {
    switch (event) {
        .input => |char| {
            self.input.insert(self.alloc, intCast(usize, self.cursor_position), char) catch {
                return CursorContainer.Error.FailedToProcessEvent;
            };

            self.moveCursor(.{ .x = 1, .y = 0 });
        },
        .control => |sequence| {
            switch (sequence) {
                .backspace => {
                    _ = self.input.orderedRemove(self.cursor_position);
                    return;
                },
                .left => {
                    self.moveCursor(.{ .x = -1, .y = 0 });
                    return;
                },
                .right => {},
                .new_line => {},
                else => return,
            }
        },
    }
    return;
}
