const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayListUnmanaged;

const lib = @import("lib");
const types = lib.types;
const Signal = types.Signal;
const InputEvent = types.input.InputEvent;
const AppInfo = types.AppInfo;
const Vec2 = types.Vec2;
const Buffer = types.Buffer;
const RenderElement = types.RenderElement;
const intCast = lib.casts.intCast;
const CursorContainer = lib.interfaces.CursorContainer;

const Page = @import("../pages.zig").Page;
const renderables = @import("../renderables.zig");

const MainPage = @This();

pub const element_id = enum {
    top_bar,
    top_spacer,
    text_window,
    bottom_prompt,
    bottom_bar1,
    bottom_bar2,
};

dimensions: Vec2,

elements: struct {
    top_bar: renderables.AlignedRibbon,
    top_spacer: renderables.Spacer,
    text_window: renderables.TextWindow,
    bottom_prompt: renderables.PromptRibbon,
    bottom_bar1: renderables.Ribbon,
    bottom_bar2: renderables.Ribbon,
},

alloc: Allocator,

state: PageState = .edit_text,

cursor_parent: element_id = .text_window,
current_buffer: *Buffer,

const PageState = enum {
    edit_text,
    prompt_save,
    get_buff_path,
};

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

    const bottom_prompt = renderables.PromptRibbon.init(
        alloc,
        .{
            .text = "",
            .width = intCast(usize, dimensions.x),
            .foreground_color = .black,
            .background_color = .white,
            .hidden = true,
        },
    );

    const bottom_bar1 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &getBottomBar1Elements(.edit_text),
    );

    const bottom_bar2 = try renderables.Ribbon.init(
        alloc,
        intCast(usize, dimensions.x),
        &getBottomBar2Elements(.edit_text),
    );

    return MainPage{
        .dimensions = dimensions,
        .elements = .{
            .top_bar = top_bar,
            .top_spacer = spacer,
            .text_window = text_window,
            .bottom_prompt = bottom_prompt,
            .bottom_bar1 = bottom_bar1,
            .bottom_bar2 = bottom_bar2,
        },
        .current_buffer = current_buffer,
        .alloc = alloc,
    };
}

pub fn deinit(self: *MainPage) void {
    self.current_buffer.deinit();
    self.alloc.destroy(self.current_buffer);
    self.elements.bottom_prompt.deinit();
    self.elements.bottom_bar1.deinit();
    self.elements.bottom_bar2.deinit();
    self.elements.top_bar.deinit();
}

fn switchState(self: *MainPage, new_state: PageState) void {
    if (self.state == new_state) return;
    switch (new_state) {
        .edit_text => {
            self.cursor_parent = .text_window;
            self.elements.bottom_prompt.hidden = true;
            self.elements.bottom_prompt.text = "";
            self.elements.bottom_prompt.clearInput();
            self.elements.bottom_bar1.elements.replaceRangeAssumeCapacity(
                0,
                self.elements.bottom_bar1.elements.items.len,
                &getBottomBar1Elements(new_state),
            );
            self.elements.bottom_bar2.elements.replaceRangeAssumeCapacity(
                0,
                self.elements.bottom_bar2.elements.items.len,
                &getBottomBar2Elements(new_state),
            );
        },

        .prompt_save => {
            self.elements.bottom_prompt.hidden = false;
            self.cursor_parent = .bottom_prompt;
            self.elements.bottom_prompt.text = "Save Current Buffer Y/N:";
            self.elements.bottom_prompt.clearInput();
            self.elements.bottom_bar1.elements.replaceRangeAssumeCapacity(
                0,
                self.elements.bottom_bar1.elements.items.len,
                &getBottomBar1Elements(new_state),
            );
            self.elements.bottom_bar2.elements.replaceRangeAssumeCapacity(
                0,
                self.elements.bottom_bar2.elements.items.len,
                &getBottomBar2Elements(new_state),
            );
        },

        .get_buff_path => {
            self.elements.bottom_prompt.hidden = false;
            self.cursor_parent = .bottom_prompt;
            self.elements.bottom_prompt.text = "Enter Path:";
            self.elements.bottom_prompt.clearInput();
            self.elements.bottom_bar1.elements.replaceRangeAssumeCapacity(
                0,
                self.elements.bottom_bar1.elements.items.len,
                &getBottomBar1Elements(new_state),
            );
            self.elements.bottom_bar2.elements.replaceRangeAssumeCapacity(
                0,
                self.elements.bottom_bar2.elements.items.len,
                &getBottomBar2Elements(new_state),
            );
        },
    }
    self.state = new_state;
}

