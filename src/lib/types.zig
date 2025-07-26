const std = @import("std");
pub const Vec2 = @import("types/Vec2.zig");
pub const Buffer = @import("types/Buffer.zig");
pub const RenderElement = @import("types/RenderElement.zig");
pub const input = @import("types/input.zig");

pub const Signal = error{
    Exit,
    PromptSave,
    SaveBuffer,
};

pub const AppInfo = struct {
    name: ?[]const u8 = null,
    version: ?[]const u8 = null,
    buffer_name: ?[]const u8 = null,
    state: ?[]const u8 = null ,
};
