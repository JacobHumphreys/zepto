const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const types = @import("../types.zig");
const RenderElement = types.RenderElement;
const Vec2 = types.Vec2;
const CursorContainer = @import("CursorContainer.zig");

const Stringable = @This();
ptr: *anyopaque,
vtable: VTable,

const VTable = struct {
    getCursorParent: *const fn (*anyopaque) ?CursorContainer,
    getElements: *const fn (*anyopaque, Allocator) Allocator.Error!ArrayList(RenderElement),
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

        fn getElementsOpaque(ptr: *anyopaque, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
            return toConcretePtr(ptr).toString(alloc);
        }

        fn getCursorParentOpaque(ptr: *anyopaque) ?CursorContainer {
            return toConcretePtr(ptr).getCursorParent();
        }
    };

    return Stringable{
        .ptr = generator.getOpaquePtr(selfPtr),
        .vtable = .{
            .getElements = generator.getElementsOpaque,
            .getCursorParent = generator.getCursorParentOpaque,
        },
    };
}

pub fn getElements(self: Stringable, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
    return self.vtable.getElements(self.ptr, alloc);
}

pub fn getCursorParent(self: Stringable) ?CursorContainer {
    return self.vtable.getCursorParent(self.ptr);
}
