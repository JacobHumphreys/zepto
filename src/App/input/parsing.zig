const std = @import("std");
const types = @import("types.zig");
const Event = types.Event;
const ControlSequences = types.ControlSequence;
const KeyCode = types.KeyCode;

pub fn parseEvent(input: []u8) Event {
    if (input.len == 1) {
        const char = input[0];
        if (char == '\n' or char == '\r') {
            return Event{ .control = ControlSequences.new_line };
        }
        return Event{ .input = char };
    }

    if (std.mem.eql(u8, input, KeyCode.up)) {
        return Event{ .control = .up };
    }
    if (std.mem.eql(u8, input, KeyCode.down)) {
        std.log.info("down", .{});
        return Event{ .control = .down };
    }
    if (std.mem.eql(u8, input, KeyCode.left)) {
        return Event{ .control = .left };
    }
    if (std.mem.eql(u8, input, KeyCode.right)) {
        return Event{ .control = .right };
    }

    return Event{ .control = .unknown };
}
