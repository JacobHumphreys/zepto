const std = @import("std");
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const zepto = @import("zepto");
const Vec2 = zepto.Vec2;
const Buffer = zepto.Buffer;
const Signal = zepto.Signal;
const InputEvent = zepto.input.InputEvent;
const RenderElement = @import("tui").RenderElement;

const HelpPage = @This();
pub inline fn getElements(self: *HelpPage, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
    _ = self; // autofix
    _ = alloc; // autofix
}

pub inline fn getCursorParent(self: *HelpPage) Allocator.Error!RenderElement {
    switch (self) {
        inline else => |page| return page.getCursorParent(),
    }
}

pub inline fn setOutputDimensions(self: *HelpPage, new_dimensions: Vec2) void {
    switch (self) {
        inline else => |page| return page.setOutputDimensions(new_dimensions),
    }
}

pub inline fn getCurrentBuffer(self: *HelpPage) *Buffer {
    switch (self) {
        inline else => |page| return page.getCurrentBuffer(),
    }
}

pub inline fn getDimensions(self: *HelpPage) Vec2 {
    switch (self) {
        inline else => |page| return page.getDimensions(),
    }
}

pub inline fn processEvent(self: *HelpPage, event: InputEvent) (Allocator.Error || Signal)!void {
    _ = self; // autofix
    _ = event; // autofix

}

pub inline fn deinit(self: *HelpPage) void {
    switch (self) {
        inline else => |page| return page.deinit(),
    }
}
