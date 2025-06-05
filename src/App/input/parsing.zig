const std = @import("std");

const control_code = std.ascii.control_code;
const EnumMap = std.enums.EnumMap;
const StaticStringMap = std.StaticStringMap;

pub fn parseEvent(input: []u8) Event {
    if (input.len == 1) {
        return switch (input[0]) {
            '\n', '\r' => Event{ .control = ControlSequence.new_line },
            getControlCombination('q') => Event{ .control = ControlSequence.exit },
            else => Event{ .input = input[0] },
        };
    }

    return Event{ .control = ControlSequence.from(input) };
}

fn getControlCombination(char: u8) u8 {
    return char & std.ascii.control_code.us;
}

pub const Event = union(enum) {
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
