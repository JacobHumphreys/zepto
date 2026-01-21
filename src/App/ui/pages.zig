const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const zepto = @import("zepto");
const Signal = zepto.Signal;
const InputEvent = zepto.input.InputEvent;
const Buffer = zepto.Buffer;
const Vec2 = zepto.Vec2;

const tui = @import("tui");
const RenderElement = tui.RenderElement;
const CursorContainer = tui.interfaces.CursorContainer;

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

    pub inline fn processNewEvent(self: Page, event: InputEvent) (Allocator.Error || Signal)!void {
        switch (self) {
            inline else => |page| return page.processNewEvent(event),
        }
    }

    pub inline fn deinit(self: Page) void {
        switch (self) {
            inline else => |page| return page.deinit(),
        }
    }
};
