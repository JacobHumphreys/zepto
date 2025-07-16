const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const types = @import("../types.zig");
const RenderElement = types.RenderElement;
const Buffer = types.Buffer;
const Vec2 = types.Vec2;
const CursorContainer = @import("CursorContainer.zig");

const Page = @This();
ptr: *anyopaque,
vtable: VTable,

const VTable = struct {
    getCursorParent: *const fn (*anyopaque ) Allocator.Error!RenderElement,
    getElements: *const fn (*anyopaque, Allocator) Allocator.Error!ArrayList(RenderElement),
    getCurrentBuffer: *const fn (*anyopaque) Buffer,
    getDimensions: *const fn (*anyopaque) Vec2,
};

/// Generates A Stringable Interface from a Pointer to a struct.
/// Struct MUST implement the following:
///
///     fn toString(*Self, Allocator) Allocator.Error![]const u8
pub fn from(selfPtr: anytype) Page {
    const Tptr = @TypeOf(selfPtr);
    const generator = struct {
        fn getOpaquePtr(concretePtr: Tptr) *anyopaque {
            const ptr: *anyopaque = @ptrCast(concretePtr);
            return ptr;
        }

        fn toConcretePtr(ptr: *anyopaque) Tptr {
            return @as(Tptr, @ptrCast(@alignCast(ptr)));
        }

        fn getElements(ptr: *anyopaque, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
            return toConcretePtr(ptr).getElements(alloc);
        }

        fn getCursorParent(ptr: *anyopaque) Allocator.Error!RenderElement {
            return toConcretePtr(ptr).getCursorParent();
        }

        fn getCurrentBuffer(ptr: *anyopaque) Buffer {
            return toConcretePtr(ptr).getCurrentBuffer();
        }

        fn getDimensions(ptr: *anyopaque) Vec2 {
            return toConcretePtr(ptr).getDimensions();
        }
    };

    return Page{
        .ptr = generator.getOpaquePtr(selfPtr),
        .vtable = .{
            .getElements = generator.getElements,
            .getCursorParent = generator.getCursorParent,
            .getCurrentBuffer = generator.getCurrentBuffer,
            .getDimensions = generator.getDimensions,
        },
    };
}

pub fn getElements(self: Page, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
    return self.vtable.getElements(self.ptr, alloc);
}

pub fn getCursorParent(self: Page) Allocator.Error!RenderElement {
    return self.vtable.getCursorParent(self.ptr );
}

pub fn getCurrentBuffer(self: Page) Buffer {
    return self.vtable.getCurrentBuffer(self.ptr);
}

pub fn getDimensions(self: Page) Vec2 {
    return self.vtable.getDimensions(self.ptr);
}
