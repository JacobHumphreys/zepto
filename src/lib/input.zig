const std = @import("std");
const EnumMap = std.EnumMap;
const StaticStringMap = std.StaticStringMap;
const control_code = std.ascii.control_code;

pub const InputEvent = union(enum) {
    input: u8,
    control: ControlSequence,
};

//essentially just a tagged union but using an internal enum map because strings
pub const ControlSequence = enum {
    new_line,
    left,
    right,
    up,
    down,
    backspace,
    exit,
    unknown,

    const OutputSequenceMap = EnumMap(ControlSequence, []const u8).init(.{
        .new_line = "\r\n",
    });

    pub fn getValue(key: ControlSequence) ?[]const u8 {
        return OutputSequenceMap.get(key);
    }

    pub fn from(sequence: []const u8) ControlSequence {
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

