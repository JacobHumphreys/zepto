pub const Vec2 = @import("types/Vec2.zig");
pub const Buffer = @import("types/Buffer.zig");
pub const RenderElement = @import("types/RenderElement.zig");
pub const input = @import("types/input.zig");

pub const Signal = error{
    Exit,
    SaveBuffer,
};
