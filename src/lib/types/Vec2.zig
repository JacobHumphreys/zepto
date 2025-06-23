const Vec2 = @This();
x: i32,
y: i32,

pub fn add(self: Vec2, other: Vec2) Vec2 {
    return .{
        .x = self.x + other.x,
        .y = self.y + other.y,
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
