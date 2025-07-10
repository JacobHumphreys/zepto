const Vec2 = @import("../types.zig").Vec2;
const CursorContainer = @This();

ptr: *anyopaque,
vtable: VTable,

const VTable = struct {
    getCursorPosition: *const fn (*anyopaque) Vec2,
    moveCursor: *const fn (*anyopaque, Vec2) void,
};

pub fn getCursorPosition(self: CursorContainer) Vec2 {
    return self.vtable.getCursorPosition(self.ptr);
}

pub fn moveCursor(self: CursorContainer, offset: Vec2) void {
    self.vtable.moveCursor(self.ptr, offset);
}

/// Generates A CursorContainer Interface from a Pointer to a struct.
/// Struct MUST implement the following:
///
///     fn getCursorPosition(*Self) Vec2
///     fn moveCursor(*Self, Vec2) void
pub fn from(selfPtr: anytype) CursorContainer {
    const Tptr = @TypeOf(selfPtr);
    const generator = struct {
        fn getOpaquePtr(concretePtr: Tptr) *anyopaque {
            const ptr: *anyopaque = @ptrCast(concretePtr);
            return ptr;
        }

        fn toConcretePtr(ptr: *anyopaque) Tptr {
            return @as(Tptr, @ptrCast(@alignCast(ptr)));
        }

        fn getCursorPositionOpaque(ptr: *anyopaque) Vec2 {
            return toConcretePtr(ptr).getCursorPosition();
        }

        fn moveCursorOpaque(ptr: *anyopaque, offset: Vec2) void {
            return toConcretePtr(ptr).moveCursor(offset);
        }
    };

    return CursorContainer{
        .ptr = generator.getOpaquePtr(selfPtr),
        .vtable = .{
            .getCursorPosition = generator.getCursorPositionOpaque,
            .moveCursor = generator.moveCursorOpaque,
        },
    };
}
