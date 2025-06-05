const std = @import("std");

const control_code = std.ascii.control_code;
const EnumMap = std.enums.EnumMap;
const StaticStringMap = std.StaticStringMap;

const lib = @import("lib");
const InputEvent = lib.InputEvent;
const ControlSequence = lib.ControlSequence;

pub fn parseEvent(input: []u8) InputEvent {
    if (input.len == 1) {
        return switch (input[0]) {
            '\n', '\r' => InputEvent{ .control = ControlSequence.new_line },
            getControlCombination('q') => InputEvent{ .control = ControlSequence.exit },
            else => InputEvent{ .input = input[0] },
        };
    }

    return InputEvent{ .control = ControlSequence.from(input) };
}

fn getControlCombination(char: u8) u8 {
    return char & std.ascii.control_code.us;
}
