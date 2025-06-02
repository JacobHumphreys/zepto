const logging = @import("error_logging.zig");
pub const std_options = struct {
    pub const logFn = logging.myLogFn; // Use your custom log function
};
