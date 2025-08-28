const std = @import("std");
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const Vec2 = lib.types.Vec2;
const Buffer = lib.types.Buffer;
const Signal = lib.types.Signal;
const InputEvent = lib.types.input.InputEvent;
const RenderElement = lib.types.RenderElement;

const FileExplorer = @This();
pub inline fn getElements(self: *FileExplorer, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
    _ = self; // autofix
    _ = alloc; // autofix
}

pub inline fn getCursorParent(self: *FileExplorer) Allocator.Error!RenderElement {
    switch (self) {
        inline else => |page| return page.getCursorParent(),
    }
}

pub inline fn setOutputDimensions(self: *FileExplorer, new_dimensions: Vec2) void {
    switch (self) {
        inline else => |page| return page.setOutputDimensions(new_dimensions),
    }
}

pub inline fn getCurrentBuffer(self: *FileExplorer) *Buffer {
    switch (self) {
        inline else => |page| return page.getCurrentBuffer(),
    }
}

pub inline fn getDimensions(self: *FileExplorer) Vec2 {
    switch (self) {
        inline else => |page| return page.getDimensions(),
    }
}

pub inline fn processEvent(self: *FileExplorer, event: InputEvent) (Allocator.Error || Signal)!void {
    _ = self; // autofix
    _ = event; // autofix

}

pub inline fn deinit(self: *FileExplorer) void {
    switch (self) {
        inline else => |page| return page.deinit(),
    }
}
