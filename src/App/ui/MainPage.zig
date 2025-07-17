const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const MainPage = @This();

const renderables = @import("renderables.zig");
const RibbonElement = renderables.Ribbon.Element;

const lib = @import("lib");
const Page = lib.interfaces.Page;
const Vec2 = lib.types.Vec2;
const Buffer = lib.types.Buffer;
const RenderElement = lib.types.RenderElement;
const intCast = lib.casts.intCast;

const CursorContainer = lib.interfaces.CursorContainer;

pub const element_id = enum {
    top_bar,
    top_spacer,
    text_window,
    bottom_bar1,
    bottom_bar2,
    bottom_bar3,
};

dimensions: Vec2,

text_window: renderables.TextWindow,
top_bar: renderables.Ribbon,
top_spacer: renderables.Spacer,
bottom_bar1: renderables.Ribbon,
bottom_bar2: renderables.Ribbon,
bottom_bar3: renderables.Ribbon,

cursor_parent: element_id,

pub fn init(alloc: Allocator, dimensions: Vec2, buffer: Buffer) Allocator.Error!MainPage {
    const top_bar = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{
            RibbonElement{
                .text = "This is a test top ribbon",
            },
        },
    );

    const window_dimensions = dimensions.sub(.{ .x = 0, .y = 5 });

    const text_window = renderables.TextWindow.init(alloc, window_dimensions, buffer);

    const spacer = renderables.Spacer.init(intCast(usize, dimensions.x));

    const bottom_bar1 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{.{
            .text = "",
        }},
    );

    const bottom_bar2 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{
            RibbonElement{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^G Get Help",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^O WriteOut",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^R Read File",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^Y Prev Pg",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^K Cut Text",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^C Cur Pos",
            },
        },
    );

    const bottom_bar3 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^X Exit",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^J Justify",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^W Where is",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^V Next Pg",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^U UnCut Text",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^T To Spell",
            },
        },
    );

    return MainPage{
        .dimensions = dimensions,
        .top_bar = top_bar,
        .top_spacer = spacer,
        .text_window = text_window,
        .bottom_bar1 = bottom_bar1,
        .bottom_bar2 = bottom_bar2,
        .bottom_bar3 = bottom_bar3,
        .cursor_parent = element_id.text_window,
    };
}

pub fn deinit(self: *MainPage) void {
    self.text_window.deinit();
    self.bottom_bar1.deinit();
    self.bottom_bar2.deinit();
    self.bottom_bar3.deinit();
    self.top_bar.deinit();
}

pub fn getElements(self: *MainPage, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
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
                .cursor_container = self.text_window.cursorContainer(),
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

pub fn getCursorParent(self: *MainPage) Allocator.Error!RenderElement {
    var allocation_buffer: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&allocation_buffer);
    const alloc = fba.allocator();

    var elements = try self.getElements(alloc);
    defer elements.deinit(alloc);
    const cursor_parent = elements.items[@intFromEnum(self.cursor_parent)];

    return cursor_parent;
}

pub fn getCurrentBuffer(self: *MainPage) Buffer {
    return self.text_window.buffer;
}

pub fn getDimensions(self: *MainPage) Vec2 {
    return self.dimensions;
}

pub fn page(self: *MainPage) Page {
    return Page.from(self);
}
