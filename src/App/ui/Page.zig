const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const Page = @This();

const renderables = @import("renderables.zig");

const lib = @import("lib");
const Vec2 = lib.types.Vec2;
const intCast = lib.casts.intCast;

const RenderElement = @import("RenderElement.zig");

dimensions: Vec2,

text_window: renderables.TextWindow,
top_bar: renderables.Ribbon,
top_spacer: renderables.Spacer,
bottom_bar1: renderables.Ribbon,
bottom_bar2: renderables.Ribbon,
bottom_bar3: renderables.Ribbon,

cursor_parent: usize,

pub fn init(alloc: Allocator, dimensions: Vec2) Allocator.Error!Page {
    const top_bar = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{"This is a test top ribbon"},
    );

    const window_dimensions = dimensions.sub(.{ .x = 0, .y = 5 });

    const text_window = renderables.TextWindow.init(alloc, window_dimensions);

    const spacer = renderables.Spacer.init(intCast(usize, dimensions.x));

    const bottom_bar1 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{""},
    );

    const bottom_bar2 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{"This is a test bottom ribbon 2"},
    );

    const bottom_bar3 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{"This is a test bottom ribbon 3"},
    );

    return Page{
        .dimensions = dimensions,
        .top_bar = top_bar,
        .top_spacer = spacer,
        .text_window = text_window,
        .bottom_bar1 = bottom_bar1,
        .bottom_bar2 = bottom_bar2,
        .bottom_bar3 = bottom_bar3,
        .cursor_parent = 2,
    };
}

pub fn getElements(self: *Page, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
    var element_list = try ArrayList(RenderElement).initCapacity(alloc, 6);
    element_list.appendSliceAssumeCapacity(
        &.{
            RenderElement{
                .stringable = self.top_bar.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = 0 },
            },
            RenderElement{
                .stringable = self.top_spacer.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = 1 },
            },
            RenderElement{
                .stringable = self.text_window.stringable(),
                .cursorContainer = self.text_window.cursorContainer(),
                .is_visible = true,
                .position = .{ .x = 0, .y = 2 },
            },
            RenderElement{
                .stringable = self.bottom_bar1.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = self.dimensions.y - 3 },
            },
            RenderElement{
                .stringable = self.bottom_bar2.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = self.dimensions.y - 2 },
            },
            RenderElement{
                .stringable = self.bottom_bar3.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = self.dimensions.y - 1 },
            },
        },
    );
    return element_list;
}

pub fn deinit(self: *Page) void {
    self.text_window.deinit();
    self.bottom_bar1.deinit();
    self.bottom_bar2.deinit();
    self.bottom_bar3.deinit();
    self.top_bar.deinit();
}
