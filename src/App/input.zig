pub const fetching = @import("input/fetching.zig");
pub const parsing = @import("input/fetching.zig");

pub const Event = enum(u8) {
    Input,
    Delete,
    Control,
};

pub const Error = error{
    FetchingError,
};

fn getInputEvent() Error!Event {
    fetching.getNextInput() catch {
        return Error.FetchingError;
    };
}
