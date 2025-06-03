const fetching = @import("input/fetching.zig");
const parsing = @import("input/fetching.zig");

const Event = union(enum) {
    input: u8,
    control: []const u8,
};

pub const Control = struct {
    const new_line: []const u8 = "\r\n";
};

pub const Error = error{
    FetchingError,
    ParsingEventError,
};

pub fn getInputEvent() Error!Event {
    const input = fetching.getNextInput() catch {
        return Error.FetchingError;
    };

    switch (input) {
        .character => |char| {
            if (char == '\n' or char == '\r') {
                return Event{ .control = Control.new_line };
            }
            return Event{ .input = char };
        },
        .sequence => |sequence| {
            return Event{ .control = sequence };
        },
    }
}
