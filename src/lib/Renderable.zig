const std = @import("std");
const Allocator = std.mem.Allocator;
const Renderable = @This();
const Vec2 = @import("Vec2.zig");

ptr: *anyopaque,
toStringFn: *const fn (*anyopaque, Allocator) Allocator.Error![]const u8,

/// Generates A Renderable Interface from a Pointer to a struct.
/// Struct MUST implement the following:
///
///     fn toString(*Self, Allocator) Allocator.Error![]const u8
///     fn getPosition(*Self) Vec2
pub fn from(selfPtr: anytype) Renderable {
    const Tptr = @TypeOf(selfPtr);
    const generator = struct {
        fn getOpaquePtr(concretePtr: Tptr) *anyopaque {
            const ptr: *anyopaque = @ptrCast(concretePtr);
            return ptr;
        }

        fn toConcretePtr(ptr: *anyopaque) Tptr {
            return @as(Tptr, @ptrCast(@alignCast(ptr)));
        }

        fn toStringOpaque(ptr: *anyopaque, alloc: Allocator) Allocator.Error![]const u8 {
            return toConcretePtr(ptr).toString(alloc);
        }
    };

    return Renderable{
        .ptr = generator.getOpaquePtr(selfPtr),
        .toStringFn = generator.toStringOpaque,
    };
}

pub fn toString(self: Renderable, alloc: Allocator) Allocator.Error![]const u8 {
    return self.toStringFn(self.ptr, alloc);
}
