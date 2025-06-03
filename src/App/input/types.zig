const std = @import("std");
const control_code = std.ascii.control_code;
const EnumMap = std.enums.EnumMap;

pub const Event = union(enum) {
    input: u8,
    control: ControlSequence,
};

pub const ControlSequence = enum {
    const ControlMap = EnumMap(ControlSequence, []const u8).init(.{
        .new_line = KeyCode.new_line,
        .left = KeyCode.left,
        .right = KeyCode.right,
        .up = KeyCode.up,
        .down = KeyCode.down,
    });

    pub fn getValue(key: ControlSequence) ?[]const u8 {
        return ControlMap.get(key);
    }

    new_line,
    left,
    right,
    up,
    down,
    unknown,
};

pub const KeyCode = struct {
    pub const new_line = "\r\n";
    pub const left = .{control_code.esc} ++ "[D";
    pub const right = .{control_code.esc} ++ "[C";
    pub const up = .{control_code.esc} ++ "[A";
    pub const down = .{control_code.esc} ++ "[B";
};
