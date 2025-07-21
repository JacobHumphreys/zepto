const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const RenderElement = lib.types.RenderElement;
const Buffer = lib.types.Buffer;
const Vec2 = lib.types.Vec2;

pub const MainPage = @import("pages/MainPage.zig");

pub const Page = union(enum) {
    main_page: *MainPage,

    pub fn getElements(self: Page, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
        switch (self) {
            inline else => |page| return page.getElements(alloc),
        }
    }

    pub fn getCursorParent(self: Page) Allocator.Error!RenderElement {
        switch (self) {
            inline else => |page| return page.getCursorParent(),
        }
    }

    pub fn getCurrentBuffer(self: Page) Buffer {
        switch (self) {
            inline else => |page| return page.getCurrentBuffer(),
        }
    }

    pub fn getDimensions(self: Page) Vec2 {
        switch (self) {
            inline else => |page| return page.getDimensions(),
        }
    }
};
