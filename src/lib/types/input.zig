const std = @import("std");
const EnumMap = std.EnumMap;
const StaticStringMap = std.StaticStringMap;
const control_code = std.ascii.control_code;

pub const InputEvent = union(enum) {
    input: u8,
    control: ControlSequence,
};

// Essentially just a tagged union but using an internal enum map because strings
pub const ControlSequence = enum {
    new_line,
    left,
    right,
    up,
    down,
    backspace,
    exit,
    clear_screen,
    enter_alt_screen,
    exit_alt_screen,
    show_cursor,
    hide_cursor,
    unknown,

    const esc = [1]u8{control_code.esc};
    const OutputSequenceMap = EnumMap(ControlSequence, []const u8).init(.{
        .new_line = "\n",
        .clear_screen = esc ++ "[2J" ++ esc ++ "[H",
        .enter_alt_screen = esc ++ "[?1049h",
        .exit_alt_screen = esc ++ "[?1049l",
        .show_cursor = esc ++ "[?25h",
        .hide_cursor = esc ++ "[?25l",
    });

    pub inline fn getValue(key: ControlSequence) ?[]const u8 {
        return OutputSequenceMap.get(key);
    }

    pub inline fn from(sequence: []const u8) ControlSequence {
        return KeyCodeMap.get(sequence) orelse ControlSequence.unknown;
    }
};

const KeyCodeMap = StaticStringMap(ControlSequence).initComptime(.{
    .{ KeyCode.left, ControlSequence.left },
    .{ KeyCode.right, ControlSequence.right },
    .{ KeyCode.up, ControlSequence.up },
    .{ KeyCode.down, ControlSequence.down },
});

const KeyCode = struct {
    const left = .{control_code.esc} ++ "[D";
    const right = .{control_code.esc} ++ "[C";
    const up = .{control_code.esc} ++ "[A";
    const down = .{control_code.esc} ++ "[B";
};
