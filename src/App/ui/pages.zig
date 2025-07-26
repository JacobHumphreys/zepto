const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const types = lib.types;
const Signal = types.Signal;
const InputEvent = types.input.InputEvent;
const RenderElement = types.RenderElement;
const CursorContainer = lib.interfaces.CursorContainer;
const Buffer = types.Buffer;
const Vec2 = types.Vec2;

pub const MainPage = @import("pages/MainPage.zig");

/// Comptime interface for Page. All Pages must be defined at comptime
pub const Page = union(enum) {
    main_page: *MainPage,

    pub inline fn getElements(self: Page, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
        switch (self) {
            inline else => |page| return page.getElements(alloc),
        }
    }

    pub inline fn getCursorParent(self: Page) Allocator.Error!RenderElement {
        switch (self) {
            inline else => |page| return page.getCursorParent(),
        }
    }

    pub inline fn setOutputDimensions(self: Page, new_dimensions: Vec2) void {
        switch (self) {
            inline else => |page| return page.setOutputDimensions(new_dimensions),
        }
    }

    pub inline fn getCurrentBuffer(self: Page) *Buffer {
        switch (self) {
            inline else => |page| return page.getCurrentBuffer(),
        }
    }

    pub inline fn getDimensions(self: Page) Vec2 {
        switch (self) {
            inline else => |page| return page.getDimensions(),
        }
    }

    pub inline fn processEvent(self: Page, event: InputEvent) (Allocator.Error || Signal)!void {
        switch (self) {
            inline else => |page| return page.processEvent(event),
        }
    }
    pub inline fn deinit(self: Page) void {
        switch (self) {
            inline else => |page| return page.deinit(),
        }
    }
};
