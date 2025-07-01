/// An inline function alias for @as(T, @intCast(value))
pub inline fn intCast(comptime T: type, value: anytype) T {
    return @as(T, @intCast(value));
}
