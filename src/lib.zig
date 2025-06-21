const std = @import("std");

pub const Vec2 = @import("lib/Vec2.zig");
pub const input = @import("lib/input.zig");
pub const Renderable = @import("lib/Renderable.zig");

pub const Signal = error{
    Exit,
};
