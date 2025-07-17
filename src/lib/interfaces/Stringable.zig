const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;
const Stringable = @This();
const Vec2 = @import("../types.zig").Vec2;

ptr: *anyopaque,
vtable: VTable,

const VTable = struct {
    toStringList: *const fn (*anyopaque, Allocator) Allocator.Error!ArrayList(ArrayList(u8)),
};

/// Generates A Stringable Interface from a Pointer to a struct.
/// Struct MUST implement the following:
///
///     fn toString(*Self, Allocator) Allocator.Error!ArrayList(ArrayList(u8))
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

        fn toStringOpaque(ptr: *anyopaque, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
            return toConcretePtr(ptr).toStringList(alloc);
        }
    };

    return Stringable{
        .ptr = generator.getOpaquePtr(selfPtr),
        .vtable = .{
            .toStringList = generator.toStringOpaque,
        },
    };
}

pub inline fn toStringList(self: Stringable, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    return self.vtable.toStringList(self.ptr, alloc);
}
