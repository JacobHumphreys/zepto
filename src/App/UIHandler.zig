//! Handles ui rendering and processing of input events at a high level.
const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const Vec2 = lib.types.Vec2;
const InputEvent = lib.input.InputEvent;
const Signal = lib.types.Signal;
const ControlSequence = lib.input.ControlSequence;

const input = @import("input.zig");
const rendering = @import("ui/rendering.zig");
const renderables = @import("ui/renderables.zig");
const RenderElement = @import("ui/RenderElement.zig");

const UIHandler = @This();

pub const Error = renderables.Error || rendering.Error;

const Page = struct {
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
            @as(usize, @intCast(dimensions.x)),
            &.{"This is a test top ribbon"},
        );

        const window_dimensions = dimensions.sub(.{ .x = 0, .y = 5 });

        const text_window = renderables.TextWindow.init(alloc, window_dimensions);

        const spacer = renderables.Spacer.init(@as(usize, @intCast(window_dimensions.x)));

        const bottom_bar1 = try renderables.Ribbon.init(
            alloc,
            @as(usize, @intCast(dimensions.x)),
            &.{""},
        );

        const bottom_bar2 = try renderables.Ribbon.init(
            alloc,
            @as(usize, @intCast(dimensions.x)),
            &.{"This is a test bottom ribbon 2"},
        );

        const bottom_bar3 = try renderables.Ribbon.init(
            alloc,
            @as(usize, @intCast(dimensions.x)),
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
        element_list.appendAssumeCapacity(RenderElement{
            .stringable = self.top_bar.stringable(),
            .is_visible = true,
            .position = .{ .x = 0, .y = 0 },
        });
        element_list.appendAssumeCapacity(RenderElement{
            .stringable = self.top_spacer.stringable(),
            .is_visible = true,
            .position = .{ .x = 0, .y = 1 },
        });
        element_list.appendAssumeCapacity(RenderElement{
            .stringable = self.text_window.stringable(),
            .cursorContainer = self.text_window.cursorContainer(),
            .is_visible = true,
            .position = .{ .x = 0, .y = 2 },
        });
        element_list.appendAssumeCapacity(RenderElement{
            .stringable = self.bottom_bar1.stringable(),
            .is_visible = true,
            .position = .{ .x = 0, .y = self.dimensions.y - 3 },
        });
        element_list.appendAssumeCapacity(RenderElement{
            .stringable = self.bottom_bar2.stringable(),
            .is_visible = true,
            .position = .{ .x = 0, .y = self.dimensions.y - 2 },
        });
        element_list.appendAssumeCapacity(RenderElement{
            .stringable = self.bottom_bar3.stringable(),
            .is_visible = true,
            .position = .{ .x = 0, .y = self.dimensions.y - 1 },
        });
        return element_list;
    }

    pub fn deinit(self: *Page) void {
        self.text_window.deinit();
        self.bottom_bar1.deinit();
        self.bottom_bar2.deinit();
        self.top_bar.deinit();
    }
};

current_page: Page,
alloc: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2) (Allocator.Error || Error)!UIHandler {
    try rendering.clearScreen();

    var page = try Page.init(alloc, dimensions);

    var page_elements = try page.getElements(alloc);

    try rendering.reRenderOutput(page_elements.items, alloc);
    try rendering.renderCursorFromGlobalSpace(.{
        .x = 0,
        .y = @as(i32, @intCast(page.cursor_parent)),
    });

    page_elements.deinit(alloc);

    return UIHandler{
        .alloc = alloc,
        .current_page = page,
    };
}

pub fn deinit(self: *UIHandler) void {
    self.current_page.deinit();
}

pub fn processEvent(self: *UIHandler, event: InputEvent) (Error || Signal)!void {
    switch (event) {
        .input => |char| {
            var page_elements = self.current_page.getElements(self.alloc) catch {
                return;
            };
            defer page_elements.deinit(self.alloc);

            try self.current_page.text_window.addCharToBuffer(char);

            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(
                page_elements.items[self.current_page.cursor_parent],
            );
        },
        .control => |sequence| {
            return self.processControlSequence(sequence);
        },
    }
}

pub fn setOutputDimensions(self: *UIHandler, dimensions: Vec2) void {
    self.current_page.text_window.dimensions = dimensions;
}

pub fn processControlSequence(self: *UIHandler, sequence: ControlSequence) (Error || Signal)!void {
    var page_elements = self.current_page.getElements(self.alloc) catch {
        return;
    };
    defer page_elements.deinit(self.alloc);
    switch (sequence) {
        .backspace => {
            self.current_page.text_window.deleteAtCursorPosition();
            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },

        .exit => return Signal.Exit,

        .new_line => {
            try self.current_page.text_window.addSequenceToBuffer(sequence);
            self.current_page.text_window.cursor_position.x = 0;
            self.current_page.text_window.moveCursor(.{ .x = 0, .y = 1 });
            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },

        .left => {
            self.current_page.text_window.moveCursor(.{ .x = -1, .y = 0 });
            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },
        .right => {
            self.current_page.text_window.moveCursor(.{ .x = 1, .y = 0 });
            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },
        .up => {
            self.current_page.text_window.moveCursor(.{ .x = 0, .y = -1 });
            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },
        .down => {
            self.current_page.text_window.moveCursor(.{ .x = 0, .y = 1 });
            try rendering.reRenderOutput(page_elements.items, self.alloc);
            return rendering.renderCursor(page_elements.items[self.current_page.cursor_parent]);
        },

        .unknown => return,
    }
}

test "mem test" {
    //    const alloc = std.testing.allocator;
    //    var ui_handler = try UIHandler.init(alloc, .{ .x = 100, .y = 100 });
    //
    //    try std.testing.expectError(
    //        Signal.Exit,
    //        ui_handler.processEvent(
    //            InputEvent{ .control = .exit },
    //        ),
    //    );
    //    defer ui_handler.deinit();
}
