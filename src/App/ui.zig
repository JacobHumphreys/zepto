pub const MainPage = @import("ui/MainPage.zig");
const renderables = @import("ui/renderables.zig");
pub const rendering = @import("ui/rendering.zig");

pub const Error = renderables.Error || rendering.Error;
