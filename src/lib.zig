//! This internal package contains various things used throughout the program that cannot be
//! contained within a single sub-package without overly using complex import paths.
pub const types = @import("lib/types.zig");
pub const interfaces = @import("lib/interfaces.zig");
pub const casts = @import("lib/casts.zig");
