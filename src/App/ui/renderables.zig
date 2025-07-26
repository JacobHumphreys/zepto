//! Contains a set of structs that adhere to the stringable interface and,
//! optionally, the CursorContainer interface
pub const TextWindow = @import("renderables/TextWindow.zig");
pub const Ribbon = @import("renderables/Ribbon.zig");
pub const AlignedRibbon = @import("renderables/AlignedRibbon.zig");
pub const CursorAlignedRibbon = @import("renderables/CursorAlignedRibbon.zig");
pub const Spacer = @import("renderables/Spacer.zig");
pub const Error = (error{FailedToProcessEvent});
