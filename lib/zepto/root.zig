//! This internal package contains various things used throughout the program that cannot be
//! contained within a single sub-package without overly using complex import paths.
const types = @import("types.zig");

pub const Vec2 = types.Vec2;
pub const input = types.input;
pub const Buffer = types.Buffer;

pub const Signal = types.Signal; 
pub const AppInfo = types.AppInfo; 
pub const Queue = types.Queue;

pub const files = @import("files.zig");

/// An inline function alias for @as(T, @intCast(value))
pub inline fn intCast(comptime T: type, value: anytype) T {
    return @intCast(value);
}
