const lib = @import("lib");
const ControlSequence = lib.ControlSequence;
const InputEvent = lib.InputEvent;

const fetching = @import("input/fetching.zig");
const parsing = @import("input/parsing.zig");

pub const Error = error{
    FetchingError,
    ParsingEventError,
};

pub fn getInputEvent(buffer: []u8) Error!InputEvent {
    const input = fetching.getNextInput(buffer) catch {
        return Error.FetchingError;
    };

    return parsing.parseEvent(input);
}