pub fn processEvent(self: *MainPage, event: InputEvent) (Allocator.Error || Signal)!void {
    const cursor_parent = try self.getCursorParent();
    const cursor_container = cursor_parent.cursor_container.?;

    cursor_container.processEvent(event) catch |err| switch (err) {
        CursorContainer.Error.FailedToProcessEvent => {
            std.log.err("{any}", .{err});
            return Signal.Exit;
        },

        Signal.RedrawBuffer => {
            try self.updatePage();
            return Signal.RedrawBuffer;
        },

        Signal.Exit => {
            switch (self.state) {
                PageState.edit_text => {
                    self.switchState(.prompt_save);
                    return Signal.RedrawBuffer;
                },
                PageState.get_buff_path => {
                    if (self.elements.bottom_prompt.input.items.len == 0) return;
                    self.current_buffer.target_path = self.elements.bottom_prompt.input.items;
                    return Signal.SaveBuffer;
                },
                PageState.prompt_save => try self.updatePage(),
            }
        },

        else => |e| return e,
    };
    try self.processUnhandledEvent(event);
}

/// Modifies elements based on the page state and their individual states, often returns a Signal.
///
/// Intended to be used when element state needs to be modifed in ways not directly supported by
/// the type
pub fn updatePage(self: *MainPage) (Allocator.Error || Signal)!void {
    switch (self.state) {
        .edit_text => {
            const appstate: AppInfo = switch (self.getCurrentBuffer().state) {
                .modified => .{ .state = "Modified" },
                .unmodified => .{ .state = "" },
            };

            try self.updateAppInfo(self.alloc, appstate);
            return Signal.RedrawBuffer;
        },

        .prompt_save => {
            const answer = self.elements.bottom_prompt.input.items;
            if (answer.len < 1) return;
            if (std.ascii.toLower(answer[0]) == 'y') {
                self.switchState(.get_buff_path);
                if (self.current_buffer.target_path != null) return Signal.SaveBuffer;
            } else if (std.ascii.toLower(answer[0]) == 'n') {
                return Signal.Exit;
            }
            return Signal.RedrawBuffer;
        },
        else => {},
    }
}

/// For inputs that are expected at specific page states, but not handled by the element type.
/// Eg: InputEvent.control.ctrl_c for PageState.prompt_save
pub fn processUnhandledEvent(self: *MainPage, event: InputEvent) Signal!void {
    switch (self.state) {
        .get_buff_path => {
            if (event == .input) return;
            if (event.control == .ctrl_c) {
                self.switchState(.edit_text);
                return Signal.RedrawBuffer;
            }
        },
        .prompt_save => {
            if (event == .input) return;
            if (event.control == .ctrl_c) {
                self.switchState(.edit_text);
                return Signal.RedrawBuffer;
            }
        },
        else => return,
    }
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
                .stringable = self.elements.bottom_prompt.stringable(),
                .cursor_container = self.elements.bottom_prompt.cursorContainer(),
                .is_visible = !self.elements.bottom_prompt.hidden,
                .position = .{ .x = 0, .y = self.dimensions.y - 3 },
            },
            RenderElement{
                .stringable = self.elements.bottom_bar1.stringable(),
                .is_visible = true,
                .position = .{ .x = 0, .y = self.dimensions.y - 2 },
            },
            RenderElement{
                .stringable = self.elements.bottom_bar2.stringable(),
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

pub inline fn getCurrentBuffer(self: *MainPage) *Buffer {
    return self.current_buffer;
}

pub inline fn getDimensions(self: *MainPage) Vec2 {
    return self.dimensions;
}

pub inline fn page(self: *MainPage) Page {
    return .{ .main_page = self };
}

pub fn setOutputDimensions(self: *MainPage, dimensions: Vec2) void {
    self.dimensions = dimensions;
    self.elements.top_bar.width = intCast(usize, dimensions.x);
    self.elements.top_spacer.width = intCast(usize, dimensions.x);
    self.elements.bottom_prompt.width = intCast(usize, dimensions.x);
    self.elements.bottom_bar1.width = intCast(usize, dimensions.x);
    self.elements.bottom_bar2.width = intCast(usize, dimensions.x);
    const window_dimensions = dimensions.sub(.{ .x = 0, .y = 5 });
    self.elements.text_window.dimensions = window_dimensions;
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

fn getBottomBar1Elements(state: PageState) [6]renderables.Ribbon.Element {
    return switch (state) {
        .edit_text => .{
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
        .prompt_save => .{
            .{ .text = "" },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 1 },
                .text = "Y Yes",
            },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
        },
        .get_buff_path => .{
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
                .text = "^T Files",
            },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
        },
    };
}

fn getBottomBar2Elements(state: PageState) [6]renderables.Ribbon.Element {
    return switch (state) {
        .edit_text => .{
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
        .prompt_save => .{
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^C Cancel",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 1 },
                .text = "N No",
            },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
        },
        .get_buff_path => .{
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 2 },
                .text = "^C Cancel",
            },
            .{
                .background_color = .white,
                .foreground_color = .black,
                .color_range = .{ .x = 0, .y = 3 },
                .text = "TAB Complete",
            },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
            .{ .text = "" },
        },
    };
}
