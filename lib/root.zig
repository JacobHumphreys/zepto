//! This internal package contains various things used throughout the program that cannot be
//! contained within a single sub-package without overly using complex import paths.
pub const types = @import("types.zig");
pub const interfaces = @import("interfaces.zig");
pub const casts = @import("casts.zig");
pub const text = @import("text.zig");
