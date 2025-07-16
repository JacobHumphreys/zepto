const Vec2 = @This();

pub const ZERO: Vec2 = .{ .x = 0, .y = 0 };
pub const ONE: Vec2 = .{ .x = 0, .y = 0 };

x: i32 = 0,
y: i32 = 0,

pub fn add(self: Vec2, other: Vec2) Vec2 {
    return .{
        .x = self.x + other.x,
        .y = self.y + other.y,
    };
}

pub fn mult(self: Vec2, value: i32) Vec2 {
    return .{
        .x = self.x * value,
        .y = self.y * value,
    };
}

pub fn sub(self: Vec2, other: Vec2) Vec2 {
    return .{
        .x = self.x - other.x,
        .y = self.y - other.y,
    };
}

pub fn clamp(self: Vec2, min: Vec2, max: Vec2) Vec2 {
    return .{
        .x = @max(min.x, @min(self.x, max.x)),
        .y = @max(min.y, @min(self.y, max.y)),
    };
}
