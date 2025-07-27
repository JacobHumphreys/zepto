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

const PromptRibbon = @This();
text: []const u8,
input: ArrayList(u8),
width: usize,
cursor_position: usize,
alloc: Allocator,
fg_color: ?FgColor,
bg_color: ?BgColor,

pub fn init(alloc: Allocator, opts: struct {
    text: []const u8,
    width: usize,
    foreground_color: ?FgColor = null,
    background_color: ?BgColor = null,
}) PromptRibbon {
    return PromptRibbon{
        .text = opts.text,
        .alloc = alloc,
        .input = .empty,
        .width = opts.width,
        .cursor_position = 0,
        .fg_color = opts.foreground_color,
        .bg_color = opts.background_color,
    };
}

pub fn deinit(self: *PromptRibbon) void {
    self.input.deinit(self.alloc);
}

pub fn stringable(self: *PromptRibbon) Stringable {
    return Stringable.from(self);
}

pub fn cursorContainer(self: *PromptRibbon) CursorContainer {
    return CursorContainer.from(self);
}

/// Outputs a string representing a single line no longer than the width of the ribbon with every
/// element taking the same amount of space.
pub fn toStringList(self: *PromptRibbon, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    var output = try ArrayList(u8).initCapacity(alloc, self.text.len + self.input.items.len);
    output.appendSliceAssumeCapacity(self.text);
    output.appendSliceAssumeCapacity(self.input.items);

    var output_list = try ArrayList(ArrayList(u8)).initCapacity(alloc, 1);
    output_list.appendAssumeCapacity(output);

    return output_list;
}

pub inline fn getCursorPosition(self: PromptRibbon) Vec2 {
    return .{
        .x = intCast(i32, self.cursor_position + self.text.len),
        .y = 0,
    };
}

pub fn moveCursor(self: *PromptRibbon, offset: Vec2) void {
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
    return @max(
        opts.min,
        @min(
            opts.max,
            opts.value,
        ),
    );
}

pub inline fn clearInput(self: *PromptRibbon) void{
    self.input.clearAndFree(self.alloc);
    self.cursor_position = 0;
}

pub fn processEvent(self: *PromptRibbon, event: InputEvent) (Signal || CursorContainer.Error)!void {
    switch (event) {
        .input => |char| {
            self.input.insert(self.alloc, intCast(usize, self.cursor_position), char) catch {
                return CursorContainer.Error.FailedToProcessEvent;
            };

            self.moveCursor(.{ .x = 1, .y = 0 });
            return Signal.RedrawBuffer;
        },
        .control => |sequence| {
            switch (sequence) {
                .backspace => {
                    if (self.cursor_position == 0) return;
                    _ = self.input.orderedRemove(self.cursor_position - 1);
                    self.moveCursor(.{ .x = -1 });
                    return Signal.RedrawBuffer;
                },
                .left => {
                    self.moveCursor(.{ .x = -1 });
                    return Signal.RedrawBuffer;
                },
                .right => {
                    self.moveCursor(.{ .x = 1 });
                    return Signal.RedrawBuffer;
                },
                .new_line => return Signal.Exit,
                else => return,
            }
        },
    }
    return;
}
