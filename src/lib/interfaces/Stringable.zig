const std = @import("std");
const Allocator = std.mem.Allocator;
const Stringable = @This();
const Vec2 = @import("../types.zig").Vec2;

ptr: *anyopaque,
vtable: VTable,

const VTable = struct {
    toString: *const fn (*anyopaque, Allocator) Allocator.Error![]const u8,
};

/// Generates A Stringable Interface from a Pointer to a struct.
/// Struct MUST implement the following:
///
///     fn toString(*Self, Allocator) Allocator.Error![]const u8
pub fn from(selfPtr: anytype) Stringable {
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

    return Stringable{
        .ptr = generator.getOpaquePtr(selfPtr),
        .vtable = .{
            .toString = generator.toStringOpaque,
        },
    };
}

pub fn toString(self: Stringable, alloc: Allocator) Allocator.Error![]const u8 {
    return self.vtable.toString(self.ptr, alloc);
}
