const types = @import("input/types.zig");
pub const Event = types.Event;
pub const ControlSequence = types.ControlSequence;
const fetching = @import("input/fetching.zig");
const parsing = @import("input/parsing.zig");

pub const Error = error{
    FetchingError,
    ParsingEventError,
};

pub fn getInputEvent(buffer: []u8) Error!Event {
    const input = fetching.getNextInput(buffer) catch {
        return Error.FetchingError;
    };

    return parsing.parseEvent(input);
}
