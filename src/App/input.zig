const fetching = @import("input/fetching.zig");
const parsing = @import("input/fetching.zig");

const Event = union(enum) {
    input: u8,
    delete,
    control,
};

pub const Error = error{
    FetchingError,
};

pub fn getInputEvent() Error!Event {
    const input = fetching.getNextInput() catch {
        return Error.FetchingError;
    };
    return Event{ .input = input };
}
