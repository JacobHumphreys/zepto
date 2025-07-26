const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const Signal = lib.types.Signal;
const InputEvent = lib.types.input.InputEvent;
const AppInfo = lib.types.AppInfo;
const Vec2 = lib.types.Vec2;
const Buffer = lib.types.Buffer;
const RenderElement = lib.types.RenderElement;
const intCast = lib.casts.intCast;
const CursorContainer = lib.interfaces.CursorContainer;

const Page = @import("../pages.zig").Page;
const renderables = @import("../renderables.zig");

const MainPage = @This();

pub const element_id = enum {
    top_bar,
    top_spacer,
    text_window,
    bottom_bar1,
    bottom_bar2,
    bottom_bar3,
};

dimensions: Vec2,

elements: struct {
    top_bar: renderables.AlignedRibbon,
    top_spacer: renderables.Spacer,
    text_window: renderables.TextWindow,
    bottom_bar1: renderables.CursorAlignedRibbon,
    bottom_bar2: renderables.Ribbon,
    bottom_bar3: renderables.Ribbon,
},

alloc: Allocator,

state: enum {
    edit_text,
    prompt_save,
} = .edit_text,

cursor_parent: element_id = .text_window,
current_buffer: *Buffer,

pub fn init(alloc: Allocator, dimensions: Vec2, buffer: Buffer, app_info: AppInfo) Allocator.Error!MainPage {
    const current_buffer = try alloc.create(Buffer);
    current_buffer.* = buffer;

    const top_bar = try renderables.AlignedRibbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{
            .{
                .text = app_info.name orelse "zepto",
                .alignment = .left,
            },
            .{
                .text = app_info.version orelse "0.0.0",
                .alignment = .left,
            },
            .{
                .text = app_info.buffer_name orelse "New Buffer",
                .alignment = .center,
            },
            .{
                .text = app_info.state orelse "",
                .alignment = .right,
            },
        },
        .white,
        .black,
    );

    const window_dimensions = dimensions.sub(.{ .x = 0, .y = 5 });

    const text_window = renderables.TextWindow.init(alloc, window_dimensions, current_buffer);

    const spacer = renderables.Spacer.init(intCast(usize, dimensions.x));

    const bottom_bar1 = renderables.CursorAlignedRibbon.init(
        alloc,
        "",
        intCast(usize, dimensions.x),
    );

    const bottom_bar2 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &.{
            .{
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
        .elements = .{
            .top_bar = top_bar,
            .top_spacer = spacer,
            .text_window = text_window,
            .bottom_bar1 = bottom_bar1,
            .bottom_bar2 = bottom_bar2,
            .bottom_bar3 = bottom_bar3,
        },
        .current_buffer = current_buffer,
        .alloc = alloc,
    };
}

pub fn processEvent(self: *MainPage, event: InputEvent) (Allocator.Error || Signal)!void {
    const cursor_parent = try self.getCursorParent();
    const cursor_container = cursor_parent.cursor_container.?;

    if (event == InputEvent.control and event.control == .exit) {
        return Signal.Exit;
    }

    cursor_container.processEvent(event) catch |err| switch (err) {
        CursorContainer.Error.FailedToProcessEvent => {
            std.log.err("{any}", .{err});
            return Signal.Exit;
        },
        else => |e| return e,
    };

    const appstate: AppInfo = switch (self.getCurrentBuffer().state) {
        .modified => .{ .state = "Modified" },
        .unmodified => .{ .state = "" },
    };

    try self.updateAppInfo(self.alloc, appstate);
}

pub fn deinit(self: *MainPage) void {
    self.current_buffer.deinit();
    self.alloc.destroy(self.current_buffer);
    self.elements.bottom_bar1.deinit();
    self.elements.bottom_bar2.deinit();
    self.elements.bottom_bar3.deinit();
    self.elements.top_bar.deinit();
}

pub fn updateAppInfo(self: *MainPage, alloc: Allocator, appInfo: AppInfo) Allocator.Error!void {
    const old_info: AppInfo = .{
        .name = self.elements.top_bar.elements.items[0].text,
        .version = self.elements.top_bar.elements.items[1].text,
        .buffer_name = self.elements.top_bar.elements.items[2].text,
        .state = self.elements.top_bar.elements.items[3].text,
    };
    self.elements.top_bar.elements.clearAndFree(alloc);
    try self.elements.top_bar.elements.appendSlice(alloc, &.{
        .{
            .text = appInfo.name orelse old_info.name.?,
            .alignment = .left,
        },
        .{
            .text = appInfo.version orelse old_info.version.?,
            .alignment = .left,
        },
        .{
            .text = appInfo.buffer_name orelse old_info.buffer_name.?,
            .alignment = .center,
        },
        .{
            .text = appInfo.state orelse old_info.state.?,
            .alignment = .right,
        },
    });
}

pub fn getElements(self: *MainPage, alloc: Allocator) Allocator.Error!ArrayList(RenderElement) {
    var element_list = try ArrayList(RenderElement).initCapacity(alloc, 6);
    element_list.appendSliceAssumeCapacity(
        &.{
            RenderElement{
                .stringable = self.elements.top_bar.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = 0 },
            },
            RenderElement{
                .stringable = self.elements.top_spacer.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = 1 },
            },
            RenderElement{
                .stringable = self.elements.text_window.stringable(),
                .cursor_container = self.elements.text_window.cursorContainer(),
                .is_visible = true,
                .position = .{ .x = 0, .y = 2 },
            },
            RenderElement{
                .stringable = self.elements.bottom_bar1.stringable(),
                .is_visible = false,
                .cursor_container = self.elements.bottom_bar1.cursorContainer(),
                .position = .{ .x = 0, .y = self.dimensions.y - 3 },
            },
            RenderElement{
                .stringable = self.elements.bottom_bar2.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = self.dimensions.y - 2 },
            },
            RenderElement{
                .stringable = self.elements.bottom_bar3.stringable(),
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

pub fn getCurrentBuffer(self: *MainPage) *Buffer {
    return self.current_buffer;
}

pub fn getDimensions(self: *MainPage) Vec2 {
    return self.dimensions;
}

pub fn page(self: *MainPage) Page {
    return .{ .main_page = self };
}

pub fn setOutputDimensions(self: *MainPage, dimensions: Vec2) void {
    self.dimensions = dimensions;
    self.elements.top_bar.width = intCast(usize, dimensions.x);
    self.elements.top_spacer.width = intCast(usize, dimensions.x);
    self.elements.bottom_bar1.width = intCast(usize, dimensions.x);
    self.elements.bottom_bar2.width = intCast(usize, dimensions.x);
    self.elements.bottom_bar3.width = intCast(usize, dimensions.x);
    const window_dimensions = dimensions.sub(.{ .x = 0, .y = 5 });
    self.elements.text_window.dimensions = window_dimensions;
}
