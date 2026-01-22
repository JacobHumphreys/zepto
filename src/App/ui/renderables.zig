//! Contains a set of structs that adhere to the stringable interface and,
//! optionally, the CursorContainer interface
pub const TextWindow = @import("renderables/TextWindow.zig");
pub const ColorRibbon = @import("renderables/ColorRibbon.zig");
pub const AlignedRibbon = @import("renderables/AlignedRibbon.zig");
pub const PromptRibbon = @import("renderables/PromptRibbon.zig");
pub const Spacer = @import("renderables/Spacer.zig");
pub const Error = (error{FailedToProcessEvent});

const Stringable = @import("tui").interfaces.Stringable;
const CursorContainer = @import("tui").interfaces.CursorContainer;

pub const Ribbon = union(enum) {
    color: ColorRibbon,
    aligned: AlignedRibbon,
    prompt: PromptRibbon,

    pub fn deinit(self: *Ribbon) void {
        switch (self.*) {
            inline else => |*r| {
                r.deinit();
            },
        }
    }

    pub fn stringable(self: *Ribbon) Stringable {
        switch (self.*) {
            inline else => |*s| return Stringable.from(s),
        }
    }

    pub fn cursorContainer(self: *Ribbon) ?CursorContainer {
        switch (self.*) {
            .prompt => |*p| {
                return p.cursorContainer();
            },
            else => {
                return null;
            },
        }
    }

    pub fn setWidth(self: *Ribbon, width: usize) void {
        switch (self.*) {
            inline else => |*s| {
                s.width = width;
            },
        }
    }

    pub fn isHidden(self: *Ribbon) bool {
        return switch (self.*) {
            .prompt => |p| p.hidden,
            else => false,
        };
    }
};
